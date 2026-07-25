import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/mapbox_service.dart';

/// Web stub — Mapbox is not supported on web.
Widget buildMiniMap({required String address}) {
  return _SimulatedMiniMap(address: address);
}

class _SimulatedMiniMap extends StatelessWidget {
  final String address;
  const _SimulatedMiniMap({required this.address});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            color: const Color(0xFFE8EFF6),
            child: CustomPaint(painter: _MiniMapPainter()),
          ),
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
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => MapboxService.openDirectionsByAddress(address),
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

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final streetPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 8;
    final minorPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 4;

    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.45, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      minorPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      minorPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.70, 0),
      Offset(size.width * 0.70, size.height),
      minorPaint,
    );

    final blockPaint = Paint()..color = const Color(0xFFD8E4EF);
    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width * 0.22 - 8, size.height * 0.38 - 8),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.25 + 4,
        8,
        size.width * 0.2 - 8,
        size.height * 0.38 - 8,
      ),
      blockPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.45 + 4,
        size.height * 0.4 + 4,
        size.width * 0.24 - 8,
        size.height * 0.24 - 8,
      ),
      blockPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
