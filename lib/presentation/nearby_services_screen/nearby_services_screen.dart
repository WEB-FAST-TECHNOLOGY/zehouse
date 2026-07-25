import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/itinerary_service.dart';
import '../../services/mapbox_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import './nearby_services_map_widget.dart';

class NearbyServicesScreen extends StatefulWidget {
  const NearbyServicesScreen({super.key});

  @override
  State<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends State<NearbyServicesScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  Position? _userPosition;
  bool _isLocating = false;
  String _locationError = '';
  String _selectedFilter = 'Tous';
  Map<String, dynamic>? _selectedService;
  bool _showRoute = false;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _professionals = [];
  bool _isLoadingPros = false;

  Future<void> _loadRealProfessionals() async {
    if (_isLoadingPros) return;
    setState(() {
      _isLoadingPros = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('role', 'professional');

      final loaded = (response as List).map((p) {
        final double lat = (p['lat'] as num?)?.toDouble() ?? (MapboxService.userLat ?? 48.8566);
        final double lng = (p['lng'] as num?)?.toDouble() ?? (MapboxService.userLng ?? 2.3522);
        
        return {
          'id': p['id'].toString(),
          'name': p['full_name'] ?? 'Artisan',
          'category': p['profession'] ?? 'Plombier',
          'lat': lat,
          'lng': lng,
          'icon': Icons.construction_rounded,
          'color': AppTheme.primary,
          'isAvailable': true,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _professionals.clear();
          _professionals.addAll(loaded);
          _isLoadingPros = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading real pros in services screen: $e');
      if (mounted) {
        setState(() {
          _isLoadingPros = false;
        });
      }
    }
  }

  final List<String> _filters = [
    'Tous',
    'Agence',
    'Appartement',
    'Maison',
    'Bureau',
    'Hôtel',
    'Déménagement',
    'Entretien',
  ];

  final List<Map<String, dynamic>> _allServices = [];
  bool _isLoadingServices = false;

  Future<void> _loadRealServices() async {
    if (_isLoadingServices) return;
    setState(() {
      _isLoadingServices = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('user_listings')
          .select()
          .eq('is_active', true);

      final loaded = (response as List).map((item) {
        final double lat = (item['lat'] as num?)?.toDouble() ?? 48.8566;
        final double lng = (item['lng'] as num?)?.toDouble() ?? 2.3522;
        
        return {
          'id': 'ul_${item['id']}',
          'name': item['title'] ?? '',
          'type': item['property_type'] ?? 'Appartement',
          'address': item['address'] ?? '',
          'phone': '',
          'rating': 4.5,
          'reviews': 0,
          'isOpen': true,
          'openHours': '9h–18h',
          'lat': lat,
          'lng': lng,
          'imageUrl': item['image_url'] ?? '',
          'semanticLabel': item['title'] ?? '',
          'icon': Icons.home_work_rounded,
          'color': AppTheme.primary,
          'services': [item['property_type'] ?? 'Immobilier'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allServices.clear();
          _allServices.addAll(loaded);
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading real services: $e');
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_selectedFilter == 'Tous') return _allServices;
    return _allServices.where((s) => s['type'] == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    final double? uLat = MapboxService.userLat;
    final double? uLng = MapboxService.userLng;
    if (uLat != null && uLng != null) {
      _userPosition = Position(
        latitude: uLat,
        longitude: uLng,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
    _loadRealServices();
    _loadRealProfessionals();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _detectLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = '';
    });
    try {
      if (kIsWeb) {
        // On web, geolocator uses the browser Geolocation API — no service-enabled check needed
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          setState(() {
            _locationError =
                'Permission de localisation refusée. Activez-la dans les paramètres du navigateur.';
            _isLocating = false;
          });
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _userPosition = pos;
          _isLocating = false;
        });
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _locationError = 'Services de localisation désactivés.';
            _isLocating = false;
          });
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          setState(() {
            _locationError =
                'Permission de localisation refusée. Activez-la dans les paramètres.';
            _isLocating = false;
          });
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _userPosition = pos;
          _isLocating = false;
        });
        _loadRealServices();
        _loadRealProfessionals();
      }
    } catch (_) {
      setState(() {
        _locationError = 'Impossible d\'obtenir votre position.';
        _isLocating = false;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  List<Map<String, dynamic>> _sortedByDistance() {
    final services = List<Map<String, dynamic>>.from(_filteredServices);
    if (_userPosition != null) {
      services.sort((a, b) {
        final da = _calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          a['lat'] as double,
          a['lng'] as double,
        );
        final db = _calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          b['lat'] as double,
          b['lng'] as double,
        );
        return da.compareTo(db);
      });
    }
    return services;
  }

  void _selectService(Map<String, dynamic> service) {
    setState(() {
      _selectedService = service;
      _showRoute = false;
    });
    _slideController.forward(from: 0);
  }

  void _closeDetail() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _selectedService = null;
          _showRoute = false;
        });
      }
    });
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
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
        Navigator.pushNamed(context, AppRoutes.myListingsScreen);
        break;
      case 5:
        Navigator.pushNamed(context, AppRoutes.profileScreen);
        break;
    }
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
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(child: _buildContent()),
          ],
        ),
        if (_selectedService != null) _buildDetailOverlay(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        AppNavigationRail(currentIndex: _currentNavIndex, onTap: _onNavTap),
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  _buildFilterBar(),
                  Expanded(child: _buildContent()),
                ],
              ),
              if (_selectedService != null) _buildDetailOverlay(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4.w,
        right: 4.w,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Services à Proximité',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                _buildLocationStatus(),
              ],
            ),
          ),
          GestureDetector(
            onTap: _detectLocation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _userPosition != null
                    ? AppTheme.primary.withAlpha(20)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _userPosition != null
                      ? AppTheme.primary.withAlpha(60)
                      : AppTheme.border,
                ),
              ),
              child: _isLocating
                  ? Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: _userPosition != null
                          ? AppTheme.primary
                          : AppTheme.muted,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_isLocating) {
      return Text(
        'Détection de votre position…',
        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
        overflow: TextOverflow.ellipsis,
      );
    }
    if (_locationError.isNotEmpty) {
      return Text(
        _locationError,
        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.error),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    if (_userPosition != null) {
      return Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Position détectée · ${_sortedByDistance().length} services',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return Text(
      'Appuyez sur 📍 pour détecter votre position',
      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.muted),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = _filters[i];
            final isSelected = _selectedFilter == f;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingServices) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
        ),
      );
    }
    final services = _sortedByDistance();
    return _buildMapAndList(services);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Détection de votre position GPS…',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 36,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Localisation impossible',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _locationError,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _detectLocation,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.muted),
          const SizedBox(height: 12),
          Text(
            'Aucun service trouvé',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Essayez un autre filtre',
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMapAndList(List<Map<String, dynamic>> services) {
    return Column(
      children: [
        // Map always visible
        SizedBox(
          height: 28.h > 280 ? 280 : 28.h,
          child: NearbyServicesMapWidget(
            services: services.isEmpty ? _allServices : services,
            professionals: _professionals,
            selectedService: _selectedService,
            onServiceTap: _selectService,
            userLocationAvailable: _userPosition != null,
          ),
        ),
        // Content below map
        Expanded(
          child: _isLocating
              ? _buildLoadingState()
              : (_locationError.isNotEmpty && _userPosition == null)
              ? _buildErrorState()
              : services.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(4.w, 12, 4.w, 16),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = services[i];
                    final dist = _userPosition != null
                        ? _calculateDistance(
                            _userPosition!.latitude,
                            _userPosition!.longitude,
                            s['lat'] as double,
                            s['lng'] as double,
                          )
                        : null;
                    return _ServiceCard(
                      service: s,
                      distance: dist,
                      formatDistance: _formatDistance,
                      isSelected: _selectedService?['id'] == s['id'],
                      onTap: () => _selectService(s),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailOverlay() {
    final s = _selectedService!;
    final color = s['color'] as Color;
    final isOpen = s['isOpen'] as bool;
    final dist = _userPosition != null
        ? _calculateDistance(
            _userPosition!.latitude,
            _userPosition!.longitude,
            s['lat'] as double,
            s['lng'] as double,
          )
        : null;
    final duration = dist != null ? (dist * 3).ceil().clamp(1, 999) : null;

    return Stack(
      children: [
        // Scrim
        GestureDetector(
          onTap: _closeDetail,
          child: Container(color: Colors.black.withAlpha(60)),
        ),
        // Bottom sheet
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  // Image header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: Image.network(
                          s['imageUrl'] as String,
                          fit: BoxFit.cover,
                          semanticLabel: s['semanticLabel'] as String,
                          errorBuilder: (_, __, ___) => Container(
                            color: color.withAlpha(30),
                            child: Icon(
                              s['icon'] as IconData,
                              size: 48,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s['name'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppTheme.successLight
                                    : AppTheme.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOpen
                                    ? 'Ouvert · ${s['openHours']}'
                                    : 'Fermé · ${s['openHours']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isOpen
                                      ? AppTheme.success
                                      : AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Type + rating
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s['type'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${s['rating']} (${s['reviews']} avis)',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Address
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
                                s['address'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Phone
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 14,
                              color: AppTheme.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s['phone'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Services chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: (s['services'] as List<String>)
                              .map(
                                (sv) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    sv,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        // Distance info
                        if (dist != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary.withAlpha(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDistance(dist),
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'Environ $duration min en voiture',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Route display
                        if (_showRoute && dist != null) ...[
                          const SizedBox(height: 12),
                          _ItineraryWidget(
                            service: s,
                            distance: dist,
                            duration: duration ?? 0,
                            formatDistance: _formatDistance,
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _closeDetail,
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Fermer'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    setState(() => _showRoute = !_showRoute),
                                icon: Icon(
                                  _showRoute
                                      ? Icons.map_rounded
                                      : Icons.directions_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  _showRoute
                                      ? 'Masquer l\'itinéraire'
                                      : 'Voir l\'itinéraire',
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  backgroundColor: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Open in Mapbox button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => ItineraryService.openDirections(
                              destLat: s['lat'] as double?,
                              destLng: s['lng'] as double?,
                              address: s['address'] as String?,
                            ),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: const Text('Ouvrir dans Mapbox'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Nearby Map View ─────────────────────────────────────────────────────────

class _NearbyMapView extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> professionals;
  final Position? userPosition;
  final Map<String, dynamic>? selectedService;
  final Function(Map<String, dynamic>) onServiceTap;

  const _NearbyMapView({
    required this.services,
    required this.professionals,
    required this.userPosition,
    required this.selectedService,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFE8EFF6)),
        Positioned.fill(
          child: Image.network(
            'https://images.pexels.com/photos/2190283/pexels-photo-2190283.jpeg',
            fit: BoxFit.cover,
            color: Colors.white.withAlpha(51),
            colorBlendMode: BlendMode.srcOver,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFFECF0F5)),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha(20),
                  Colors.transparent,
                  Colors.black.withAlpha(10),
                ],
              ),
            ),
          ),
        ),
        // Service pins
        ...List.generate(services.length > 8 ? 8 : services.length, (i) {
          final s = services[i];
          final isSelected = selectedService?['id'] == s['id'];
          const positions = [
            Offset(0.20, 0.30),
            Offset(0.55, 0.25),
            Offset(0.75, 0.45),
            Offset(0.35, 0.60),
            Offset(0.65, 0.65),
            Offset(0.15, 0.65),
            Offset(0.50, 0.50),
            Offset(0.80, 0.25),
          ];
          final pos = i < positions.length
              ? positions[i]
              : Offset(0.3 + i * 0.07, 0.4);

          return LayoutBuilder(
            builder: (context, constraints) => Positioned(
              left: constraints.maxWidth * pos.dx - 20,
              top: constraints.maxHeight * pos.dy - 20,
              child: GestureDetector(
                onTap: () => onServiceTap(s),
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: _ServicePin(
                    icon: s['icon'] as IconData,
                    color: s['color'] as Color,
                    isSelected: isSelected,
                    label: s['type'] as String,
                  ),
                ),
              ),
            ),
          );
        }),
        // Professional pins
        ...List.generate(professionals.length > 8 ? 8 : professionals.length, (
          i,
        ) {
          final pro = professionals[i];
          const proPositions = [
            Offset(0.30, 0.20),
            Offset(0.68, 0.35),
            Offset(0.12, 0.45),
            Offset(0.45, 0.72),
            Offset(0.82, 0.58),
            Offset(0.25, 0.80),
            Offset(0.60, 0.15),
            Offset(0.88, 0.75),
          ];
          final pos = i < proPositions.length
              ? proPositions[i]
              : Offset(0.2 + i * 0.08, 0.55);
          final isAvailable = (pro['isAvailable'] as bool?) ?? true;

          return LayoutBuilder(
            builder: (context, constraints) => Positioned(
              left: constraints.maxWidth * pos.dx - 16,
              top: constraints.maxHeight * pos.dy - 16,
              child: Tooltip(
                message: '${pro['name']} · ${pro['category']}',
                child: _ProfessionalPin(
                  icon: pro['icon'] as IconData,
                  color: pro['color'] as Color,
                  isAvailable: isAvailable,
                  label: pro['category'] as String,
                ),
              ),
            ),
          );
        }),
        // User dot
        if (userPosition != null)
          Positioned(
            left: MediaQuery.of(context).size.width * 0.48 - 12,
            top: 70,
            child: _UserLocationDot(),
          ),
        // Map label
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 12,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Vue carte · ${services.length} services · ${professionals.length} pros',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServicePin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final String label;

  const _ServicePin({
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSelected ? 44 : 36,
          height: isSelected ? 44 : 36,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isSelected ? 0 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(isSelected ? 100 : 60),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: isSelected ? 22 : 18,
            color: isSelected ? Colors.white : color,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Professional Pin ─────────────────────────────────────────────────────────

class _ProfessionalPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final String label;

  const _ProfessionalPin({
    required this.icon,
    required this.color,
    required this.isAvailable,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isAvailable ? AppTheme.success : AppTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final double? distance;
  final String Function(double) formatDistance;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.distance,
    required this.formatDistance,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = service['color'] as Color;
    final isOpen = service['isOpen'] as bool;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Image.network(
                  service['imageUrl'] as String,
                  fit: BoxFit.cover,
                  semanticLabel: service['semanticLabel'] as String,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withAlpha(30),
                    child: Icon(
                      service['icon'] as IconData,
                      size: 32,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service['name'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? AppTheme.successLight
                                : AppTheme.errorLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOpen ? 'Ouvert' : 'Fermé',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isOpen ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            service['type'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${service['rating']} (${service['reviews']})',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['address'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            formatDistance(distance!),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.directions_car_rounded,
                            size: 12,
                            color: AppTheme.muted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '~${(distance! * 3).ceil().clamp(1, 999)} min',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isSelected ? color : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Itinerary Widget ─────────────────────────────────────────────────────────

class _ItineraryWidget extends StatelessWidget {
  final Map<String, dynamic> service;
  final double distance;
  final int duration;
  final String Function(double) formatDistance;

  const _ItineraryWidget({
    required this.service,
    required this.distance,
    required this.duration,
    required this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    final color = service['color'] as Color;
    final steps = _generateSteps();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'Itinéraire',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${formatDistance(distance)} · $duration min',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Route steps
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isLast ? color : AppTheme.primary.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLast
                              ? color
                              : AppTheme.primary.withAlpha(60),
                        ),
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        size: 14,
                        color: isLast ? Colors.white : AppTheme.primary,
                      ),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 28, color: AppTheme.border),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['instruction'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (step['detail'] != null)
                          Text(
                            step['detail'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppTheme.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          // Transport options
          Row(
            children: [
              _TransportChip(
                icon: Icons.directions_car_rounded,
                label: '$duration min',
                isSelected: true,
                color: color,
              ),
              const SizedBox(width: 8),
              _TransportChip(
                icon: Icons.directions_walk_rounded,
                label: '${(distance * 15).ceil()} min',
                isSelected: false,
                color: color,
              ),
              const SizedBox(width: 8),
              _TransportChip(
                icon: Icons.directions_transit_rounded,
                label: '${(duration * 1.3).ceil()} min',
                isSelected: false,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateSteps() {
    final address = service['address'] as String;
    return [
      {
        'icon': Icons.my_location_rounded,
        'instruction': 'Votre position actuelle',
        'detail': 'Point de départ',
      },
      {
        'icon': Icons.turn_right_rounded,
        'instruction': 'Prenez la direction nord',
        'detail': 'Continuez sur 500 m',
      },
      {
        'icon': Icons.turn_left_rounded,
        'instruction': 'Tournez à gauche',
        'detail': 'Sur la rue principale',
      },
      {
        'icon': Icons.location_on_rounded,
        'instruction': address,
        'detail': null,
      },
    ];
  }
}

class _TransportChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;

  const _TransportChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? color.withAlpha(20) : AppTheme.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isSelected ? color.withAlpha(60) : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isSelected ? color : AppTheme.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? color : AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}
