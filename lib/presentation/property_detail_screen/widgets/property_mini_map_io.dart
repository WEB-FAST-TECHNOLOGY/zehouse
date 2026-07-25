import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/mapbox_service.dart';

Widget buildMiniMap({required String address}) {
  return _MapboxMiniMap(address: address);
}

class _MapboxMiniMap extends StatefulWidget {
  final String address;
  const _MapboxMiniMap({required this.address});

  @override
  State<_MapboxMiniMap> createState() => _MapboxMiniMapState();
}

class _MapboxMiniMapState extends State<_MapboxMiniMap> {
  MapboxMap? _mapboxMap;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    try {
      final manager = await _mapboxMap!.annotations
          .createPointAnnotationManager();
      await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              MapboxService.defaultLng,
              MapboxService.defaultLat,
            ),
          ),
          iconSize: 1.5,
        ),
      );
    } catch (e) {
      debugPrint('Mapbox mini map annotation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: MapWidget(
              styleUri: AppTheme.isDark
                  ? 'mapbox://styles/mapbox/navigation-guidance-night-v4'
                  : MapboxService.styleStandard,
              viewport: CameraViewportState(
                center: Point(
                  coordinates: Position(
                    MapboxService.defaultLng,
                    MapboxService.defaultLat,
                  ),
                ),
                zoom: MapboxService.miniMapZoom,
              ),
              onMapCreated: _onMapCreated,
            ),
          ),
          // Location pin overlay
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 36,
                    color: AppTheme.accent,
                  ),
                  SizedBox(height: 2),
                  SizedBox(
                    width: 12,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x33E85D4A),
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Open in Mapbox button
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () =>
                  MapboxService.openDirectionsByAddress(widget.address),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Ouvrir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
