import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_service.dart';
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
    'photos': <String>[],
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
    super.dispose();
  }

  /// Returns true if the current user is a professional (has an active subscription).
  bool get _isProfessional {
    final sub = SubscriptionService.instance.current;
    return sub.isActive && sub.plan != SubscriptionPlan.none;
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _stepController.reset();
      setState(() => _currentStep++);
      _stepController.forward();
    } else {
      // Last step: check if payment is needed
      if (_isProfessional) {
        // Professional users publish for free
        _submitListing();
      } else {
        // Non-professional: check free tier limit (10 listings max)
        if (_userListingCount >= SubscriptionService.freeTierMaxListings) {
          _showListingLimitDialog();
          return;
        }
        // Non-professional users must pay $10
        setState(() => _showPaymentGate = true);
      }
    }
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
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 32,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Annonce publiée !',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre annonce est maintenant visible sur la carte et dans les résultats de recherche.',
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
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.myListingsScreen,
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Voir mes annonces',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
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
                                          ? (_isProfessional
                                                ? 'Publier l\'annonce'
                                                : 'Payer & Publier (10\$)')
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
