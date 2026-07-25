import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import 'map_filter_chips_widget.dart';
import 'map_search_bar_widget.dart';

class MapSearchView extends StatelessWidget {
  final List<Map<String, dynamic>> properties;
  final String searchQuery;
  final String activeFilter;
  final bool hasActiveFilters;
  final Function(String) onSearch;
  final Function(String) onFilterChanged;
  final Function(Map<String, dynamic>) onLocateOnMap;
  final Function(Map<String, dynamic>) onPropertyTap;
  final VoidCallback onShowAdvancedFilters;
  final VoidCallback? onBackToMap;

  const MapSearchView({
    super.key,
    required this.properties,
    required this.searchQuery,
    required this.activeFilter,
    required this.hasActiveFilters,
    required this.onSearch,
    required this.onFilterChanged,
    required this.onLocateOnMap,
    required this.onPropertyTap,
    required this.onShowAdvancedFilters,
    this.onBackToMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exploration',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Trouvez la perle rare parmi nos annonces',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MapSearchBarWidget(
                onSearch: onSearch,
                onFilterTap: onShowAdvancedFilters,
                hasActiveFilters: hasActiveFilters,
                onBack: onBackToMap,
              ),
            ),

            // Filter Chips Widget
            MapFilterChipsWidget(
              activeFilter: activeFilter,
              onFilterChanged: onFilterChanged,
            ),

            // Results count badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${properties.length} annonce${properties.length != 1 ? 's' : ''} trouvée${properties.length != 1 ? 's' : ''}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (searchQuery.isNotEmpty || hasActiveFilters)
                    GestureDetector(
                      onTap: () {
                        onSearch('');
                        onFilterChanged('Tous');
                      },
                      child: Text(
                        'Réinitialiser',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Property Listings List
            Expanded(
              child: properties.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final property = properties[index];
                        return _buildPropertyCard(context, property);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, Map<String, dynamic> property) {
    final isSponsored = property['isSponsored'] as bool? ?? false;
    final isRent = property['listingType'] == 'rent';
    final price = property['price'] as int? ?? 0;
    
    // Format price
    String priceLabel;
    if (isRent) {
      priceLabel = '$price € / mois';
    } else {
      if (price >= 1000000) {
        priceLabel = '${(price / 1000000).toStringAsFixed(2).replaceAll('.', ',')} M €';
      } else {
        priceLabel = '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} €';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSponsored ? AppTheme.accent.withAlpha(120) : AppTheme.border,
          width: isSponsored ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSponsored 
                ? AppTheme.accent.withAlpha(20) 
                : Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => onPropertyTap(property),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and Badges
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: AppTheme.surfaceVariant,
                      child: property['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              property['imageUrl'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.image_not_supported_rounded, size: 40)),
                            )
                          : const Center(child: Icon(Icons.home_work_rounded, size: 40)),
                    ),
                  ),

                  // Background Gradient on image bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(0),
                            Colors.black.withAlpha(100),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tag type (Acheter / Louer)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isRent ? AppTheme.forRent : AppTheme.forSale,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: (isRent ? AppTheme.forRent : AppTheme.forSale).withAlpha(100),
                            blurRadius: 8,
                          )
                        ]
                      ),
                      child: Text(
                        isRent ? 'LOCATION' : 'ACHAT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Sponsored Tag
                  if (isSponsored)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withAlpha(100),
                              blurRadius: 8,
                            )
                          ]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'SPONSORISÉ',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Price Overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(
                      priceLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property['title']?.toString() ?? '',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppTheme.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property['address']?.toString() ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.border),
                    const SizedBox(height: 8),

                    // Features & Locate Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Features (surface, rooms)
                        Row(
                          children: [
                            if (property['surface'] != null && property['surface'] > 0) ...[
                              Icon(Icons.square_foot_rounded, size: 16, color: AppTheme.muted),
                              const SizedBox(width: 4),
                              Text(
                                '${property['surface']} m²',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (property['rooms'] != null && property['rooms'] > 0) ...[
                              Icon(Icons.bed_rounded, size: 16, color: AppTheme.muted),
                              const SizedBox(width: 4),
                              Text(
                                '${property['rooms']} p.',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Locate Button
                        ElevatedButton.icon(
                          onPressed: () => onLocateOnMap(property),
                          icon: const Icon(Icons.map_rounded, size: 14),
                          label: Text(
                            'Carte',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                            minimumSize: const Size(80, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune annonce trouvée',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Essayez de modifier votre recherche ou d\'ajuster vos filtres.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
