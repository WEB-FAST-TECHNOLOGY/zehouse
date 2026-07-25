import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/mapbox_service.dart';

Widget buildNearbyMapView({
  required List<Map<String, dynamic>> services,
  required List<Map<String, dynamic>> professionals,
  required Map<String, dynamic>? selectedService,
  required Function(Map<String, dynamic>) onServiceTap,
  bool? userLocationAvailable,
}) {
  return _NearbyMapboxView(
    services: services,
    professionals: professionals,
    selectedService: selectedService,
    onServiceTap: onServiceTap,
    userLocationAvailable: userLocationAvailable ?? false,
  );
}

class _NearbyMapboxView extends StatefulWidget {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> professionals;
  final Map<String, dynamic>? selectedService;
  final Function(Map<String, dynamic>) onServiceTap;
  final bool userLocationAvailable;

  const _NearbyMapboxView({
    required this.services,
    required this.professionals,
    required this.selectedService,
    required this.onServiceTap,
    required this.userLocationAvailable,
  });

  @override
  State<_NearbyMapboxView> createState() => _NearbyMapboxViewState();
}

class _NearbyMapboxViewState extends State<_NearbyMapboxView> {
  MapboxMap? _mapboxMap;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    try {
      await _mapboxMap?.scaleBar.updateSettings(
        ScaleBarSettings(enabled: false),
      );
      await _mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));
      await _mapboxMap?.attribution.updateSettings(
        AttributionSettings(position: OrnamentPosition.BOTTOM_LEFT),
      );
      await _mapboxMap?.logo.updateSettings(
        LogoSettings(position: OrnamentPosition.BOTTOM_LEFT),
      );
    } catch (e) {
      debugPrint('Mapbox settings error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Mapbox Streets map
            MapWidget(
              styleUri: AppTheme.isDark
                  ? 'mapbox://styles/mapbox/navigation-guidance-night-v4'
                  : MapboxService.styleStreets,
              viewport: CameraViewportState(
                center: Point(
                  coordinates: Position(
                    MapboxService.defaultLng,
                    MapboxService.defaultLat,
                  ),
                ),
                zoom: 12.0,
              ),
              onMapCreated: _onMapCreated,
            ),

            // Service pins overlay
            ...List.generate(
              widget.services.length > 10 ? 10 : widget.services.length,
              (i) {
                final s = widget.services[i];
                final isSelected = widget.selectedService?['id'] == s['id'];
                const positions = [
                  Offset(0.20, 0.30),
                  Offset(0.55, 0.25),
                  Offset(0.75, 0.45),
                  Offset(0.35, 0.60),
                  Offset(0.65, 0.65),
                  Offset(0.15, 0.65),
                  Offset(0.50, 0.50),
                  Offset(0.80, 0.25),
                  Offset(0.40, 0.20),
                  Offset(0.70, 0.75),
                ];
                final pos = i < positions.length
                    ? positions[i]
                    : Offset(0.3 + (i * 0.07) % 0.5, 0.3 + (i * 0.09) % 0.4);

                return Positioned(
                  left: constraints.maxWidth * pos.dx - 22,
                  top: constraints.maxHeight * pos.dy - 22,
                  child: GestureDetector(
                    onTap: () => widget.onServiceTap(s),
                    child: AnimatedScale(
                      scale: isSelected ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: _ServiceMapPin(
                        icon: s['icon'] as IconData,
                        color: s['color'] as Color,
                        isSelected: isSelected,
                        label: s['type'] as String,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Professional pins overlay
            ...List.generate(
              widget.professionals.length > 8 ? 8 : widget.professionals.length,
              (i) {
                final pro = widget.professionals[i];
                const proPositions = [
                  Offset(0.30, 0.20),
                  Offset(0.68, 0.35),
                  Offset(0.12, 0.45),
                  Offset(0.45, 0.72),
                  Offset(0.82, 0.58),
                  Offset(0.25, 0.80),
                  Offset(0.60, 0.15),
                  Offset(0.88, 0.75),
                ];
                final pos = i < proPositions.length
                    ? proPositions[i]
                    : Offset(0.2 + (i * 0.08) % 0.6, 0.55);
                final isAvailable = (pro['isAvailable'] as bool?) ?? true;

                return Positioned(
                  left: constraints.maxWidth * pos.dx - 16,
                  top: constraints.maxHeight * pos.dy - 16,
                  child: Tooltip(
                    message: '${pro['name']} · ${pro['category']}',
                    child: _ProfessionalMapPin(
                      icon: pro['icon'] as IconData,
                      color: pro['color'] as Color,
                      isAvailable: isAvailable,
                    ),
                  ),
                );
              },
            ),

            // User location dot
            if (widget.userLocationAvailable)
              Positioned(
                left: constraints.maxWidth * 0.50 - 12,
                top: constraints.maxHeight * 0.50 - 12,
                child: _UserDot(),
              ),
          ],
        );
      },
    );
  }
}

// ─── Service Map Pin ──────────────────────────────────────────────────────────

class _ServiceMapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final String label;

  const _ServiceMapPin({
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSelected ? 44 : 36,
          height: isSelected ? 44 : 36,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isSelected ? 0 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(isSelected ? 100 : 60),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: isSelected ? 22 : 18,
            color: isSelected ? Colors.white : color,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Professional Map Pin ─────────────────────────────────────────────────────

class _ProfessionalMapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isAvailable;

  const _ProfessionalMapPin({
    required this.icon,
    required this.color,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(50),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isAvailable ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── User Location Dot ────────────────────────────────────────────────────────

class _UserDot extends StatelessWidget {
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
