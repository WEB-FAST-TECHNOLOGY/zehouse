import '../../core/app_export.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/currency_service.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../services/mapbox_service.dart';
import '../../services/messaging_service.dart';
import '../../widgets/global_banner_ad_widget.dart';
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
  bool _isLoading = true;
  bool _hasError = false;

  Map<String, dynamic>? _property;

  @override
  void initState() {
    super.initState();
    _loadFavoriteCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_property == null && _isLoading) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['id'] != null) {
        _fetchProperty(args['id'].toString());
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProperty(String id) async {
    try {
      final cleanId = id.startsWith('ul_') ? id.substring(3) : id;
      final response = await SupabaseService.instance.client
          .from('user_listings')
          .select('*, user_profiles(*)')
          .eq('id', cleanId)
          .single();
      
      // Increment views count
      final currentViews = response['views_count'] ?? 0;
      await SupabaseService.instance.client
          .from('user_listings')
          .update({'views_count': currentViews + 1})
          .eq('id', cleanId);

      if (mounted) {
        setState(() {
          _property = _mapResponseToProperty(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _mapResponseToProperty(Map<String, dynamic> item) {
    return {
      'id': item['id'].toString(),
      'title': item['title'] ?? '',
      'address': item['address'] ?? '',
      'neighborhood': item['address'] ?? '', // No city explicitly saved for now, reuse address
      'price': item['price'] ?? 0,
      'pricePerM2': (item['price'] != null && item['surface'] != null && item['surface'] > 0) 
          ? (item['price'] / item['surface']).round() 
          : 0,
      'surface': (item['surface'] as num?)?.toDouble() ?? 0.0,
      'rooms': item['rooms'] ?? 1,
      'bedrooms': item['rooms'] ?? 1, // Fallback to rooms
      'bathrooms': 1,
      'floor': 0,
      'totalFloors': 1,
      'type': item['property_type'] ?? 'Appartement',
      'listingType': item['listing_type'] ?? 'sale',
      'daysOnMarket': DateTime.now().difference(DateTime.parse(item['created_at'])).inDays,
      'energyClass': 'NC',
      'yearBuilt': 2024,
      'description': item['description'] ?? '',
      'images': _parseImages(item),
      'lat': item['lat'] != null ? (item['lat'] as num).toDouble() : null,
      'lng': item['lng'] != null ? (item['lng'] as num).toDouble() : null,
      'agent': _parseAgent(item['user_profiles']),
    };
  }

  List<Map<String, dynamic>> _parseImages(Map<String, dynamic> item) {
    List<Map<String, dynamic>> images = [];
    
    // Add video if present
    if (item['video_url'] != null && item['video_url'].toString().isNotEmpty) {
      images.add({
        'url': item['image_url'] ?? '', // Thumbnail fallback
        'videoUrl': item['video_url'],
        'semanticLabel': 'Video',
        'isVideo': true,
      });
    }

    // Add images from image_urls array
    if (item['image_urls'] != null && (item['image_urls'] as List).isNotEmpty) {
      for (var url in (item['image_urls'] as List)) {
        images.add({
          'url': url,
          'semanticLabel': item['title'] ?? 'Listing image',
          'isVideo': false,
        });
      }
    } else {
      // Fallback to single image_url
      images.add({
        'url': item['image_url'] ?? 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
        'semanticLabel': item['title'] ?? 'Listing image',
        'isVideo': false,
      });
    }
    return images;
  }

  Map<String, dynamic> _parseAgent(dynamic profile) {
    if (profile == null) {
      return {
        'name': 'Propriétaire Zehouse',
        'agency': 'Particulier',
        'phone': 'N/A',
        'email': 'N/A',
        'rating': 5.0,
        'reviews': 0,
        'avatar': 'https://img.rocket.new/generatedImages/rocket_gen_img_1a0174142-1763295020963.png',
        'avatarSemanticLabel': 'Avatar',
        'responseTime': '< 24h',
        'activeListings': 1,
      };
    }
    
    return {
      'id': profile['id'],
      'name': profile['full_name'] ?? 'Utilisateur',
      'agency': profile['role'] == 'professional' ? 'Professionnel' : 'Particulier',
      'phone': profile['phone'] ?? 'N/A',
      'email': profile['email'] ?? 'N/A',
      'rating': 5.0,
      'reviews': 0,
      'avatar': profile['avatar_url'] ?? 'https://img.rocket.new/generatedImages/rocket_gen_img_1a0174142-1763295020963.png',
      'avatarSemanticLabel': profile['full_name'] ?? 'Avatar',
      'responseTime': '< 24h',
      'activeListings': 1, // Optional: count from user_listings
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasError || _property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Annonce introuvable ou erreur de chargement.')),
      );
    }
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomCTA(),
          const GlobalBannerAdWidget(),
        ],
      ),
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
                _property!['images'] as List,
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
                    _property!['images'] as List,
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
    final isRent = _property!['listingType'] == 'rent';
    final price = _property!['price'] as int;
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
                        color: _property!['daysOnMarket'] as int <= 7
                            ? AppTheme.successLight
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _property!['daysOnMarket'] as int <= 7
                            ? 'Nouveau · ${_property!['daysOnMarket']}j'
                            : '${_property!['daysOnMarket']} jours sur le marché',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _property!['daysOnMarket'] as int <= 7
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _property!['title'] as String,
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
                        _property!['address'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        CurrencyService.instance.formatPerM2(
                          _property!['pricePerM2'] as int,
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
          PropertySpecsWidget(property: _property!),

          const SizedBox(height: 8),

          // Description
          PropertyDescriptionWidget(
            description: _property!['description'] as String,
          ),

          const SizedBox(height: 8),

          // Price trend chart
          PropertyPriceTrendWidget(
            neighborhood: _property!['neighborhood'] as String,
          ),

          const SizedBox(height: 8),

          // Mini map
          PropertyMiniMapWidget(
            address: _property!['address'] as String,
            lat: _property!['lat'] as double?,
            lng: _property!['lng'] as double?,
          ),

          const SizedBox(height: 8),

          // Agent card
          PropertyAgentCardWidget(
            agent: Map<String, dynamic>.from(_property!['agent'] as Map),
            onMessage: () => _handleMessage(),
            onCall: () => _handleCall(_property!['agent']['phone']),
          ),

          const SizedBox(height: 8),

          // Report listing
          Center(
            child: ReportListingWidget(
              listingId: _property!['id'] as String,
              listingTitle: _property!['title'] as String,
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

  void _handleCall(String? phone) async {
    if (phone == null || phone == 'N/A') return;
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _handleMessage() async {
    final agentId = _property!['agent']['id'] as String?;
    final title = _property!['title'] as String? ?? 'Annonce';
    
    if (agentId == null) {
      Navigator.pushNamed(context, AppRoutes.messagesScreen);
      return;
    }
    
    String propImage = '';
    final images = _property!['images'] as List?;
    if (images != null && images.isNotEmpty) {
      propImage = images.first['url'] as String? ?? '';
    }

    final rawPrice = (_property!['price'] as num?)?.toInt() ?? 0;
    final isRent = (_property!['listingType'] as String?) == 'rent';
    final price = CurrencyService.instance.format(rawPrice, isRent: isRent);

    try {
      final convId = await MessagingService.instance.getOrCreateConversation(
        otherUserId: agentId,
        propertyTitle: title,
        propertyImageUrl: propImage,
        propertyPrice: price,
      );
      if (convId != null) {
        Navigator.pushNamed(context, AppRoutes.messagesScreen, arguments: {'conversationId': convId});
      } else {
        Navigator.pushNamed(context, AppRoutes.messagesScreen);
      }
    } catch (_) {
      Navigator.pushNamed(context, AppRoutes.messagesScreen);
    }
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
                onPressed: () => _handleCall(_property!['agent']['phone']),
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
                onPressed: () {
                  if (_property!['lat'] != null && _property!['lng'] != null) {
                    MapboxService.startInAppNavigation(
                      destLat: _property!['lat'],
                      destLng: _property!['lng'],
                      destName: _property!['title'],
                    );
                  }
                },
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
                onPressed: () => _handleMessage(),
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
