import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Web stub — Mapbox SDK not available on web.
/// Returns a high-fidelity simulated streets/urban map widget for nearby services.
Widget buildNearbyMapView({
  required List<Map<String, dynamic>> services,
  required List<Map<String, dynamic>> professionals,
  required Map<String, dynamic>? selectedService,
  required Function(Map<String, dynamic>) onServiceTap,
  bool? userLocationAvailable,
}) {
  return _NearbySimulatedMapView(
    services: services,
    professionals: professionals,
    selectedService: selectedService,
    onServiceTap: onServiceTap,
    userLocationAvailable: userLocationAvailable ?? false,
  );
}

class _NearbySimulatedMapView extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> professionals;
  final Map<String, dynamic>? selectedService;
  final Function(Map<String, dynamic>) onServiceTap;
  final bool userLocationAvailable;

  const _NearbySimulatedMapView({
    required this.services,
    required this.professionals,
    required this.selectedService,
    required this.onServiceTap,
    required this.userLocationAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Streets-style base
              Positioned.fill(child: Container(color: const Color(0xFFF5F0E8))),
              Positioned.fill(
                child: CustomPaint(painter: _UrbanStreetsPainter()),
              ),
              Positioned.fill(child: CustomPaint(painter: _WaterPainter())),

              // Service pins
              ...List.generate(services.length > 10 ? 10 : services.length, (
                i,
              ) {
                final s = services[i];
                final isSelected = selectedService?['id'] == s['id'];
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
                    onTap: () => onServiceTap(s),
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
              }),

              // Professional pins
              ...List.generate(
                professionals.length > 8 ? 8 : professionals.length,
                (i) {
                  final pro = professionals[i];
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
              if (userLocationAvailable)
                Positioned(
                  left: constraints.maxWidth * 0.50 - 12,
                  top: constraints.maxHeight * 0.50 - 12,
                  child: _UserDot(),
                ),

              // Mapbox attribution
              const Positioned(bottom: 6, left: 8, child: _MapboxBadge()),

              // Count badge
              Positioned(
                bottom: 6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${services.length} services · ${professionals.length} pros',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

// ─── Mapbox Badge ─────────────────────────────────────────────────────────────

class _MapboxBadge extends StatelessWidget {
  const _MapboxBadge();

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

// ─── Urban Streets Painter ────────────────────────────────────────────────────

class _UrbanStreetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()..color = const Color(0xFFE2DDD4);
    final streetPaint = Paint()
      ..color = const Color(0xFFFFFBF5)
      ..strokeWidth = 6;
    final minorStreetPaint = Paint()
      ..color = const Color(0xFFF5F0E8)
      ..strokeWidth = 3;
    final greenPaint = Paint()..color = const Color(0xFFD4E8C2);

    // City blocks
    final blocks = [
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.05,
        size.width * 0.18,
        size.height * 0.22,
      ),
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.05,
        size.width * 0.20,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.54,
        size.height * 0.08,
        size.width * 0.16,
        size.height * 0.20,
      ),
      Rect.fromLTWH(
        size.width * 0.75,
        size.height * 0.05,
        size.width * 0.20,
        size.height * 0.25,
      ),
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.35,
        size.width * 0.22,
        size.height * 0.20,
      ),
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.30,
        size.width * 0.18,
        size.height * 0.22,
      ),
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.35,
        size.width * 0.20,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.78,
        size.height * 0.35,
        size.width * 0.17,
        size.height * 0.22,
      ),
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.62,
        size.width * 0.20,
        size.height * 0.22,
      ),
      Rect.fromLTWH(
        size.width * 0.30,
        size.height * 0.60,
        size.width * 0.22,
        size.height * 0.20,
      ),
      Rect.fromLTWH(
        size.width * 0.58,
        size.height * 0.62,
        size.width * 0.18,
        size.height * 0.22,
      ),
      Rect.fromLTWH(
        size.width * 0.80,
        size.height * 0.62,
        size.width * 0.15,
        size.height * 0.20,
      ),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(3)),
        blockPaint,
      );
    }

    // Green spaces
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.40,
          size.height * 0.55,
          size.width * 0.14,
          size.height * 0.14,
        ),
        const Radius.circular(6),
      ),
      greenPaint,
    );

    // Major streets (horizontal)
    for (final y in [0.28, 0.55, 0.85]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        streetPaint,
      );
    }
    // Major streets (vertical)
    for (final x in [0.26, 0.52, 0.76]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        streetPaint,
      );
    }
    // Minor streets
    for (final y in [0.15, 0.42, 0.70]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        minorStreetPaint,
      );
    }
    for (final x in [0.13, 0.39, 0.65, 0.88]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        minorStreetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Water Painter ────────────────────────────────────────────────────────────

class _WaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFB8D4E8).withAlpha(120);
    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.68,
        size.width * 0.50,
        size.height * 0.76,
        size.width * 0.75,
        size.height * 0.70,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.67,
        size.width * 0.95,
        size.height * 0.72,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height * 0.78)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.80,
        size.width * 0.50,
        size.height * 0.84,
        size.width * 0.25,
        size.height * 0.78,
      )
      ..lineTo(0, size.height * 0.80)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
