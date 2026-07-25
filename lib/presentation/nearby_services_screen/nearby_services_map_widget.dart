import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

import 'widgets/nearby_map_view_web.dart'
    if (dart.library.io) 'widgets/nearby_map_view_io.dart';

/// Unified Mapbox map widget for the Nearby Services screen.
/// Displays service and professional pins on an interactive Mapbox Streets map.
class NearbyServicesMapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> professionals;
  final Map<String, dynamic>? selectedService;
  final Function(Map<String, dynamic>) onServiceTap;
  final bool userLocationAvailable;

  const NearbyServicesMapWidget({
    super.key,
    required this.services,
    required this.professionals,
    required this.selectedService,
    required this.onServiceTap,
    this.userLocationAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        children: [
          buildNearbyMapView(
            services: services,
            professionals: professionals,
            selectedService: selectedService,
            onServiceTap: onServiceTap,
            userLocationAvailable: userLocationAvailable,
          ),
          // Map label overlay
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 12,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${services.length} services · ${professionals.length} pros',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
