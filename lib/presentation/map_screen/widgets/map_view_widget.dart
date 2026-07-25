import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'map_view_web.dart' if (dart.library.io) 'map_view_io.dart';
import '../../../theme/app_theme.dart';

class MapViewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> properties;
  final int selectedIndex;
  final Function(int) onPropertyTap;
  final Map<String, double>? userLocation;
  final Map<String, dynamic>? routeInfo;
  final VoidCallback? onMyLocationTap;

  const MapViewWidget({
    super.key,
    required this.properties,
    required this.selectedIndex,
    required this.onPropertyTap,
    this.userLocation,
    this.routeInfo,
    this.onMyLocationTap,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  dynamic _mapboxMap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Map fills the entire available space
          Positioned.fill(
            child: buildMapView(
              properties: widget.properties,
              selectedIndex: widget.selectedIndex,
              onPropertyTap: widget.onPropertyTap,
              onMapCreated: (map) {
                _mapboxMap = map;
              },
              userLocation: widget.userLocation,
              routeInfo: widget.routeInfo,
            ),
          ),
          // My location button
          Positioned(
            bottom: 260,
            right: 16,
            child: _MapActionButton(
              icon: Icons.my_location_rounded,
              onTap: widget.onMyLocationTap ?? () {},
            ),
          ),
          // Layer toggle button
          Positioned(
            bottom: 316,
            right: 16,
            child: _MapActionButton(icon: Icons.layers_rounded, onTap: () {}),
          ),
          // Mapbox attribution (non-web)
          if (!kIsWeb)
            const Positioned(bottom: 8, left: 8, child: _MapAttribution()),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '© Mapbox',
        style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
      ),
    );
  }
}
