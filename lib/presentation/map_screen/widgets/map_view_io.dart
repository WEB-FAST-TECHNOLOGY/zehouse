import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/mapbox_service.dart';

Widget buildMapView({
  required List<Map<String, dynamic>> properties,
  required int selectedIndex,
  required Function(int) onPropertyTap,
  required Function(MapboxMap) onMapCreated,
  Map<String, double>? userLocation,
  Map<String, dynamic>? routeInfo,
}) {
  return _MapboxMapView(
    properties: properties,
    selectedIndex: selectedIndex,
    onPropertyTap: onPropertyTap,
    onMapCreated: onMapCreated,
    userLocation: userLocation,
    routeInfo: routeInfo,
  );
}

class _MapboxMapView extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  final int selectedIndex;
  final Function(int) onPropertyTap;
  final Function(MapboxMap) onMapCreated;
  final Map<String, double>? userLocation;
  final Map<String, dynamic>? routeInfo;

  const _MapboxMapView({
    required this.properties,
    required this.selectedIndex,
    required this.onPropertyTap,
    required this.onMapCreated,
    this.userLocation,
    this.routeInfo,
  });

  @override
  State<_MapboxMapView> createState() => _MapboxMapViewState();
}

class _MapboxMapViewState extends State<_MapboxMapView> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  final Map<String, int> _annotationToPropertyIndex = {};

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    widget.onMapCreated(mapboxMap);
    try {
      await _mapboxMap?.scaleBar.updateSettings(
        ScaleBarSettings(enabled: false),
      );
      await _mapboxMap?.compass.updateSettings(CompassSettings(enabled: true));
      await _mapboxMap?.attribution.updateSettings(
        AttributionSettings(position: OrnamentPosition.BOTTOM_LEFT),
      );
      await _mapboxMap?.logo.updateSettings(
        LogoSettings(position: OrnamentPosition.BOTTOM_LEFT),
      );

      _pointAnnotationManager =
          await _mapboxMap?.annotations.createPointAnnotationManager();

      // Tap listener for Point Annotations using tapEvents method
      _pointAnnotationManager?.tapEvents(onTap: (annotation) {
        final index = _annotationToPropertyIndex[annotation.id];
        if (index != null) {
          widget.onPropertyTap(index);
        }
      });

      await _updateAnnotations();

      // Auto center on user location if available at start
      if (widget.userLocation != null) {
        _centerOnUserLocation();
      } else if (widget.selectedIndex >= 0) {
        _centerOnSelectedProperty();
      }
    } catch (e) {
      debugPrint('Mapbox settings error: $e');
    }
  }

  @override
  void didUpdateWidget(_MapboxMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex && widget.selectedIndex >= 0) {
      _centerOnSelectedProperty();
    }
    if (widget.userLocation != oldWidget.userLocation && widget.userLocation != null) {
      _centerOnUserLocation();
    }
    if (widget.properties != oldWidget.properties ||
        widget.selectedIndex != oldWidget.selectedIndex ||
        widget.userLocation != oldWidget.userLocation) {
      _updateAnnotations();
    }
  }

  void _centerOnSelectedProperty() {
    if (_mapboxMap == null || widget.selectedIndex < 0 || widget.selectedIndex >= widget.properties.length) return;
    final p = widget.properties[widget.selectedIndex];
    final lat = (p['lat'] as num?)?.toDouble();
    final lng = (p['lng'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      _mapboxMap?.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 13.0,
        ),
        MapAnimationOptions(duration: 800),
      );
    }
  }

  void _centerOnUserLocation() {
    if (_mapboxMap == null || widget.userLocation == null) return;
    final lat = widget.userLocation!['lat'];
    final lng = widget.userLocation!['lng'];
    if (lat != null && lng != null) {
      _mapboxMap?.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 13.0,
        ),
        MapAnimationOptions(duration: 800),
      );
    }
  }

  Future<void> _updateAnnotations() async {
    final manager = _pointAnnotationManager;
    if (manager == null) return;

    try {
      await manager.deleteAll();
      _annotationToPropertyIndex.clear();

      // 1. Add properties point annotations
      for (int i = 0; i < widget.properties.length; i++) {
        final p = widget.properties[i];
        final lat = (p['lat'] as num?)?.toDouble();
        final lng = (p['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final isSelected = widget.selectedIndex == i;
        final isRent = p['listingType'] == 'rent';
        final price = p['price'] as int;
        final priceLabel = isRent
            ? '${price.toString()}€/m'
            : price >= 1000000
                ? '${(price / 1000000).toStringAsFixed(1)}M€'
                : '${(price / 1000).toStringAsFixed(0)}k€';

        final iconData = _iconForType(p['type'] as String? ?? '');
        final isNew = p['isNew'] as bool? ?? false;

        final markerBytes = await _generateMarkerIcon(
          label: priceLabel,
          isSelected: isSelected,
          isRent: isRent,
          icon: iconData,
          isNew: isNew,
        );

        final annotation = await manager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(lng, lat)),
            image: markerBytes,
            iconAnchor: IconAnchor.BOTTOM,
          ),
        );

        _annotationToPropertyIndex[annotation.id] = i;
      }

      // 2. Add user location dot annotation
      final userLoc = widget.userLocation;
      if (userLoc != null) {
        final userLat = userLoc['lat'];
        final userLng = userLoc['lng'];
        if (userLat != null && userLng != null) {
          final userBytes = await _generateUserLocationIcon();
          await manager.create(
            PointAnnotationOptions(
              geometry: Point(coordinates: Position(userLng, userLat)),
              image: userBytes,
              iconAnchor: IconAnchor.CENTER,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating annotations: $e');
    }
  }

  Future<Uint8List> _generateMarkerIcon({
    required String label,
    required bool isSelected,
    required bool isRent,
    required IconData icon,
    required bool isNew,
  }) async {
    final double width = isSelected ? 120.0 : 100.0;
    final double height = isSelected ? 48.0 : 40.0;
    final double radius = isSelected ? 24.0 : 20.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height + 10));

    final bgColor = isSelected
        ? AppTheme.accent
        : isRent
            ? AppTheme.info
            : AppTheme.primary;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = bgColor;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..color = Colors.white;

    // Draw shadow first
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final RRect shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, width - 8, height - 8),
      Radius.circular(radius),
    );
    canvas.drawRRect(shadowRect, shadowPaint);

    // Draw background pill
    final RRect mainRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, width - 4, height - 4),
      Radius.circular(radius),
    );
    canvas.drawRRect(mainRect, paint);
    canvas.drawRRect(mainRect, borderPaint);

    // Draw pin/triangle point at bottom center
    final path = Path()
      ..moveTo(width / 2 - 8, height - 3)
      ..lineTo(width / 2, height + 5)
      ..lineTo(width / 2 + 8, height - 3)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Draw icon
    final iconCode = icon.codePoint;
    final iconPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(iconCode),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: isSelected ? 16.0 : 13.0,
          color: Colors.white.withOpacity(0.9),
        ),
      )
      ..layout();

    // Draw price text label
    final labelPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: label,
        style: GoogleFonts.outfit(
          fontSize: isSelected ? 14.0 : 12.0,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      )
      ..layout();

    final double totalContentWidth = iconPainter.width + 4 + labelPainter.width;
    final double startX = (width - totalContentWidth) / 2;
    final double iconY = (height - iconPainter.height) / 2;
    final double labelY = (height - labelPainter.height) / 2;

    iconPainter.paint(canvas, Offset(startX, iconY));
    labelPainter.paint(canvas, Offset(startX + iconPainter.width + 4, labelY));

    // If isNew, draw a red indicator dot at top right
    if (isNew) {
      final dotPaint = Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.fill;
      final dotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final double dotX = width - 8;
      final double dotY = 8;
      canvas.drawCircle(Offset(dotX, dotY), 5.0, dotPaint);
      canvas.drawCircle(Offset(dotX, dotY), 5.0, dotBorder);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), (height + 10).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generateUserLocationIcon() async {
    const double size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final Color pulseColor = AppTheme.isDark ? const Color(0xFF00F2FE) : const Color(0xFF3B82F6);

    // 1. Outermost translucent ripple ring
    final ripple3 = Paint()
      ..color = pulseColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 26.0, ripple3);

    // 2. Middle translucent ripple ring
    final ripple2 = Paint()
      ..color = pulseColor.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 18.0, ripple2);

    // 3. Inner translucent ripple ring
    final ripple1 = Paint()
      ..color = pulseColor.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 12.0, ripple1);

    // 4. White border ring for contrast
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 8.5, borderPaint);

    // 5. Solid center core
    final innerPaint = Paint()
      ..color = pulseColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 6.0, innerPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Maison':
        return Icons.house_rounded;
      case 'Studio':
        return Icons.single_bed_rounded;
      case 'Loft':
        return Icons.warehouse_rounded;
      case 'Hôtel':
        return Icons.hotel_rounded;
      case 'Bureau':
        return Icons.business_center_rounded;
      case 'Camping-car':
        return Icons.rv_hookup_rounded;
      case 'Salle de Fêtes':
        return Icons.celebration_rounded;
      default:
        return Icons.apartment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MapWidget(
          key: ValueKey(AppTheme.isDark),
          styleUri: AppTheme.isDark
              ? 'mapbox://styles/mapbox/navigation-guidance-night-v4'
              : MapboxService.mapboxStyleUrl,
          viewport: CameraViewportState(
            center: Point(
              coordinates: Position(
                widget.userLocation?['lng'] ?? MapboxService.defaultLng,
                widget.userLocation?['lat'] ?? MapboxService.defaultLat,
              ),
            ),
            zoom: MapboxService.defaultZoom,
          ),
          onMapCreated: _onMapCreated,
        );
      },
    );
  }
}
