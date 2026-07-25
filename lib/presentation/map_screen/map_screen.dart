import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/mapbox_service.dart';
import './widgets/add_listing_modal_widget.dart';
import './widgets/map_advanced_filter_widget.dart';
import './widgets/map_filter_chips_widget.dart';
import './widgets/map_property_bottom_sheet_widget.dart';
import './widgets/map_search_bar_widget.dart';
import './widgets/map_view_widget.dart';
import './widgets/map_search_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // TODO: Replace with Riverpod for production
  int _currentNavIndex = 0;
  int _selectedPropertyIndex = -1;
  late AnimationController _bottomSheetController;
  late Animation<Offset> _bottomSheetAnimation;

  // User listings from Supabase
  List<Map<String, dynamic>> _userListings = [];

  bool _mockPropertiesOffset = false;

  // Route calculation state
  Map<String, double>? _userLocation;
  Map<String, dynamic>? _routeInfo;
  bool _loadingRoute = false;

  // Simulated user location (Paris center — replaced by GPS in production)
  static const Map<String, double> _simulatedUserLocation = {
    'lat': MapboxService.defaultLat,
    'lng': MapboxService.defaultLng,
  };

  bool _zenMode = false;

  // Search & advanced filter state
  String _searchQuery = '';
  MapFilterState _advancedFilter = const MapFilterState();

  final List<Map<String, dynamic>> _propertyMaps = [];

  List<Map<String, dynamic>> _filteredProperties = [];
  String _activeFilter = 'Tous';

  // AdMob BannerAd
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }



  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    
    final double? uLat = MapboxService.userLat;
    final double? uLng = MapboxService.userLng;
    if (uLat != null && uLng != null) {
      _userLocation = {'lat': uLat, 'lng': uLng};
      _offsetMockProperties(uLat, uLng);
      _mockPropertiesOffset = true;
    } else {
      _userLocation = _simulatedUserLocation;
    }

    _filteredProperties = List.from(_propertyMaps);
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bottomSheetAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _bottomSheetController,
            curve: Curves.easeOutCubic,
          ),
        );
    _bottomSheetController.forward();
    _loadUserListings();
    
    // Start listening to real-time location
    LocationService.instance.startLocationStream();
    LocationService.instance.locationStream.listen((position) {
      if (mounted) {
        setState(() {
          _userLocation = {
            'lat': position.latitude,
            'lng': position.longitude,
          };
          
          if (!_mockPropertiesOffset) {
            _offsetMockProperties(position.latitude, position.longitude);
            _mockPropertiesOffset = true;
          }
          
          // Re-apply filters based on new location (Around Me)
          _applyAllFilters();
        });
      }
    });
  }

  void _offsetMockProperties(double userLat, double userLng) {
    const double centerLat = 48.8566;
    const double centerLng = 2.3522;

    for (var p in _propertyMaps) {
      final double lat = (p['lat'] as num).toDouble();
      final double lng = (p['lng'] as num).toDouble();

      final double diffLat = lat - centerLat;
      final double diffLng = lng - centerLng;

      p['lat'] = userLat + diffLat;
      p['lng'] = userLng + diffLng;
    }
  }

  Future<void> _refreshLocation() async {
    await LocationService.instance.startLocationStream();
  }

  // GPS est maintenant géré par LocationService en temps réel

  Future<void> _loadUserListings() async {
    try {
      final response = await Supabase.instance.client
          .from('user_listings')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final listings = (response as List).map((item) {
        return {
          'id': 'ul_${item['id']}',
          'title': item['title'] ?? '',
          'address': item['address'] ?? '',
          'price': item['price'] ?? 0,
          'pricePerM2':
              (item['surface'] != null && (item['surface'] as double) > 0)
              ? ((item['price'] as int) / (item['surface'] as double)).round()
              : 0,
          'surface': (item['surface'] as num?)?.toDouble() ?? 0.0,
          'rooms': item['rooms'] ?? 1,
          'type': item['property_type'] ?? 'Appartement',
          'listingType': item['listing_type'] ?? 'sale',
          'daysOnMarket': 0,
          'imageUrl': item['image_url'] ?? '',
          'semanticLabel': 'Annonce utilisateur: ${item['title']}',
          'lat': (item['lat'] as num?)?.toDouble() ?? 48.8566,
          'lng': (item['lng'] as num?)?.toDouble() ?? 2.3522,
          'isNew': true,
          'isFavorite': false,
          'isUserListing': true,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _userListings = listings;
        });
        _onFilterChanged(_activeFilter);
      }
    } catch (e) {
      // Ignore
    }
  }

  List<Map<String, dynamic>> get _allProperties => [
    ..._propertyMaps,
    ..._userListings,
  ];

  /// Calculate route from user location to the selected property using Mapbox Directions API
  Future<void> _calculateRoute(Map<String, dynamic> property) async {
    final userLoc = _userLocation;
    if (userLoc == null) return;

    final destLat = (property['lat'] as num?)?.toDouble();
    final destLng = (property['lng'] as num?)?.toDouble();
    if (destLat == null || destLng == null) return;

    setState(() {
      _loadingRoute = true;
      _routeInfo = null;
    });

    try {
      final url = MapboxService.buildDirectionsUrl(
        originLat: userLoc['lat']!,
        originLng: userLoc['lng']!,
        destLat: destLat,
        destLng: destLng,
        profile: 'driving',
      );

      final dio = Dio();
      final response = await dio.get(url);
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data as Map<String, dynamic>;

      final routes = data['routes'] as List?;
      if (routes != null && routes.isNotEmpty) {
        final route = routes[0] as Map<String, dynamic>;
        final distanceM = (route['distance'] as num).toDouble();
        final durationS = (route['duration'] as num).toDouble();

        // Format distance
        String distanceLabel;
        if (distanceM >= 1000) {
          distanceLabel = '${(distanceM / 1000).toStringAsFixed(1)} km';
        } else {
          distanceLabel = '${distanceM.round()} m';
        }

        // Format duration
        String durationLabel;
        final minutes = (durationS / 60).round();
        if (minutes >= 60) {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          durationLabel = mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
        } else {
          durationLabel = '$minutes min';
        }

        if (mounted) {
          setState(() {
            _routeInfo = {
              'distance': distanceLabel,
              'duration': durationLabel,
              'distanceM': distanceM,
              'durationS': durationS,
            };
            _loadingRoute = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingRoute = false);
      }
    } catch (e) {
      debugPrint('Route calculation error: $e');
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bottomSheetController.dispose();
    LocationService.instance.stopLocationStream();
    super.dispose();
  }

  void _onFilterChanged(String filter) {
    // TODO: Replace with Riverpod for production
    setState(() {
      _activeFilter = filter;
      _applyAllFilters();
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyAllFilters();
    });
  }

  void _onAdvancedFilterApply(MapFilterState filter) {
    setState(() {
      _advancedFilter = filter;
      _applyAllFilters();
    });
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  void _applyAllFilters() {
    final all = _allProperties;
    List<Map<String, dynamic>> result = List.from(all);

    // Apply "Around Me" filter
    if (_advancedFilter.onlyAroundMe && _userLocation != null) {
      final userLat = _userLocation!['lat']!;
      final userLng = _userLocation!['lng']!;
      result = result.where((p) {
        final pLat = (p['lat'] as num?)?.toDouble();
        final pLng = (p['lng'] as num?)?.toDouble();
        if (pLat == null || pLng == null) return false;
        final dist = _calculateDistance(userLat, userLng, pLat, pLng);
        return dist <= 25.0; // 25 km radius
      }).toList();
    }

    // Apply chip filter (listing type / property type)
    if (_activeFilter == 'Acheter') {
      result = result.where((p) => p['listingType'] == 'sale').toList();
    } else if (_activeFilter == 'Louer') {
      result = result.where((p) => p['listingType'] == 'rent').toList();
    } else if (_activeFilter != 'Tous') {
      result = result.where((p) => p['type'] == _activeFilter).toList();
    }

    // Apply advanced filters
    result = result.where((p) => _advancedFilter.matchesProperty(p)).toList();

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        final title = (p['title'] as String).toLowerCase();
        final address = (p['address'] as String).toLowerCase();
        final type = (p['type'] as String).toLowerCase();
        return title.contains(q) || address.contains(q) || type.contains(q);
      }).toList();
    }

    // Sort: sponsored first, then by date
    result.sort((a, b) {
      final aSponsored = (a['isSponsored'] as bool?) ?? false;
      final bSponsored = (b['isSponsored'] as bool?) ?? false;
      if (aSponsored && !bSponsored) return -1;
      if (!aSponsored && bSponsored) return 1;
      return 0;
    });

    _filteredProperties = result;
  }

  void _onPropertySelected(int index) {
    // TODO: Replace with Riverpod for production
    setState(() {
      _selectedPropertyIndex = index;
      _routeInfo = null;
    });
    if (index >= 0 && index < _filteredProperties.length) {
      _calculateRoute(_filteredProperties[index]);
    }
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => MapAdvancedFilterWidget(
          currentFilter: _advancedFilter,
          onApply: _onAdvancedFilterApply,
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      // Already on map screen — just ensure index is reset
      setState(() => _currentNavIndex = 0);
      return;
    }
    if (index == 1) {
      // Search: scroll to top / focus search bar
      setState(() => _currentNavIndex = 1);
      return;
    }

    setState(() => _currentNavIndex = index);

    switch (index) {
      case 2:
        Navigator.pushNamed(context, AppRoutes.publishListingScreen).then((_) {
          if (mounted) setState(() => _currentNavIndex = 0);
        });
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.messagesScreen).then((_) {
          if (mounted) setState(() => _currentNavIndex = 0);
        });
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.myListingsScreen).then((_) {
          if (mounted) setState(() => _currentNavIndex = 0);
        });
        break;
      case 5:
        Navigator.pushNamed(context, AppRoutes.profileScreen).then((_) {
          if (mounted) setState(() => _currentNavIndex = 0);
        });
        break;
    }
  }

  void _showAddListingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddListingModalWidget(
          onListingAdded: () {
            _loadUserListings();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Annonce publiée et visible sur la carte !',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
                ),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      extendBody: true,
      body: _currentNavIndex == 1
          ? MapSearchView(
              properties: _filteredProperties,
              searchQuery: _searchQuery,
              activeFilter: _activeFilter,
              hasActiveFilters: !_advancedFilter.isDefault,
              onSearch: _onSearch,
              onFilterChanged: _onFilterChanged,
              onBackToMap: () {
                setState(() {
                  _currentNavIndex = 0;
                });
              },
              onLocateOnMap: (property) {
                // Switch back to Map tab (index 0)
                setState(() {
                  _currentNavIndex = 0;
                  _advancedFilter = _advancedFilter.copyWith(onlyAroundMe: false);
                  _applyAllFilters();
                });
                // Find index of this property in filtered list
                final idx = _filteredProperties.indexWhere((p) => p['id'] == property['id']);
                if (idx >= 0) {
                  _onPropertySelected(idx);
                }
              },
              onPropertyTap: (property) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.propertyDetailScreen,
                  arguments: property,
                );
              },
              onShowAdvancedFilters: _showAdvancedFilters,
            )
          : (isTablet ? _buildTabletLayout() : _buildPhoneLayout()),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Stack(
      children: [
        // Full-screen map — fills entire screen behind all overlays
        Positioned.fill(
          child: MapViewWidget(
            properties: _filteredProperties,
            selectedIndex: _selectedPropertyIndex,
            onPropertyTap: _onPropertySelected,
            userLocation: _userLocation,
            routeInfo: _routeInfo,
            onMyLocationTap: _refreshLocation,
          ),
        ),

        // Floating Zen Mode toggle button on the right
        Positioned(
          bottom: 372,
          right: 16,
          child: _CompactFab(
            icon: _zenMode ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: _zenMode ? AppTheme.accent : AppTheme.primary,
            tooltip: _zenMode ? 'Afficher les contrôles' : 'Mode Zen',
            onTap: () {
              setState(() {
                _zenMode = !_zenMode;
              });
            },
          ),
        ),

        if (!_zenMode) ...[
          // Top gradient scrim so controls are readable over the map
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(55), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Top overlay: search bar + filter chips
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MapSearchBarWidget(
                      onSearch: _onSearch,
                      onFilterTap: _showAdvancedFilters,
                      hasActiveFilters: !_advancedFilter.isDefault,
                      onTap: () {
                        setState(() {
                          _currentNavIndex = 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  MapFilterChipsWidget(
                    activeFilter: _activeFilter,
                    onFilterChanged: _onFilterChanged,
                  ),
                  // AdMob BannerAd integration below chips
                  if (_isBannerAdLoaded && _bannerAd != null)
                    Container(
                      alignment: Alignment.center,
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  if (_searchQuery.isNotEmpty || !_advancedFilter.isDefault)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 16),
                      child: _ResultsCountBadge(
                        count: _filteredProperties.length,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom sheet property list with frosted background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _bottomSheetAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IgnorePointer(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(80),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  MapPropertyBottomSheetWidget(
                    properties: _filteredProperties,
                    selectedIndex: _selectedPropertyIndex,
                    onPropertySelected: _onPropertySelected,
                    onPropertyTap: (property) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.propertyDetailScreen,
                        arguments: property,
                      );
                    },
                    onRefresh: _loadUserListings,
                  ),
                ],
              ),
            ),
          ),

          // Left-side compact icon FABs — rendered ABOVE the bottom sheet
          Positioned(
            left: 14,
            bottom: 295,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompactFab(
                  icon: Icons.near_me_rounded,
                  color: AppTheme.accent,
                  tooltip: 'Services proches',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.nearbyServicesScreen,
                  ),
                ),
                const SizedBox(height: 10),
                _CompactFab(
                  icon: Icons.construction_rounded,
                  color: const Color(0xFF16A34A),
                  tooltip: 'Professionnels',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.professionalsScreen),
                ),
                const SizedBox(height: 10),
                _CompactFab(
                  icon: Icons.add_location_alt_rounded,
                  color: const Color(0xFFE85D4A),
                  tooltip: 'Publier',
                  onTap: _showAddListingModal,
                ),
              ],
            ),
          ),

          // Route info banner — shown above bottom sheet when route is ready
          if (_loadingRoute || _routeInfo != null)
            Positioned(
              bottom: 256,
              left: 16,
              right: 16,
              child: _RouteInfoBanner(
                routeInfo: _routeInfo,
                isLoading: _loadingRoute,
                onClose: () => setState(() {
                  _routeInfo = null;
                  _selectedPropertyIndex = -1;
                }),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        if (!_zenMode) ...[
          // Left: property list panel
          SizedBox(
            width: 360,
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MapSearchBarWidget(
                      onSearch: _onSearch,
                      onFilterTap: _showAdvancedFilters,
                      hasActiveFilters: !_advancedFilter.isDefault,
                      onTap: () {
                        setState(() {
                          _currentNavIndex = 1;
                        });
                      },
                    ),
                  ),
                ),
                MapFilterChipsWidget(
                  activeFilter: _activeFilter,
                  onFilterChanged: _onFilterChanged,
                ),
                // Results count
                if (_searchQuery.isNotEmpty || !_advancedFilter.isDefault)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _ResultsCountBadge(
                        count: _filteredProperties.length,
                      ),
                    ),
                  ),
                // Nearby services button for tablet
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _TabletActionButton(
                    icon: Icons.near_me_rounded,
                    color: AppTheme.accent,
                    label: 'Services à proximité',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.nearbyServicesScreen,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _TabletActionButton(
                    icon: Icons.construction_rounded,
                    color: const Color(0xFF16A34A),
                    label: 'Professionnels Bâtiment',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.professionalsScreen,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _TabletActionButton(
                    icon: Icons.add_location_alt_rounded,
                    color: const Color(0xFFE85D4A),
                    label: 'Publier une annonce',
                    onTap: _showAddListingModal,
                  ),
                ),
                Expanded(
                  child: MapPropertyBottomSheetWidget(
                    properties: _filteredProperties,
                    selectedIndex: _selectedPropertyIndex,
                    onPropertySelected: _onPropertySelected,
                    onPropertyTap: (property) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.propertyDetailScreen,
                        arguments: property,
                      );
                    },
                    isTabletPanel: true,
                    onRefresh: _loadUserListings,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: const Color(0xFFE5E7EB)),
        ],
        // Right: map
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: MapViewWidget(
                  properties: _filteredProperties,
                  selectedIndex: _selectedPropertyIndex,
                  onPropertyTap: _onPropertySelected,
                  userLocation: _userLocation,
                  routeInfo: _routeInfo,
                  onMyLocationTap: _refreshLocation,
                ),
              ),
              // Floating Zen Mode toggle button on tablet (right side)
              Positioned(
                bottom: 372,
                right: 16,
                child: _CompactFab(
                  icon: _zenMode ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: _zenMode ? AppTheme.accent : AppTheme.primary,
                  tooltip: _zenMode ? 'Afficher les contrôles' : 'Mode Zen',
                  onTap: () {
                    setState(() {
                      _zenMode = !_zenMode;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultsCountBadge extends StatelessWidget {
  final int count;
  const _ResultsCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count résultat${count != 1 ? 's' : ''}',
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Banner displayed above the bottom sheet showing route distance and duration
class _RouteInfoBanner extends StatelessWidget {
  final Map<String, dynamic>? routeInfo;
  final bool isLoading;
  final VoidCallback onClose;

  const _RouteInfoBanner({
    required this.routeInfo,
    required this.isLoading,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Calcul de l\'itinéraire...',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        routeInfo?['duration'] as String? ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        routeInfo?['distance'] as String? ?? '',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Compact circular icon FAB used on the phone map layout
class _CompactFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _CompactFab({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surface.withAlpha(220),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withAlpha(120),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width labeled button used in the tablet side panel
class _TabletActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _TabletActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
