import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MapFilterChipsWidget extends StatelessWidget {
  final String activeFilter;
  final Function(String) onFilterChanged;

  const MapFilterChipsWidget({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const List<Map<String, dynamic>> _filters = [
    {'label': 'Tous', 'icon': Icons.layers_rounded},
    {'label': 'Acheter', 'icon': Icons.sell_rounded},
    {'label': 'Louer', 'icon': Icons.key_rounded},
    {'label': 'Appartement', 'icon': Icons.apartment_rounded},
    {'label': 'Maison', 'icon': Icons.house_rounded},
    {'label': 'Studio', 'icon': Icons.single_bed_rounded},
    {'label': 'Loft', 'icon': Icons.warehouse_rounded},
    {'label': 'Hôtel', 'icon': Icons.hotel_rounded},
    {'label': 'Appt. Meublé', 'icon': Icons.chair_rounded},
    {'label': 'Camping-car', 'icon': Icons.rv_hookup_rounded},
    {'label': 'Salle de Fêtes', 'icon': Icons.celebration_rounded},
    {'label': 'Bureau', 'icon': Icons.business_center_rounded},
    {'label': 'Déménagement', 'icon': Icons.local_shipping_rounded},
    {'label': 'Entretien', 'icon': Icons.build_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = activeFilter == filter['label'];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isActive ? AppTheme.primary : AppTheme.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => onFilterChanged(filter['label'] as String),
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 14,
                      color: isActive ? Colors.white : AppTheme.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filter['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
