import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PropertySpecsWidget extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertySpecsWidget({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caractéristiques',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SpecItem(
                icon: Icons.straighten_rounded,
                label: 'Surface',
                value: '${property['surface']}m²',
              ),
              _SpecItem(
                icon: Icons.meeting_room_rounded,
                label: 'Pièces',
                value: '${property['rooms']}',
              ),
              _SpecItem(
                icon: Icons.bed_rounded,
                label: 'Chambres',
                value: '${property['bedrooms']}',
              ),
              _SpecItem(
                icon: Icons.bathtub_rounded,
                label: 'SDB',
                value: '${property['bathrooms']}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _SpecItem(
                icon: Icons.layers_rounded,
                label: 'Étage',
                value: '${property['floor']}/${property['totalFloors']}',
              ),
              _SpecItem(
                icon: Icons.calendar_today_rounded,
                label: 'Construit',
                value: '${property['yearBuilt']}',
              ),
              _SpecItem(
                icon: Icons.eco_rounded,
                label: 'DPE',
                value: property['energyClass'] as String,
                valueColor: _getDpeColor(property['energyClass'] as String),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDpeColor(String dpe) {
    switch (dpe) {
      case 'A':
        return const Color(0xFF16A34A);
      case 'B':
        return const Color(0xFF65A30D);
      case 'C':
        return const Color(0xFFD97706);
      case 'D':
        return const Color(0xFFEA580C);
      case 'E':
        return const Color(0xFFDC2626);
      default:
        return AppTheme.muted;
    }
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
