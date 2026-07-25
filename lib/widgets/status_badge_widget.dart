import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PropertyStatus { published, underOffer, archived, draft, forSale, forRent }

class StatusBadgeWidget extends StatelessWidget {
  final PropertyStatus status;
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: GoogleFonts.outfit(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(PropertyStatus s) {
    switch (s) {
      case PropertyStatus.published:
        return _StatusConfig(
          'Publié',
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          const Color(0xFF16A34A),
        );
      case PropertyStatus.underOffer:
        return _StatusConfig(
          'Sous offre',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          const Color(0xFFD97706),
        );
      case PropertyStatus.archived:
        return _StatusConfig(
          'Archivé',
          const Color(0xFFF3F4F6),
          const Color(0xFF9CA3AF),
          const Color(0xFF6B7280),
        );
      case PropertyStatus.draft:
        return _StatusConfig(
          'Brouillon',
          const Color(0xFFF3F0FF),
          const Color(0xFF7C3AED),
          const Color(0xFF7C3AED),
        );
      case PropertyStatus.forSale:
        return _StatusConfig(
          'Vente',
          const Color(0xFFE8EDF5),
          const Color(0xFF1A2B4A),
          const Color(0xFF1A2B4A),
        );
      case PropertyStatus.forRent:
        return _StatusConfig(
          'Location',
          const Color(0xFFF3F0FF),
          const Color(0xFF7C3AED),
          const Color(0xFF7C3AED),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color background;
  final Color dotColor;
  final Color textColor;
  const _StatusConfig(
    this.label,
    this.background,
    this.dotColor,
    this.textColor,
  );
}
