// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/mapbox_service.dart';

Widget buildMapView({
  required List<Map<String, dynamic>> properties,
  required int selectedIndex,
  required Function(int) onPropertyTap,
  required Function(dynamic) onMapCreated,
  Map<String, double>? userLocation,
  Map<String, dynamic>? routeInfo,
}) {
  return _WebMapboxView(
    properties: properties,
    selectedIndex: selectedIndex,
    onPropertyTap: onPropertyTap,
    userLocation: userLocation,
    routeInfo: routeInfo,
  );
}

class _WebMapboxView extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  final int selectedIndex;
  final Function(int) onPropertyTap;
  final Map<String, double>? userLocation;
  final Map<String, dynamic>? routeInfo;

  const _WebMapboxView({
    required this.properties,
    required this.selectedIndex,
    required this.onPropertyTap,
    this.userLocation,
    this.routeInfo,
  });

  @override
  State<_WebMapboxView> createState() => _WebMapboxViewState();
}

class _WebMapboxViewState extends State<_WebMapboxView> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'mapbox-map-${DateTime.now().millisecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    final token = MapboxService.accessToken;
    final lat = MapboxService.defaultLat;
    final lng = MapboxService.defaultLng;
    final zoom = MapboxService.defaultZoom;

    final html.IFrameElement iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..allow = 'geolocation'
      ..srcdoc = _buildMapHtml(token, lat, lng, zoom);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => iframe,
    );
  }

  String _buildMapHtml(String token, double lat, double lng, double zoom) {
    return '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<link href="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.css" rel="stylesheet"/>
<script src="https://api.mapbox.com/mapbox-gl-js/v3.3.0/mapbox-gl.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { width: 100vw; height: 100vh; overflow: hidden; }
  #map { position: absolute; top: 0; bottom: 0; width: 100%; height: 100%; }
</style>
</head>
<body>
<div id="map"></div>
<script>
  mapboxgl.accessToken = '$token';
  var map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/mapbox/streets-v12',
    center: [$lng, $lat],
    zoom: $zoom,
    attributionControl: true
  });
  map.addControl(new mapboxgl.NavigationControl(), 'bottom-right');
  map.addControl(new mapboxgl.ScaleControl({ maxWidth: 80, unit: 'metric' }), 'bottom-left');
</script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Real Mapbox GL JS map
            Positioned.fill(child: HtmlElementView(viewType: _viewId)),
            // Price pins overlay
            ...List.generate(widget.properties.length, (index) {
              final p = widget.properties[index];
              final isSelected = widget.selectedIndex == index;
              final isRent = p['listingType'] == 'rent';
              final price = p['price'] as int;
              final priceLabel = isRent
                  ? '${price.toString()}€/m'
                  : price >= 1000000
                  ? '${(price / 1000000).toStringAsFixed(1)}M€'
                  : '${(price / 1000).toStringAsFixed(0)}k€';

              final positions = [
                const Offset(0.38, 0.32),
                const Offset(0.60, 0.46),
                const Offset(0.24, 0.52),
                const Offset(0.72, 0.28),
                const Offset(0.46, 0.62),
                const Offset(0.56, 0.40),
                const Offset(0.30, 0.22),
                const Offset(0.65, 0.58),
                const Offset(0.18, 0.38),
                const Offset(0.80, 0.44),
                const Offset(0.42, 0.72),
                const Offset(0.52, 0.18),
              ];
              final pos = index < positions.length
                  ? positions[index]
                  : Offset(
                      0.3 + (index * 0.07) % 0.5,
                      0.3 + (index * 0.09) % 0.4,
                    );

              return Positioned(
                left: constraints.maxWidth * pos.dx - 44,
                top: constraints.maxHeight * pos.dy - 22,
                child: GestureDetector(
                  onTap: () => widget.onPropertyTap(index),
                  child: AnimatedScale(
                    scale: isSelected ? 1.18 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: _PricePin(
                      label: priceLabel,
                      isSelected: isSelected,
                      isRent: isRent,
                      isNew: p['isNew'] as bool,
                      propertyType: p['type'] as String,
                    ),
                  ),
                ),
              );
            }),
            // User location dot at center
            Positioned(
              left: constraints.maxWidth * 0.50 - 12,
              top: constraints.maxHeight * 0.50 - 12,
              child: _UserLocationDot(),
            ),
            // Route info label
            if (widget.selectedIndex >= 0 && widget.routeInfo != null)
              Positioned(
                top: constraints.maxHeight * 0.50 - 52,
                left: constraints.maxWidth * 0.50 - 70,
                child: _RouteInfoLabel(routeInfo: widget.routeInfo!),
              ),
          ],
        );
      },
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withAlpha(40),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withAlpha(100),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteInfoLabel extends StatelessWidget {
  final Map<String, dynamic> routeInfo;
  const _RouteInfoLabel({required this.routeInfo});

  @override
  Widget build(BuildContext context) {
    final distance = routeInfo['distance'] as String? ?? '';
    final duration = routeInfo['duration'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_car_rounded,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            '$duration · $distance',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePin extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isRent;
  final bool isNew;
  final String propertyType;

  const _PricePin({
    required this.label,
    required this.isSelected,
    required this.isRent,
    required this.isNew,
    required this.propertyType,
  });

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
    final bgColor = isSelected
        ? AppTheme.accent
        : isRent
        ? AppTheme.info
        : AppTheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: -4,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 8,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: bgColor.withAlpha(isSelected ? 120 : 60),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForType(propertyType), size: 11, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
