import '../../core/app_export.dart';
import '../../services/currency_service.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/report_listing_widget.dart';
import './widgets/property_agent_card_widget.dart';
import './widgets/property_description_widget.dart';
import './widgets/property_gallery_widget.dart';
import './widgets/property_mini_map_widget.dart';
import './widgets/property_price_trend_widget.dart';
import './widgets/property_specs_widget.dart';

class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  // TODO: Replace with Riverpod for production
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  int _userFavoriteCount = 0;

  final Map<String, dynamic> _property = {
    'id': 'p1',
    'title': 'Appartement Haussmannien Lumineux',
    'address': '12 Rue de la Paix, 75001 Paris',
    'neighborhood': 'Opéra – 1er arrondissement',
    'price': 850000,
    'pricePerM2': 9770,
    'surface': 87.0,
    'rooms': 4,
    'bedrooms': 3,
    'bathrooms': 2,
    'floor': 3,
    'totalFloors': 6,
    'type': 'Appartement',
    'listingType': 'sale',
    'daysOnMarket': 5,
    'energyClass': 'C',
    'yearBuilt': 1892,
    'description':
        'Magnifique appartement Haussmannien au cœur de Paris, entièrement rénové avec des matériaux haut de gamme. Parquet en chêne massif, moulures d\'époque, haute plafond à 3,20m. Vue dégagée sur les toits parisiens depuis le salon double de 35m². Cuisine équipée, deux salles de bain en marbre. Cave et possibilité de parking.',
    'images': [
      {
        'url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1a002677e-1772365142336.png',
        'semanticLabel':
            'Spacious Haussmann living room with parquet floors, ornate moldings and tall windows',
      },
      {
        'url': 'https://images.unsplash.com/photo-1722604817803-4c88edef9bc0',
        'semanticLabel':
            'Modern renovated kitchen with marble countertops and stainless steel appliances',
      },
      {
        'url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_146cc8ee3-1772751062741.png',
        'semanticLabel':
            'Master bedroom with parquet floor, large windows and neutral tones',
      },
      {
        'url':
            'https://img.rocket.new/generatedImages/rocket_gen_img_173313a03-1773164996010.png',
        'semanticLabel':
            'Elegant bathroom with marble walls and freestanding bathtub',
      },
    ],
    'agent': {
      'name': 'Sophie Marchand',
      'agency': 'ZEHOUSE Premium Paris',
      'phone': '+33 6 12 34 56 78',
      'email': 'sophie.marchand@zehouse.fr',
      'rating': 4.9,
      'reviews': 127,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1a0174142-1763295020963.png',
      'avatarSemanticLabel':
          'Professional headshot of French female real estate agent with brown hair in business attire',
      'responseTime': '< 1h',
      'activeListings': 14,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadFavoriteCount();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppTheme.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: _buildBackButton(),
          actions: [
            _buildFavoriteButton(),
            _buildShareButton(),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: PropertyGalleryWidget(
              images: List<Map<String, dynamic>>.from(
                _property['images'] as List,
              ),
              currentIndex: _currentImageIndex,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildPropertyContent()),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: gallery
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                PropertyGalleryWidget(
                  images: List<Map<String, dynamic>>.from(
                    _property['images'] as List,
                  ),
                  currentIndex: _currentImageIndex,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  isTablet: true,
                ),
                Positioned(top: 16, left: 16, child: _buildBackButton()),
              ],
            ),
          ),
          // Right: details
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildPropertyContent(isTablet: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyContent({bool isTablet = false}) {
    final isRent = _property['listingType'] == 'rent';
    final price = _property['price'] as int;
    final priceText = CurrencyService.instance.format(price, isRent: isRent);

    return Container(
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type + Days badge
                Row(
                  children: [
                    StatusBadgeWidget(
                      status: isRent
                          ? PropertyStatus.forRent
                          : PropertyStatus.forSale,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _property['daysOnMarket'] as int <= 7
                            ? AppTheme.successLight
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _property['daysOnMarket'] as int <= 7
                            ? 'Nouveau · ${_property['daysOnMarket']}j'
                            : '${_property['daysOnMarket']} jours sur le marché',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _property['daysOnMarket'] as int <= 7
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _property['title'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _property['address'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceText,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        CurrencyService.instance.formatPerM2(
                          _property['pricePerM2'] as int,
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Specs
          PropertySpecsWidget(property: _property),

          const SizedBox(height: 8),

          // Description
          PropertyDescriptionWidget(
            description: _property['description'] as String,
          ),

          const SizedBox(height: 8),

          // Price trend chart
          PropertyPriceTrendWidget(
            neighborhood: _property['neighborhood'] as String,
          ),

          const SizedBox(height: 8),

          // Mini map
          PropertyMiniMapWidget(address: _property['address'] as String),

          const SizedBox(height: 8),

          // Agent card
          PropertyAgentCardWidget(
            agent: Map<String, dynamic>.from(_property['agent'] as Map),
            onMessage: () =>
                Navigator.pushNamed(context, AppRoutes.messagesScreen),
            onCall: () {},
          ),

          const SizedBox(height: 8),

          // Report listing
          Center(
            child: ReportListingWidget(
              listingId: _property['id'] as String,
              listingTitle: _property['title'] as String,
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  bool get _isProfessional {
    final sub = SubscriptionService.instance.current;
    return sub.isActive && sub.plan != SubscriptionPlan.none;
  }

  Future<void> _loadFavoriteCount() async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await SupabaseService.instance.client
          .from('saved_properties')
          .select('id')
          .eq('user_id', user.id);
      if (mounted) {
        setState(() => _userFavoriteCount = (data as List).length);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (!_isFavorite && !_isProfessional) {
      // Check favorite limit for non-professional users
      await _loadFavoriteCount();
      if (_userFavoriteCount >= SubscriptionService.freeTierMaxFavorites) {
        _showFavoriteLimitDialog();
        return;
      }
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  void _showFavoriteLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 32,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Limite de favoris atteinte',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez atteint la limite de ${SubscriptionService.freeTierMaxFavorites} favoris gratuits. Abonnez-vous pour des favoris illimités.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Voir les abonnements',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: _toggleFavorite,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isFavorite ? AppTheme.accent.withAlpha(26) : Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 18,
            color: _isFavorite ? AppTheme.accent : AppTheme.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.share_rounded, size: 18, color: AppTheme.muted),
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('Appeler'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.mapScreen),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Itinéraire'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppTheme.accent,
                  side: BorderSide(color: AppTheme.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.messagesScreen),
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
