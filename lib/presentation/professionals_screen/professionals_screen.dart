import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../../routes/app_routes.dart';
import '../../services/itinerary_service.dart';
import '../../services/mapbox_service.dart';

class ProfessionalsScreen extends StatefulWidget {
  const ProfessionalsScreen({super.key});

  @override
  State<ProfessionalsScreen> createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  Position? _userPosition;
  bool _isLocating = false;
  String _locationError = '';
  String _selectedCategory = 'Tous';
  Map<String, dynamic>? _selectedPro;
  bool _showMapView = false;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final List<String> _categories = [
    'Tous',
    'Plombier',
    'Électricien',
    'Maçon',
    'Architecte',
    'Peintre',
    'Menuisier',
    'Carreleur',
    'Couvreur',
    'Serrurier',
    'Chauffagiste',
    'Décorateur',
    'Soudeur Alu',
    'Soudeur Méca',
    'Charpentier',
    'Ferrailleur',
    'Ingénieur',
  ];

  final List<Map<String, dynamic>> _professionals = [];
  bool _loadingPros = false;

  Future<void> _loadProfessionals() async {
    if (_loadingPros) return;
    setState(() {
      _loadingPros = true;
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
          'company': 'Artisan Indépendant',
          'address': p['address'] ?? 'À proximité',
          'phone': p['phone'] ?? '',
          'rating': 4.5,
          'reviews': 0,
          'isAvailable': true,
          'experience': 'Professionnel vérifié',
          'lat': lat,
          'lng': lng,
          'workZoneRadius': 25,
          'imageUrl': p['avatar_url'] ?? '',
          'icon': Icons.construction_rounded,
          'color': AppTheme.primary,
          'services': [p['profession'] ?? 'Artisanat'],
          'certifications': ['Vérifié'],
          'priceRange': 'Sur devis',
          'isSponsored': false,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _professionals.clear();
          _professionals.addAll(loaded);
          _loadingPros = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading professionals: $e');
      if (mounted) {
        setState(() {
          _loadingPros = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPros {
    List<Map<String, dynamic>> list;
    if (_selectedCategory == 'Tous') {
      list = List<Map<String, dynamic>>.from(_professionals);
    } else {
      list = _professionals
          .where((p) => p['category'] == _selectedCategory)
          .toList();
    }
    // Sort: sponsored first, then by distance if available
    list.sort((a, b) {
      final aSponsored = (a['isSponsored'] as bool?) ?? false;
      final bSponsored = (b['isSponsored'] as bool?) ?? false;
      if (aSponsored && !bSponsored) return -1;
      if (!aSponsored && bSponsored) return 1;
      if (_userPosition != null) {
        final dA = _calcDistance(
          (a['lat'] as num).toDouble(),
          (a['lng'] as num).toDouble(),
        );
        final dB = _calcDistance(
          (b['lat'] as num).toDouble(),
          (b['lng'] as num).toDouble(),
        );
        return dA.compareTo(dB);
      }
      return 0;
    });
    return list;
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
    _loadProfessionals();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _detectLocation();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = '';
    });
    try {
      // isLocationServiceEnabled() is not supported on Flutter Web —
      // the browser Geolocation API handles service availability internally.
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _locationError = 'Services de localisation désactivés.';
            _isLocating = false;
          });
          return;
        }
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permission de localisation refusée.';
            _isLocating = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permission de localisation refusée définitivement.';
          _isLocating = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _userPosition = position;
        _isLocating = false;
      });
      _loadProfessionals();
    } catch (e) {
      setState(() {
        _locationError = 'Impossible de détecter votre position.';
        _isLocating = false;
      });
    }
  }

  double _calcDistance(double lat, double lng) {
    if (_userPosition == null) return 0;
    const R = 6371.0;
    final dLat = (lat - _userPosition!.latitude) * math.pi / 180;
    final dLng = (lng - _userPosition!.longitude) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_userPosition!.latitude * math.pi / 180) *
            math.cos(lat * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  void _selectPro(Map<String, dynamic> pro) {
    setState(() => _selectedPro = pro);
    _slideController.forward();
  }

  void _closePro() {
    _slideController.reverse().then((_) {
      setState(() => _selectedPro = null);
    });
  }

  void _handleNavTap(int index) {
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
    final isTablet = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      children: [
        _buildHeader(),
        _buildCategoryBar(),
        _buildViewToggle(),
        Expanded(
          child: Stack(
            children: [
              _showMapView ? _buildMapView() : _buildListView(),
              if (_selectedPro != null) _buildProDetailSheet(),
            ],
          ),
        ),
        AppNavigation(currentIndex: _currentNavIndex, onTap: _handleNavTap),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        AppNavigationRail(currentIndex: _currentNavIndex, onTap: _handleNavTap),
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              _buildCategoryBar(),
              _buildViewToggle(),
              Expanded(
                child: Stack(
                  children: [
                    _showMapView ? _buildMapView() : _buildListView(),
                    if (_selectedPro != null) _buildProDetailSheet(),
                  ],
                ),
              ),
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
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Professionnels du Bâtiment',
                  style: GoogleFonts.dmSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _isLocating ? _pulseAnimation.value : 1.0,
                        child: Icon(
                          _isLocating
                              ? Icons.location_searching_rounded
                              : _userPosition != null
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          size: 12,
                          color: _isLocating
                              ? AppTheme.warning
                              : _userPosition != null
                              ? AppTheme.success
                              : AppTheme.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLocating
                          ? 'Localisation en cours...'
                          : _userPosition != null
                          ? '${_filteredPros.length} professionnels trouvés'
                          : _locationError.isNotEmpty
                          ? _locationError
                          : 'Position non détectée',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _detectLocation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
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
                  cat,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
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

  Widget _buildViewToggle() {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8),
      child: Row(
        children: [
          if (_userPosition != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.near_me_rounded,
                  size: 13,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Triés par proximité',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            )
          else
            Text(
              '${_filteredPros.length} résultats',
              style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                _ToggleBtn(
                  icon: Icons.view_list_rounded,
                  label: 'Liste',
                  isActive: !_showMapView,
                  onTap: () => setState(() => _showMapView = false),
                ),
                _ToggleBtn(
                  icon: Icons.map_rounded,
                  label: 'Carte',
                  isActive: _showMapView,
                  onTap: () => setState(() => _showMapView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_loadingPros) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
        ),
      );
    }
    final pros = _filteredPros;
    if (pros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 48, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(
              'Aucun professionnel trouvé\npour cette catégorie',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14.sp,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12),
      itemCount: pros.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ProCard(
        pro: pros[index],
        distance: _calcDistance(
          (pros[index]['lat'] as num).toDouble(),
          (pros[index]['lng'] as num).toDouble(),
        ),
        hasLocation: _userPosition != null,
        onTap: () => _selectPro(pros[index]),
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Simulated map background
        Container(
          color: const Color(0xFFE8EDF5),
          child: CustomPaint(
            painter: _MapGridPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        // Zone circles and pins
        ..._filteredPros.map((pro) => _buildProPin(pro)),
        // User location
        if (_userPosition != null)
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(80),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Map hint
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Appuyez sur un professionnel pour voir sa zone',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondary,
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

  Widget _buildProPin(Map<String, dynamic> pro) {
    final color = pro['color'] as Color;
    final isSelected = _selectedPro?['id'] == pro['id'];
    // Map lat/lng to screen position (simplified projection)
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height * 0.55;
    final centerLat = 48.8566;
    final centerLng = 2.3522;
    final scale = 800.0;
    final x = screenW / 2 + ((pro['lng'] as num) - centerLng) * scale;
    final y = screenH / 2 - ((pro['lat'] as num) - centerLat) * scale;

    return Positioned(
      left: x - 20,
      top: y - 20,
      child: GestureDetector(
        onTap: () => _selectPro(pro),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Work zone circle
            if (isSelected)
              Container(
                width: (pro['workZoneRadius'] as num) * 3.0,
                height: (pro['workZoneRadius'] as num) * 3.0,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(80), width: 1.5),
                ),
              ),
            // Pin
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color : AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isSelected ? 0 : 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                pro['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProDetailSheet() {
    final pro = _selectedPro!;
    final color = pro['color'] as Color;
    final distance = _calcDistance(
      (pro['lat'] as num).toDouble(),
      (pro['lng'] as num).toDouble(),
    );
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 200) {
              _closePro();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 8, 4.w, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: Icon(
                              pro['icon'] as IconData,
                              color: color,
                              size: 26,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pro['name'] as String,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 15.sp,
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
                                        color: (pro['isAvailable'] as bool)
                                            ? AppTheme.successLight
                                            : AppTheme.errorLight,
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Text(
                                        (pro['isAvailable'] as bool)
                                            ? 'Disponible'
                                            : 'Occupé',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: (pro['isAvailable'] as bool)
                                              ? AppTheme.success
                                              : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${pro['category']} • ${pro['company']}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12.sp,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _closePro,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats row
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.star_rounded,
                            label: '${pro['rating']} (${pro['reviews']} avis)',
                            color: const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          if (_userPosition != null)
                            _StatChip(
                              icon: Icons.near_me_rounded,
                              label: distance < 1
                                  ? '${(distance * 1000).round()} m'
                                  : '${distance.toStringAsFixed(1)} km',
                              color: AppTheme.primary,
                            ),
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: Icons.work_history_rounded,
                            label: pro['experience'] as String,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Zone de travail
                      Row(
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Zone de travail : ${pro['workZoneRadius']} km autour de ${(pro['address'] as String).split(',').last.trim()}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.euro_rounded,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tarif : ${pro['priceRange']}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Services
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (pro['services'] as List<String>)
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: color.withAlpha(60),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.phone_rounded,
                              label: 'Appeler',
                              color: AppTheme.success,
                              onTap: () => _showContactSnackbar(
                                'Appel vers ${pro['phone']}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.chat_bubble_rounded,
                              label: 'Message',
                              color: AppTheme.primary,
                              onTap: () => _showContactSnackbar(
                                'Message envoyé à ${pro['name']}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionBtn(
                              icon: Icons.directions_rounded,
                              label: 'Itinéraire',
                              color: AppTheme.accent,
                              onTap: () => ItineraryService.openDirections(
                                destLat: pro['lat'] as double?,
                                destLng: pro['lng'] as double?,
                                address: pro['address'] as String?,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Rate professional button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRateProDialog(pro),
                          icon: const Icon(
                            Icons.star_outline_rounded,
                            size: 18,
                          ),
                          label: Text(
                            'Évaluer ce professionnel',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF59E0B),
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContactSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.dmSans()),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRateProDialog(Map<String, dynamic> pro) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (pro['color'] as Color).withAlpha(20),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      pro['icon'] as IconData,
                      color: pro['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Évaluer ${pro['name']}',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${pro['category']} • ${pro['company']}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Star selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          i < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          key: ValueKey('$i-${i < selectedRating}'),
                          size: 40,
                          color: i < selectedRating
                              ? const Color(0xFFF59E0B)
                              : AppTheme.border,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _ratingLabel(selectedRating),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 300,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Décrivez votre expérience (optionnel)...',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.muted,
                  ),
                  counterStyle: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.muted,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final user =
                              Supabase.instance.client.auth.currentUser;
                          if (user == null) {
                            Navigator.pop(ctx);
                            _showContactSnackbar(
                              'Connectez-vous pour laisser un avis',
                            );
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            await Supabase.instance.client
                                .from('professional_reviews')
                                .upsert({
                                  'professional_id': pro['id'] as String,
                                  'reviewer_id': user.id,
                                  'rating': selectedRating,
                                  'comment':
                                      commentController.text.trim().isEmpty
                                      ? null
                                      : commentController.text.trim(),
                                }, onConflict: 'professional_id,reviewer_id');
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Votre avis a été publié !',
                                    style: GoogleFonts.dmSans(fontSize: 13),
                                  ),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            setModalState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Publier mon avis',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}

// ─── Pro Card ────────────────────────────────────────────────────────────────

class _ProCard extends StatelessWidget {
  final Map<String, dynamic> pro;
  final double distance;
  final bool hasLocation;
  final VoidCallback onTap;

  const _ProCard({
    required this.pro,
    required this.distance,
    required this.hasLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = pro['color'] as Color;
    final isSponsored = (pro['isSponsored'] as bool?) ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSponsored ? const Color(0xFFF97316) : AppTheme.border,
            width: isSponsored ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Icon(pro['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isSponsored) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
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
                                  size: 9,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Sponsorisé',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            pro['name'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 14.sp,
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
                            color: (pro['isAvailable'] as bool)
                                ? AppTheme.successLight
                                : AppTheme.errorLight,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            (pro['isAvailable'] as bool)
                                ? 'Disponible'
                                : 'Occupé',
                            style: GoogleFonts.dmSans(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: (pro['isAvailable'] as bool)
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pro['category']} • ${pro['company']}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${pro['rating']}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          ' (${pro['reviews']})',
                          style: GoogleFonts.dmSans(
                            fontSize: 11.sp,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.radar_rounded,
                          size: 13,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Zone: ${pro['workZoneRadius']} km',
                          style: GoogleFonts.dmSans(
                            fontSize: 11.sp,
                            color: AppTheme.muted,
                          ),
                        ),
                        if (hasLocation) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(18),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: AppTheme.primary.withAlpha(70),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  size: 11,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  distance < 1
                                      ? '${(distance * 1000).round()} m'
                                      : '${distance.toStringAsFixed(1)} km',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Map Grid Painter ─────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D9E6)
      ..strokeWidth = 0.8;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Draw some road-like lines
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
