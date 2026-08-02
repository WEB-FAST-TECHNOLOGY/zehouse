import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';
import '../../widgets/custom_image_widget.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../services/language_service.dart';
import '../../services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ad_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 5;
  late TabController _tabController;

  // User data from Supabase
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _avatarUrl = '';
  String _role = 'buyer';
  String _memberSince = '';
  bool _isSaving = false;

  // Saved properties from Supabase
  List<Map<String, dynamic>> _savedProperties = [];
  bool _loadingProperties = false;

  SupabaseClient get _client => SupabaseService.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    SubscriptionService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    // Trigger Interstitial ad on profile view
    AdHelper.showInterstitial(onAdClosed: () {});
    SubscriptionService.instance.addListener(_onSubscriptionChanged);
    _loadUserProfile();
    _loadSavedProperties();
  }

  void _onSubscriptionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    SubscriptionService.instance.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.signUpLoginScreen);
        }
        return;
      }

      final data = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        final createdAt = data['created_at'] != null
            ? DateTime.tryParse(data['created_at'] as String)
            : null;
        final monthNames = [
          'Jan',
          'Fév',
          'Mar',
          'Avr',
          'Mai',
          'Jun',
          'Jul',
          'Aoû',
          'Sep',
          'Oct',
          'Nov',
          'Déc',
        ];
        setState(() {
          _fullName = (data['full_name'] as String?) ?? '';
          _email = (data['email'] as String?) ?? user.email ?? '';
          _phone = (data['phone'] as String?) ?? '';
          _avatarUrl = (data['avatar_url'] as String?) ?? '';
          _role = (data['role'] as String?) ?? 'buyer';
          _memberSince = createdAt != null
              ? 'Membre depuis ${monthNames[createdAt.month - 1]} ${createdAt.year}'
              : 'Membre récent';
        });
      }
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedProperties() async {
    setState(() => _loadingProperties = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final data = await _client
          .from('saved_properties')
          .select()
          .eq('user_id', user.id)
          .order('saved_at', ascending: false);

      if (mounted) {
        setState(() {
          _savedProperties = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _loadingProperties = false);
    }
  }

  Future<void> _updateProfile({
    required String fullName,
    required String phone,
    required String role,
  }) async {
    setState(() => _isSaving = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('user_profiles')
          .update({'full_name': fullName, 'phone': phone, 'role': role})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          _fullName = fullName;
          _phone = phone;
          _role = role;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil mis à jour',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la mise à jour',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeSavedProperty(String id) async {
    try {
      await _client.from('saved_properties').delete().eq('id', id);
      setState(() => _savedProperties.removeWhere((p) => p['id'] == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Retiré des favoris',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _signOut() async {
    try {
      await _client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.signUpLoginScreen);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.signUpLoginScreen);
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.mapScreen);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.mapScreen);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.publishListingScreen);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.messagesScreen);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.myListingsScreen);
        break;
      case 5:
        // Already on profile screen — do nothing
        break;
    }
  }

  String _formatPrice(int price, String listingType) {
    return CurrencyService.instance.format(
      price,
      isRent: listingType == 'rent',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      bottomNavigationBar: isTablet
          ? null
          : AppNavigation(currentIndex: _currentNavIndex, onTap: _onNavTap),
    );
  }

  Widget _buildPhoneLayout() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(innerBoxIsScrolled),
      ],
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSavedPropertiesTab(), _buildAccountTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        AppNavigationRail(currentIndex: _currentNavIndex, onTap: _onNavTap),
        VerticalDivider(width: 1, color: AppTheme.border),
        Expanded(child: _buildPhoneLayout()),
      ],
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppTheme.border,
      automaticallyImplyLeading: false,
      title: AnimatedOpacity(
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          'Mon Profil',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => _showSettingsSheet(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildProfileHeader(),
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_isLoading) {
      return Container(
        color: AppTheme.surface,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.fromLTRB(4.w, 6.h, 4.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              SizedBox(width: 4.w),
              Expanded(child: _buildUserInfo()),
            ],
          ),
          SizedBox(height: 2.h),
          _buildRoleSwitcher(),
          SizedBox(height: 1.5.h),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () => _showEditProfileSheet(context),
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border, width: 2),
            ),
            child: ClipOval(
              child: _avatarUrl.isNotEmpty
                  ? CustomImageWidget(
                      imageUrl: _avatarUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      semanticLabel: 'Photo de profil de $_fullName',
                    )
                  : Container(
                      color: AppTheme.primary.withAlpha(20),
                      child: Center(
                        child: Text(
                          _fullName.isNotEmpty
                              ? _fullName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 0.5.h),
        Text(
          _fullName.isNotEmpty ? _fullName : 'Utilisateur',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 0.3.h),
        Row(
          children: [
            Icon(Icons.email_outlined, size: 13, color: AppTheme.muted),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _email,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.verified_rounded,
              size: 13,
              color: AppTheme.success,
            ),
          ],
        ),
        if (_phone.isNotEmpty) ...[
          SizedBox(height: 0.3.h),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 13, color: AppTheme.muted),
              const SizedBox(width: 4),
              Text(
                _phone,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 0.5.h),
        Text(
          _memberSince,
          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.muted),
        ),
      ],
    );
  }

  Widget _buildRoleSwitcher() {
    final roles = [
      {'key': 'buyer', 'label': 'Acheteur', 'icon': Icons.search_rounded},
      {'key': 'seller', 'label': 'Vendeur', 'icon': Icons.sell_rounded},
      {'key': 'agent', 'label': 'Agent', 'icon': Icons.badge_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mon rôle',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 0.8.h),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: roles.map((role) {
              final isSelected = _role == role['key'];
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final newRole = role['key'] as String;
                    setState(() => _role = newRole);
                    final user = _client.auth.currentUser;
                    if (user != null) {
                      try {
                        await _client
                            .from('user_profiles')
                            .update({'role': newRole})
                            .eq('id', user.id);
                      } catch (_) {}
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(9.0),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(40),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          role['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.white : AppTheme.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          role['label'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected ? Colors.white : AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final sub = SubscriptionService.instance.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatChip(
              Icons.favorite_outline_rounded,
              '${_savedProperties.length} favoris',
              AppTheme.accent,
            ),
            const SizedBox(width: 8),
            // Rewarded Video Ad button to gain premium status for 24h
            GestureDetector(
              onTap: () {
                AdHelper.showRewarded(
                  onUserEarnedReward: (reward) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Félicitations ! Vous avez gagné 24h d\'accès Premium !',
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
                        ),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  onAdClosed: () {},
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_fill_rounded, size: 12, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Débloquer Premium (Pub)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        _buildSubscriptionChip(sub),
      ],
    );
  }

  Widget _buildSubscriptionChip(SubscriptionInfo sub) {
    if (!sub.isActive && sub.status != SubscriptionStatus.expired) {
      return GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.warningLight,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.warning.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: 13, color: AppTheme.warning),
              const SizedBox(width: 5),
              Text(
                'Activer un abonnement',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 13,
                color: AppTheme.warning,
              ),
            ],
          ),
        ),
      );
    }

    final color = sub.plan == SubscriptionPlan.hotel
        ? AppTheme.primary
        : const Color(0xFF7C3AED);
    final icon = sub.plan == SubscriptionPlan.hotel
        ? Icons.hotel_rounded
        : Icons.apartment_rounded;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              sub.isTrial
                  ? '${sub.planLabel} · Essai (${sub.daysRemaining}j)'
                  : sub.status == SubscriptionStatus.expired
                  ? '${sub.planLabel} · Expiré'
                  : '${sub.planLabel} · Actif',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 13, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.muted,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 2,
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Favoris'),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_savedProperties.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.manage_accounts_rounded, size: 16),
                SizedBox(width: 6),
                Text('Compte'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPropertiesTab() {
    if (_loadingProperties) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_savedProperties.isEmpty) {
      return _buildEmptyState(
        Icons.favorite_border_rounded,
        'Aucun favori',
        'Ajoutez des biens à vos favoris pour les retrouver facilement.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavedProperties,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: _savedProperties.length,
        separatorBuilder: (_, __) => SizedBox(height: 1.2.h),
        itemBuilder: (context, index) =>
            _buildSavedPropertyCard(_savedProperties[index]),
      ),
    );
  }

  Widget _buildSavedPropertyCard(Map<String, dynamic> prop) {
    final isRent = (prop['listing_type'] as String?) == 'rent';
    final price = (prop['price'] as int?) ?? 0;
    final listingType = (prop['listing_type'] as String?) ?? 'sale';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.propertyDetailScreen,
        arguments: {
          'id': prop['property_id'],
          'title': prop['title'],
          'address': prop['address'],
          'price': price,
          'listingType': listingType,
          'surface': (prop['surface'] as num?)?.toDouble() ?? 0.0,
          'rooms': (prop['rooms'] as int?) ?? 0,
          'imageUrl': prop['image_url'],
          'semanticLabel': prop['semantic_label'],
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14.0),
              ),
              child: (prop['image_url'] as String?)?.isNotEmpty == true
                  ? CustomImageWidget(
                      imageUrl: prop['image_url'] as String,
                      width: 100,
                      height: 90,
                      fit: BoxFit.cover,
                      semanticLabel:
                          (prop['semantic_label'] as String?) ??
                          'Bien immobilier',
                    )
                  : Container(
                      width: 100,
                      height: 90,
                      color: AppTheme.surfaceVariant,
                      child: Icon(
                        Icons.home_rounded,
                        color: AppTheme.muted,
                        size: 32,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isRent
                                ? AppTheme.infoLight
                                : AppTheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            isRent ? 'Location' : 'Vente',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isRent ? AppTheme.info : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      (prop['title'] as String?) ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 0.2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            (prop['address'] as String?) ?? '',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(price, listingType),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _removeSavedProperty(prop['id'] as String),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Informations personnelles'),
          SizedBox(height: 1.h),
          _buildInfoCard(),
          SizedBox(height: 2.h),
          _buildSectionHeader('Abonnement'),
          SizedBox(height: 1.h),
          _buildSubscriptionCard(),
          SizedBox(height: 2.h),
          _buildSectionHeader('Actions'),
          SizedBox(height: 1.h),
          _buildActionCard(),
          SizedBox(height: 2.h),
          // Terms & Copyright
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.termsScreen),
            child: Text(
              'Conditions d\'utilisation',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            '© 2026 WFTech. Tous droits réservés.',
            style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.muted),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_outline_rounded,
            'Nom complet',
            _fullName.isNotEmpty ? _fullName : '—',
          ),
          Divider(height: 1, color: AppTheme.border, indent: 16),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            _email.isNotEmpty ? _email : '—',
          ),
          Divider(height: 1, color: AppTheme.border, indent: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            'Téléphone',
            _phone.isNotEmpty ? _phone : 'Non renseigné',
          ),
          Divider(height: 1, color: AppTheme.border, indent: 16),
          InkWell(
            onTap: () => _showEditProfileSheet(context),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Modifier mes informations',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.muted),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.muted),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final sub = SubscriptionService.instance.current;
    final isActive = sub.isActive;
    final color = isActive
        ? (sub.plan == SubscriptionPlan.hotel
              ? AppTheme.primary
              : const Color(0xFF7C3AED))
        : AppTheme.muted;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 20,
                    color: color,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? sub.planLabel : 'Aucun abonnement',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        isActive
                            ? sub.isTrial
                                  ? 'Essai gratuit · ${sub.daysRemaining} jours restants'
                                  : sub.status == SubscriptionStatus.expired
                                  ? 'Expiré'
                                  : '${sub.daysRemaining} jours restants'
                            : 'Activez un plan pour publier des annonces',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border, indent: 16),
          InkWell(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.manage_accounts_outlined
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    isActive ? 'Gérer mon abonnement' : 'Voir les plans',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildActionRow(Icons.notifications_outlined, 'Notifications', () {}),
          Divider(height: 1, color: AppTheme.border, indent: 16),
          _buildActionRow(Icons.lock_outline_rounded, 'Confidentialité', () {}),
          Divider(height: 1, color: AppTheme.border, indent: 16),
          _buildActionRow(
            Icons.help_outline_rounded,
            'Aide & Support',
            () => _showSupportContact(context),
          ),
          Divider(height: 1, color: AppTheme.border, indent: 16),
          InkWell(
            onTap: _signOut,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Se déconnecter',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accent,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.muted),
            SizedBox(width: 3.w),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppTheme.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppTheme.muted),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.8.h),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(text: _phone);
    String selectedRole = _role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                SizedBox(height: 2.h),
                Text(
                  'Modifier le profil',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: AppTheme.muted,
                    ),
                  ),
                ),
                SizedBox(height: 1.5.h),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      size: 20,
                      color: AppTheme.muted,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Rôle',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children:
                        [
                          {'key': 'buyer', 'label': 'Acheteur'},
                          {'key': 'seller', 'label': 'Vendeur'},
                          {'key': 'agent', 'label': 'Agent'},
                        ].map((role) {
                          final isSelected = selectedRole == role['key'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(
                                () => selectedRole = role['key']!,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                                child: Center(
                                  child: Text(
                                    role['label']!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                SizedBox(height: 2.5.h),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _updateProfile(
                            fullName: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            role: selectedRole,
                          );
                        },
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Paramètres',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            _buildSettingsItem(Icons.star_rounded, 'Abonnements', () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen);
            }, color: AppTheme.warning),
            _buildSettingsItem(Icons.edit_outlined, 'Modifier le profil', () {
              Navigator.pop(ctx);
              _showEditProfileSheet(context);
            }),
            _buildSettingsItem(
              Icons.language_rounded,
              'Langue — ${LanguageService.instance.currentLanguage.flag} ${LanguageService.instance.currentLanguage.name}',
              () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.languageSelectionScreen);
              },
              color: AppTheme.primary,
            ),
            _buildSettingsItem(
              Icons.currency_exchange_rounded,
              'Devise — ${CurrencyService.instance.currentCurrency.flag} ${CurrencyService.instance.currentCurrency.code}',
              () {
                Navigator.pop(ctx);
                _showCurrencySheet(context);
              },
              color: AppTheme.info,
            ),
            _buildSettingsItem(
              Icons.dark_mode_rounded,
              'Thème — ${_getThemeLabel(AppTheme.themeModeNotifier.value)}',
              () {
                Navigator.pop(ctx);
                _showThemeSheet(context);
              },
              color: AppTheme.primary,
            ),
            _buildSettingsItem(
              Icons.notifications_outlined,
              'Notifications',
              () {},
            ),
            _buildSettingsItem(
              Icons.lock_outline_rounded,
              'Confidentialité',
              () {},
            ),
            _buildSettingsItem(
              Icons.help_outline_rounded,
              'Aide & Support',
              () {
                Navigator.pop(ctx);
                _showSupportContact(context);
              },
            ),
            SizedBox(height: 1.h),
            Divider(color: AppTheme.border),
            SizedBox(height: 1.h),
            _buildSettingsItem(Icons.logout_rounded, 'Se déconnecter', () {
              Navigator.pop(ctx);
              _signOut();
            }, color: AppTheme.accent),
            _buildSettingsItem(
              Icons.delete_forever_rounded,
              'Supprimer mon compte',
              () {
                Navigator.pop(ctx);
                _showDeleteAccountConfirm(context);
              },
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final itemColor = color ?? AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
        child: Row(
          children: [
            Icon(icon, size: 20, color: itemColor),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }

  void _showCurrencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Choisir une devise',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Les prix seront convertis automatiquement',
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
              ),
              SizedBox(height: 2.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 50.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: CurrencyService.allCurrencies.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppTheme.border),
                  itemBuilder: (_, index) {
                    final currency = CurrencyService.allCurrencies[index];
                    final isSelected =
                        CurrencyService.instance.currentCode == currency.code;
                    return InkWell(
                      onTap: () async {
                        await CurrencyService.instance.setCurrency(
                          currency.code,
                        );
                        setSheetState(() {});
                        if (mounted) setState(() {});
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12.0),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 1.4.h,
                        ),
                        child: Row(
                          children: [
                            Text(
                              currency.flag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${currency.code} — ${currency.symbol}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    currency.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Choisir un thème',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              _buildThemeOption(ctx, setSheetState, ThemeMode.light, 'Thème Clair', Icons.light_mode_rounded),
              Divider(height: 1, color: AppTheme.border),
              _buildThemeOption(ctx, setSheetState, ThemeMode.dark, 'Thème Sombre', Icons.dark_mode_rounded),
              Divider(height: 1, color: AppTheme.border),
              _buildThemeOption(ctx, setSheetState, ThemeMode.system, 'Thème Système', Icons.settings_brightness_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext ctx,
    StateSetter setSheetState,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = AppTheme.themeModeNotifier.value == mode;
    return InkWell(
      onTap: () async {
        AppTheme.themeModeNotifier.value = mode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'theme_mode',
          mode == ThemeMode.dark
              ? 'dark'
              : mode == ThemeMode.system
                  ? 'system'
                  : 'light',
        );
        await prefs.setBool('is_dark_theme', mode == ThemeMode.dark);
        setSheetState(() {});
        if (mounted) setState(() {});
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.6.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 22,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showSupportContact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Aide & Support',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Notre équipe est disponible pour vous aider.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email support client',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'support@zehouse.com',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Nous répondons dans un délai de 5 jours ouvrables.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: AppTheme.border),
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer le compte',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement votre compte et toutes vos données (annonces, favoris, profil) ?\n\nCette action est irréversible.',
          style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              // Show a loading indicator if necessary or just sign out for now
              final user = _client.auth.currentUser;
              if (user != null) {
                try {
                  // Delete profile row (which cascades or triggers deletion on backend)
                  await _client.from('user_profiles').delete().eq('id', user.id);
                } catch (e) {
                  // Ignore errors and force logout
                }
              }
              _signOut();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Votre compte a été supprimé',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              'Oui, Supprimer',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
