import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../services/currency_service.dart';

class MapPropertyBottomSheetWidget extends StatelessWidget {
  final List<Map<String, dynamic>> properties;
  final int selectedIndex;
  final Function(int) onPropertySelected;
  final Function(Map<String, dynamic>) onPropertyTap;
  final bool isTabletPanel;
  final VoidCallback? onRefresh;

  const MapPropertyBottomSheetWidget({
    super.key,
    required this.properties,
    required this.selectedIndex,
    required this.onPropertySelected,
    required this.onPropertyTap,
    this.isTabletPanel = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isTabletPanel) {
      return _buildTabletPanel(context);
    }
    return _buildPhoneSheet(context);
  }

  Widget _buildPhoneSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          // Horizontal scroll cards or empty state
          properties.isEmpty
              ? _buildEmptyStateOverlay(context)
              : SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      return _PropertyPreviewCard(
                        property: properties[index],
                        isSelected: selectedIndex == index,
                        onTap: () {
                          onPropertySelected(index);
                          onPropertyTap(properties[index]);
                        },
                      );
                    },
                  ),
                ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyStateOverlay(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.border.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off_outlined,
            size: 32,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune annonce trouvée à proximité',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Élargissez vos filtres ou actualisez.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (onRefresh != null)
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Actualiser',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.isDark ? Colors.black : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabletPanel(BuildContext context) {
    if (properties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_off_outlined,
                size: 54,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun bien trouvé',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez d\'actualiser ou de modifier vos filtres.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (onRefresh != null)
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Actualiser',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PropertyListTile(
            property: properties[index],
            isSelected: selectedIndex == index,
            onTap: () {
              onPropertySelected(index);
              onPropertyTap(properties[index]);
            },
          ),
        );
      },
    );
  }
}

class _PropertyPreviewCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final bool isSelected;
  final VoidCallback onTap;

  const _PropertyPreviewCard({
    required this.property,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRent = property['listingType'] == 'rent';
    final price = property['price'] as int;
    final priceText = CurrencyService.instance.format(price, isRent: isRent);
    final isSponsored = (property['isSponsored'] as bool?) ?? false;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSponsored
                ? const Color(0xFFF97316)
                : isSelected
                ? AppTheme.primary
                : AppTheme.border,
            width: isSponsored || isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Stack(
                children: [
                  CustomImageWidget(
                    imageUrl: property['imageUrl'] as String,
                    width: 240,
                    height: 110,
                    fit: BoxFit.cover,
                    semanticLabel: property['semanticLabel'] as String,
                  ),
                  if (isSponsored)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Sponsorisé',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (property['isNew'] as bool)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Nouveau',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusBadgeWidget(
                      status: isRent
                          ? PropertyStatus.forRent
                          : PropertyStatus.forSale,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['title'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          property['address'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceText,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 12,
                            color: AppTheme.muted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${property['surface']}m²',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyListTile extends StatelessWidget {
  final Map<String, dynamic> property;
  final bool isSelected;
  final VoidCallback onTap;

  const _PropertyListTile({
    required this.property,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRent = property['listingType'] == 'rent';
    final price = property['price'] as int;
    final priceText = CurrencyService.instance.format(price, isRent: isRent);
    final isSponsored = (property['isSponsored'] as bool?) ?? false;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(13) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSponsored
                ? const Color(0xFFF97316)
                : isSelected
                ? AppTheme.primary
                : AppTheme.border,
            width: isSponsored || isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImageWidget(
                imageUrl: property['imageUrl'] as String,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                semanticLabel: property['semanticLabel'] as String,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSponsored)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Color(0xFFF97316),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Sponsorisé',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    property['title'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${property['surface']}m² · ${property['rooms']} pièces',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isRent ? AppTheme.info : AppTheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
