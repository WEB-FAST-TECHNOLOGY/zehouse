import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../services/currency_service.dart';

class MyListingCardWidget extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onActionsTap;
  final VoidCallback onTap;

  const MyListingCardWidget({
    super.key,
    required this.listing,
    required this.onActionsTap,
    required this.onTap,
  });

  PropertyStatus _getStatus(String status) {
    switch (status) {
      case 'published':
        return PropertyStatus.published;
      case 'underOffer':
        return PropertyStatus.underOffer;
      case 'archived':
        return PropertyStatus.archived;
      case 'draft':
        return PropertyStatus.draft;
      default:
        return PropertyStatus.draft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRent = listing['listingType'] == 'rent';
    final price = listing['price'] as int;
    final priceText = CurrencyService.instance.format(price, isRent: isRent);
    final status = listing['status'] as String;
    final isArchived = status == 'archived';
    final priceDropped = listing['priceDropped'] as bool;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isArchived ? AppTheme.border : AppTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Opacity(
                    opacity: isArchived ? 0.6 : 1.0,
                    child: CustomImageWidget(
                      imageUrl: listing['imageUrl'] as String,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      semanticLabel: listing['semanticLabel'] as String,
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: StatusBadgeWidget(status: _getStatus(status)),
                ),
                // Price drop badge
                if (priceDropped)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_down_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Prix baissé',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Actions menu
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onActionsTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing['title'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isArchived
                                    ? AppTheme.muted
                                    : AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              listing['address'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Price + surface
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceText,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isArchived ? AppTheme.muted : AppTheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 13,
                            color: AppTheme.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${listing['surface']}m² · ${listing['rooms']} pièces',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.visibility_rounded,
                        value: '${listing['views']}',
                        label: 'vues',
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: Icons.chat_bubble_rounded,
                        value: '${listing['contacts']}',
                        label: 'contacts',
                        highlight: (listing['contacts'] as int) > 5,
                      ),
                      const Spacer(),
                      if ((listing['daysActive'] as int) > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: (listing['daysActive'] as int) > 30
                                  ? AppTheme.warning
                                  : AppTheme.muted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${listing['daysActive']}j',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (listing['daysActive'] as int) > 30
                                    ? AppTheme.warning
                                    : AppTheme.muted,
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: highlight ? AppTheme.success : AppTheme.muted,
        ),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
            color: highlight ? AppTheme.success : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
