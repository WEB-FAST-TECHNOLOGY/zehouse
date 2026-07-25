import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_export.dart';
import './widgets/my_listing_card_widget.dart';
import './widgets/my_listings_stats_widget.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with Riverpod for production
  int _currentNavIndex = 4;
  late TabController _tabController;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _listingMaps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMyListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyListings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('user_listings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final fetchedListings = (response as List).map((item) {
        return {
          'id': item['id'].toString(),
          'title': item['title'] ?? '',
          'address': item['address'] ?? '',
          'price': item['price'] ?? 0,
          'surface': (item['surface'] as num?)?.toDouble() ?? 0.0,
          'rooms': item['rooms'] ?? 1,
          'type': item['property_type'] ?? 'Appartement',
          'listingType': item['listing_type'] ?? 'sale',
          'status': (item['is_active'] == true) ? 'published' : 'archived',
          'views': 45,
          'contacts': 2,
          'daysActive': 3,
          'imageUrl': item['image_url'] ?? 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
          'priceDropped': false,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _listingMaps.clear();
          _listingMaps.addAll(fetchedListings);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredListings(String statusFilter) {
    if (statusFilter == 'all') return _listingMaps;
    return _listingMaps.where((l) => l['status'] == statusFilter).toList();
  }

  int _getCountForStatus(String status) {
    if (status == 'all') return _listingMaps.length;
    return _listingMaps.where((l) => l['status'] == status).length;
  }

  void _onNavTap(int index) {
    // TODO: Replace with Riverpod for production
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mapScreen,
          (r) => false,
        );
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mapScreen,
          (r) => false,
        );
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.publishListingScreen);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.messagesScreen);
        break;
      case 4:
        // Already on Mes Annonces screen — do nothing
        break;
      case 5:
        Navigator.pushNamed(context, AppRoutes.profileScreen);
        break;
    }
  }

  void _showListingActions(BuildContext context, Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ListingActionsSheet(
        listing: listing,
        onEdit: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.publishListingScreen);
        },
        onPause: () async {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          try {
            final isPublished = listing['status'] == 'published';
            await Supabase.instance.client
                .from('user_listings')
                .update({'is_active': !isPublished})
                .eq('id', listing['id']);
            _loadMyListings();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  isPublished ? 'Annonce mise en pause' : 'Annonce réactivée',
                  style: GoogleFonts.outfit(),
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } catch (e) {
            // handle error
          }
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteConfirmation(context, listing);
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> listing,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer l\'annonce',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${listing['title']}" ? Cette action est irréversible.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(color: AppTheme.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('user_listings')
                    .delete()
                    .eq('id', listing['id']);
                _loadMyListings();
              } catch (e) {
                // handle error
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final activeCount = _getCountForStatus('published');
    final totalViews = _listingMaps.fold<int>(
      0,
      (sum, l) => sum + (l['views'] as int),
    );
    final totalContacts = _listingMaps.fold<int>(
      0,
      (sum, l) => sum + (l['contacts'] as int),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.surface,
              elevation: 0,
              scrolledUnderElevation: 1,
              automaticallyImplyLeading: false,
              title: Text(
                'Mes annonces',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add_rounded, color: AppTheme.primary),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.publishListingScreen,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 2,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.muted,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: [
                    Tab(text: 'Toutes (${_getCountForStatus('all')})'),
                    Tab(text: 'Publiées ($activeCount)'),
                    Tab(
                      text: 'Sous offre (${_getCountForStatus('underOffer')})',
                    ),
                    Tab(text: 'Archivées (${_getCountForStatus('archived')})'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Stats summary
            MyListingsStatsWidget(
              activeListings: activeCount,
              totalViews: totalViews,
              totalContacts: totalContacts,
              newInquiries: 3,
            ),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: ['all', 'published', 'underOffer', 'archived'].map((
                        status,
                      ) {
                        final listings = _getFilteredListings(status);
                        if (listings.isEmpty) {
                          return EmptyStateWidget(
                            icon: Icons.home_work_outlined,
                            title: 'Aucune annonce',
                            description:
                                'Vous n\'avez pas encore d\'annonce dans cette catégorie.',
                            ctaLabel: 'Publier une annonce',
                            onCta: () => Navigator.pushNamed(
                              context,
                              AppRoutes.publishListingScreen,
                            ),
                          );
                        }
                        return isTablet
                            ? _buildTabletGrid(listings)
                            : _buildPhoneList(listings);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.publishListingScreen),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nouvelle annonce',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildPhoneList(List<Map<String, dynamic>> listings) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MyListingCardWidget(
            listing: listings[index],
            onActionsTap: () => _showListingActions(context, listings[index]),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.propertyDetailScreen),
          ),
        );
      },
    );
  }

  Widget _buildTabletGrid(List<Map<String, dynamic>> listings) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        return MyListingCardWidget(
          listing: listings[index],
          onActionsTap: () => _showListingActions(context, listings[index]),
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.propertyDetailScreen),
        );
      },
    );
  }
}

class _ListingActionsSheet extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onDelete;

  const _ListingActionsSheet({
    required this.listing,
    required this.onEdit,
    required this.onPause,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              listing['title'] as String,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.edit_rounded,
              label: 'Modifier l\'annonce',
              onTap: onEdit,
            ),
            _ActionTile(
              icon: listing['status'] == 'published'
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_fill_rounded,
              label: listing['status'] == 'published'
                  ? 'Mettre en pause'
                  : 'Réactiver l\'annonce',
              onTap: onPause,
            ),
            const Divider(height: 24),
            _ActionTile(
              icon: Icons.delete_rounded,
              label: 'Supprimer l\'annonce',
              onTap: onDelete,
              isDestructive: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.errorLight
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
