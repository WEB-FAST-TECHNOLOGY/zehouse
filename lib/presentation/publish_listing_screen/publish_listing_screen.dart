import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:confetti/confetti.dart';
import '../../services/ad_helper.dart';
import 'dart:io';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../services/currency_service.dart';
import './widgets/publish_step1_widget.dart';
import './widgets/publish_step2_widget.dart';
import './widgets/publish_step3_widget.dart';
import './widgets/publish_step_indicator_widget.dart';
import './widgets/listing_payment_gate_widget.dart';

class PublishListingScreen extends StatefulWidget {
  const PublishListingScreen({super.key});

  @override
  State<PublishListingScreen> createState() => _PublishListingScreenState();
}

class _PublishListingScreenState extends State<PublishListingScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showPaymentGate = false;
  int _userListingCount = 0;
  
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  late AnimationController _stepController;
  late Animation<Offset> _slideAnimation;

  final Map<String, dynamic> _formData = {
    'listingType': 'sale',
    'propertyType': 'appartement',
    'title': '',
    'price': '',
    'surface': '',
    'rooms': '3',
    'bedrooms': '2',
    'floor': '0',
    'energyClass': 'C',
    'description': '',
    'photos': <XFile>[],
    'video': null, // XFile?
    'address': '',
    'city': '',
    'zipCode': '',
  };

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _stepController, curve: Curves.easeOutCubic),
        );
    _stepController.forward();
    _loadUserListingCount();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  Future<void> _loadUserListingCount() async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await SupabaseService.instance.client
          .from('user_listings')
          .select('id')
          .eq('user_id', user.id);
      if (mounted) {
        setState(() => _userListingCount = (data as List).length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stepController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 2) {
      _stepController.reset();
      setState(() => _currentStep++);
      _stepController.forward();
    } else {
      // Validate phone number before proceeding
      setState(() => _isLoading = true);
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final profile = await SupabaseService.instance.client
              .from('user_profiles')
              .select('phone')
              .eq('id', user.id)
              .single();
          if (profile['phone'] == null || profile['phone'].toString().trim().isEmpty) {
            setState(() => _isLoading = false);
            _showPhoneRequiredDialog();
            return;
          }
        } catch (_) {}
      }
      setState(() => _isLoading = false);

      // Last step: check if payment is needed
      final sub = SubscriptionService.instance.current;
      if (sub.canPublishWithoutFee(_userListingCount)) {
        // Can publish for free without paying $10 (subscription or trial active, and within quota)
        _submitListing();
      } else {
        // Limit reached or no active subscription/trial -> Show $10 payment gate
        setState(() => _showPaymentGate = true);
      }
    }
  }

  void _showPhoneRequiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Numéro requis', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Vous devez ajouter un numéro de téléphone à votre profil pour que les intéressés puissent vous contacter.',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profileScreen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Mettre à jour', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _prevStep() {
    if (_showPaymentGate) {
      setState(() => _showPaymentGate = false);
      return;
    }
    if (_currentStep > 0) {
      _stepController.reset();
      setState(() => _currentStep--);
      _stepController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitListing() async {
    setState(() {
      _showPaymentGate = false;
    });

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      final shouldWatchAd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Soutenir l\'application',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Pour publier cette annonce gratuitement, vous allez visionner une courte vidéo publicitaire.\n\nVous pouvez également passer à un abonnement premium pour ne plus avoir de publicités !',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.pushNamed(context, AppRoutes.subscriptionPlansScreen);
              },
              child: Text(
                'Voir les abonnements',
                style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Regarder la vidéo',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (shouldWatchAd == true) {
        bool userEarnedReward = false;
        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _isRewardedAdLoaded = false;
            if (userEarnedReward) {
              setState(() => _isLoading = true);
              _performSubmitListing();
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vous devez visionner la vidéo jusqu\'à la fin pour publier.', style: GoogleFonts.outfit()),
                    backgroundColor: AppTheme.warning,
                  ),
                );
              }
            }
            // Reload ad for next time
            _loadRewardedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _isRewardedAdLoaded = false;
            setState(() => _isLoading = true);
            _performSubmitListing(); // fallback
            _loadRewardedAd();
          },
        );
        try {
          _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
            userEarnedReward = true;
          });
        } catch (e) {
          debugPrint('Error showing rewarded ad: $e');
          setState(() => _isLoading = true);
          _performSubmitListing();
        }
      }
    } else {
      setState(() => _isLoading = true);
      _performSubmitListing();
    }
  }

  Future<void> _performSubmitListing() async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) throw Exception('Non connecté');

      final photos = _formData['photos'] as List<XFile>;
      final video = _formData['video'] as XFile?;
      
      String mainImageUrl = '';
      List<String> imageUrls = [];
      String videoUrl = '';
      final uuid = const Uuid().v4();

      // Upload all photos
      if (photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          final ext = photos[i].path.split('.').last;
          final path = '${user.id}/$uuid/photo_$i.$ext';
          await SupabaseService.instance.client.storage
              .from('listings_media')
              .upload(path, File(photos[i].path));
          final url = SupabaseService.instance.client.storage
              .from('listings_media')
              .getPublicUrl(path);
          imageUrls.add(url);
          if (i == 0) mainImageUrl = url; // fallback for older clients
        }
      }

      // Upload video if present
      if (video != null) {
        final ext = video.path.split('.').last;
        final path = '${user.id}/$uuid/video.$ext';
        await SupabaseService.instance.client.storage
            .from('listings_media')
            .upload(path, File(video.path));
        videoUrl = SupabaseService.instance.client.storage
            .from('listings_media')
            .getPublicUrl(path);
      }

      // Insert into database
      await SupabaseService.instance.client.from('user_listings').insert({
        'user_id': user.id,
        'title': _formData['title'],
        'description': _formData['description'],
        'price': ((int.tryParse(_formData['price']) ?? 0) / CurrencyService.instance.currentCurrency.rateFromEur).round(),
        'surface': double.tryParse(_formData['surface']) ?? 0.0,
        'rooms': int.tryParse(_formData['rooms']) ?? 1,
        'listing_type': _formData['listingType'],
        'property_type': _formData['propertyType'],
        'address': _formData['address'],
        'image_url': mainImageUrl,
        'image_urls': imageUrls, // new column required
        'video_url': videoUrl,
        'is_active': true,
        // Optional: generate random coordinates for demo
        'lat': 48.8566 + (DateTime.now().millisecond % 100) / 10000,
        'lng': 2.3522 + (DateTime.now().millisecond % 100) / 10000,
      });

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la publication : $e', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _FuturisticSuccessDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack).value,
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );
  }

  void _showListingLimitDialog() {
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
                Icons.lock_outline_rounded,
                size: 32,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Limite atteinte',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez atteint la limite de ${SubscriptionService.freeTierMaxListings} annonces gratuites. Abonnez-vous pour publier des annonces illimitées.',
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

  static const List<String> _stepTitles = [
    'Informations',
    'Photos & Description',
    'Localisation',
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: _prevStep,
        ),
        title: Text(
          _showPaymentGate ? 'Paiement requis' : 'Publier une annonce',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _showPaymentGate
          ? ListingPaymentGateWidget(
              onPaymentSuccess: _submitListing,
              onCancel: () => setState(() => _showPaymentGate = false),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Step indicator
                  Container(
                    color: AppTheme.surface,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: PublishStepIndicatorWidget(
                      currentStep: _currentStep,
                      stepTitles: _stepTitles,
                    ),
                  ),

                  // Step content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _stepController,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 40 : 20,
                            vertical: 20,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: _buildCurrentStep(isTablet),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom navigation
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _prevStep,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  foregroundColor: AppTheme.primary,
                                  side: BorderSide(
                                    color: AppTheme.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Retour',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _nextStep,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                backgroundColor: _currentStep == 2
                                    ? AppTheme.accent
                                    : AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _currentStep == 2
                                          ? 'Publier'
                                          : 'Continuer',
                                      style: GoogleFonts.outfit(
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
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStep(bool isTablet) {
    switch (_currentStep) {
      case 0:
        return PublishStep1Widget(
          formData: _formData,
          isTablet: isTablet,
          onChanged: (key, value) => setState(() => _formData[key] = value),
        );
      case 1:
        return PublishStep2Widget(
          formData: _formData,
          onChanged: (key, value) => setState(() => _formData[key] = value),
        );
      case 2:
        return PublishStep3Widget(
          formData: _formData,
          onChanged: (key, value) => setState(() => _formData[key] = value),
        );
      default:
        return const SizedBox();
    }
  }
}

class _FuturisticSuccessDialog extends StatefulWidget {
  const _FuturisticSuccessDialog();

  @override
  State<_FuturisticSuccessDialog> createState() => _FuturisticSuccessDialogState();
}

class _FuturisticSuccessDialogState extends State<_FuturisticSuccessDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.rocket_launch_rounded, size: 40, color: AppTheme.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'Félicitations !',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre annonce est désormais en ligne et prête à être découverte.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.myListingsScreen, (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Voir mes annonces',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -50,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // point downwards
              maxBlastForce: 20,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}
