import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';
import '../../env.dart';

import '../../theme/app_theme.dart';
import '../../services/subscription_service.dart';
import '../../services/cinetpay_web.dart'
    if (dart.library.io) '../../services/cinetpay_io.dart';
import '../../services/moneroo_web.dart'
    if (dart.library.io) '../../services/moneroo_io.dart';
import '../../services/currency_service.dart';
import 'subscription_success_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen>
    with SingleTickerProviderStateMixin {
  final _subscriptionService = SubscriptionService.instance;
  bool _isLoading = false;
  late TabController _tabController;
  bool _wantSponsored = false;
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;

  static final String _cinetpayApiKey = Env.cinetpayApiKey;
  static final String _cinetpayApiPassword = Env.cinetpayApiPassword;
  static final String _cinetpaySiteId = Env.cinetpaySiteId;
  static const String _notifyUrl =
      'https://zehouse2471.builtwithrocket.new/cinetpay/notify';

  static final String _monerooApiKey = Env.monerooApiKey;

  final List<Map<String, dynamic>> _plans = [
    {
      'plan': SubscriptionPlan.plus,
      'title': 'ZEHOUSE Plus+',
      'originalPriceMonthly': 5,
      'priceMonthly': 3,
      'originalPriceYearly': 60,
      'priceYearly': 25,
      'currency': 'USD',
      'icon': Icons.add_circle_outline_rounded,
      'color': const Color(0xFF0EA5E9), // Neon blue
      'description': 'L\'essentiel pour démarrer sans frais par annonce.',
      'features': [
        'Jusqu\'à 30 annonces gratuites',
        'Zéro frais de publication',
        'Badge Profil "Plus+ Vérifié"',
        'Messagerie et contacts directs',
        'Zéro Publicités internes et externes',
      ],
    },
    {
      'plan': SubscriptionPlan.pro,
      'title': 'ZEHOUSE Pro',
      'originalPriceMonthly': 15,
      'priceMonthly': 9,
      'originalPriceYearly': 180,
      'priceYearly': 89,
      'currency': 'USD',
      'icon': Icons.domain_rounded,
      'color': const Color(0xFF8B5CF6), // Neon purple
      'description': 'Pour les professionnels actifs et agents immobiliers.',
      'features': [
        'Jusqu\'à 100 annonces gratuites',
        'Zéro frais de publication',
        'Recherche prioritaire (vos annonces remontent)',
        'Badge Profil "PRO"',
        'Apparition dans l\'Annuaire des Pros',
        'Statistiques avancées',
        'Zéro Publicités internes et externes',
      ],
    },
    {
      'plan': SubscriptionPlan.ultra,
      'title': 'ZEHOUSE Ultra',
      'originalPriceMonthly': 30,
      'priceMonthly': 19,
      'originalPriceYearly': 360,
      'priceYearly': 189,
      'currency': 'USD',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFFF59E0B), // Neon gold
      'description': 'Visibilité maximale et annonces illimitées.',
      'features': [
        'Annonces illimitées sans aucun frais',
        'Top Priorité absolue dans les résultats',
        'Badge VIP "Ultra Gold"',
        'Portfolio Pro avec appel direct',
        'Statistiques complètes et détaillées',
        'Zéro Publicités internes et externes',
      ],
    },
  ];

  void _onSubscriptionUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _subscriptionService.addListener(_onSubscriptionUpdated);
  }

  @override
  void dispose() {
    _subscriptionService.removeListener(_onSubscriptionUpdated);
    super.dispose();
  }

  void _startPayment(Map<String, dynamic> planData, {bool isTrial = false}) async {
    if (isTrial) {
      final plan = planData['plan'] as SubscriptionPlan;
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1)); // UX delay
      await _subscriptionService.activateTrial(plan, sponsored: _wantSponsored);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubscriptionSuccessScreen(planData: planData),
          ),
        );
      }
      return;
    }
    _showPaymentProviderDialog(planData, isTrial: isTrial);
  }

  void _showPaymentProviderDialog(Map<String, dynamic> planData, {bool isTrial = false}) {
    final color = planData['color'] as Color;
    final title = planData['title'] as String;
    final isMonthly = _selectedBillingCycle == BillingCycle.monthly;
    final baseAmount = isTrial ? 0 : (isMonthly ? planData['priceMonthly'] as int : planData['priceYearly'] as int);
    final sponsoredExtra = (!isTrial && _wantSponsored) ? (isMonthly ? 3 : 30) : 0;
    final totalAmount = baseAmount + sponsoredExtra;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
            Text(
              'Choisissez votre moyen de paiement',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildProviderTile(
              icon: Icons.payment_rounded,
              providerName: 'Accéder au paiement CinetPay',
              subtitle: 'Mobile Money, Orange Money, Wave...',
              color: const Color(0xFF0066CC),
              onTap: () {
                Navigator.pop(context);
                _startCinetPayPayment(planData, totalAmount, isTrial: isTrial);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile({
    required IconData icon,
    required String providerName,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _startCinetPayPayment(Map<String, dynamic> planData, int baseAmountUsd, {bool isTrial = false}) {
    final plan = planData['plan'] as SubscriptionPlan;
    final title = planData['title'] as String;
    
    // CinetPay compte Cameroun → toujours XAF
    const String cinetpayCurrency = 'XAF';
    
    // Convertir USD en XAF (1 USD ≈ 600 XAF)
    final int amountInLocalCurrency = baseAmountUsd * 600;

    final transactionId = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 20);

    _printYellowLog(
      'INITIATING CINETPAY PAYMENT\n'
      'Plan: $title (Trial: $isTrial)\n'
      'Amount: $amountInLocalCurrency $cinetpayCurrency\n'
      'Site ID: $_cinetpaySiteId\n'
      'API Key: ${_cinetpayApiKey.isEmpty ? 'MISSING' : 'PROVIDED'}\n'
      'Transaction ID: $transactionId',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinetPayCheckoutWidget(
          title: 'Abonnement $title',
          configData: {
            'apikey': _cinetpayApiKey,
            'api_password': _cinetpayApiPassword,
            'site_id': _cinetpaySiteId,
            'notify_url': _notifyUrl,
          },
          paymentData: {
            'transaction_id': transactionId,
            'amount': amountInLocalCurrency,
            'currency': cinetpayCurrency,
            'channels': 'ALL',
            'description': 'Abonnement $title - ZEHOUSE',
          },
          waitResponse: (response) {
            Navigator.pop(context);
            _handlePaymentResponse(response, planData, transactionId, _selectedBillingCycle, isTrial: isTrial);
          },
          onError: (error) {
            Navigator.pop(context);
            _handlePaymentError(error);
          },
        ),
      ),
    );
  }

  void _startMonerooPayment(Map<String, dynamic> planData, int amount) {
    final plan = planData['plan'] as SubscriptionPlan;
    final title = planData['title'] as String;
    final transactionId = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 20);

    _printYellowLog(
      'INITIATING MONEROO PAYMENT\n'
      'Plan: $title\n'
      'Amount: $amount XOF\n'
      'API Key: ${_monerooApiKey.isEmpty ? 'MISSING' : 'PROVIDED'}\n'
      'Transaction ID: $transactionId',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonerooCheckoutWidget(
          title: 'Abonnement $title',
          amount: amount,
          currency: 'XOF',
          description: 'Abonnement $title - ZEHOUSE',
          apiKey: _monerooApiKey.isEmpty
              ? 'YOUR_MONEROO_API_KEY'
              : _monerooApiKey,
          customerEmail: 'client@zehouse.com',
          customerFirstName: 'Client',
          customerLastName: 'ZEHOUSE',
          onPaymentCompleted: (success) {
            Navigator.pop(context);
            if (success) {
              _subscriptionService
                  .activatePaidSubscription(
                    plan,
                    transactionId,
                    _selectedBillingCycle,
                    sponsored: _wantSponsored,
                  )
                  .then((_) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubscriptionSuccessScreen(planData: planData),
                        ),
                      );
                    }
                  });
            } else {
              _showErrorDialog(
                'Paiement refusé',
                'Votre paiement a été refusé. Veuillez réessayer ou choisir un autre moyen de paiement.',
              );
            }
          },
          onError: (error) {
            Navigator.pop(context);
            _showErrorDialog('Erreur de paiement', error);
          },
        ),
      ),
    );
  }

  void _printYellowLog(String message) {
    debugPrint('\x1B[33m========================================\x1B[0m');
    debugPrint('\x1B[33m🚀 ZEHOUSE PAYMENT LOG:\x1B[0m');
    debugPrint('\x1B[33m$message\x1B[0m');
    debugPrint('\x1B[33m========================================\x1B[0m');
  }

  void _handlePaymentResponse(
    Map<String, dynamic> response,
    Map<String, dynamic> planData,
    String transactionId,
    BillingCycle billingCycle, {
    bool isTrial = false,
  }) async {
    final status = response['status'] as String? ?? '';
    if (status == 'ACCEPTED') {
      if (isTrial) {
        await _subscriptionService.activateTrial(
          planData['plan'] as SubscriptionPlan,
          sponsored: _wantSponsored,
        );
      } else {
        await _subscriptionService.activatePaidSubscription(
          planData['plan'] as SubscriptionPlan,
          transactionId,
          billingCycle,
          sponsored: _wantSponsored,
        );
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubscriptionSuccessScreen(planData: planData),
          ),
        );
      }
    } else {
      if (mounted) {
        _showErrorDialog(
          'Paiement refusé',
          'Votre paiement a été refusé. Veuillez réessayer ou choisir un autre moyen de paiement.',
        );
      }
    }
  }

  void _handlePaymentError(Map<String, dynamic> error) {
    final message = error['message'] as String? ?? 'Une erreur est survenue';
    _showErrorDialog('Erreur de paiement', message);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_rounded,
                color: AppTheme.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subscriptionService.current;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Abonnements',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: _buildPlanList(_plans, sub),
    );
  }

  Widget _buildPlanList(
    List<Map<String, dynamic>> plans,
    SubscriptionInfo sub,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current subscription status
          if (sub.isActive) _buildCurrentSubscriptionBanner(sub),
          if (sub.isActive) SizedBox(height: 2.h),

          // Header
          Text(
            'Choisissez votre plan',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '30 jours d\'essai gratuit inclus avec chaque plan',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 2.h),

          // Trial badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppTheme.success.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎁 30 premiers jours offerts — sans engagement, sans carte bancaire',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 1.5.h),

          // Billing Cycle Toggle
          _buildBillingCycleToggle(),

          SizedBox(height: 1.5.h),

          // Sponsored option
          _buildSponsoredToggle(),

          SizedBox(height: 2.h),

          // Plan cards
          ...plans.map((plan) => _buildPlanCard(plan, sub)),

          SizedBox(height: 2.h),

          // Cancel subscription
          if (sub.isActive)
            Center(
              child: TextButton(
                onPressed: () => _showCancelConfirmation(),
                child: Text(
                  'Annuler mon abonnement',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.error,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildBillingCycleToggle() {
    final isMonthly = _selectedBillingCycle == BillingCycle.monthly;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedBillingCycle = BillingCycle.monthly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isMonthly ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isMonthly
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  'Mensuel',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: isMonthly ? FontWeight.w700 : FontWeight.w500,
                    color: isMonthly ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedBillingCycle = BillingCycle.yearly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isMonthly ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isMonthly
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withAlpha(50),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Annuel',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: !isMonthly ? FontWeight.w700 : FontWeight.w500,
                        color: !isMonthly ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: !isMonthly ? Colors.white.withAlpha(40) : AppTheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-20%',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: !isMonthly ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wantSponsored ? const Color(0xFFFFF7ED) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: _wantSponsored ? const Color(0xFFF97316) : AppTheme.border,
          width: _wantSponsored ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withAlpha(20),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFF97316),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Annonces Sponsorisées',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '+30\$/an',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Apparaissez en tête de liste et sur la carte avec le badge "Sponsorisé"',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _wantSponsored,
            onChanged: (v) => setState(() => _wantSponsored = v),
            activeThumbColor: const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionBanner(SubscriptionInfo sub) {
    Color color;
    IconData icon;
    
    switch (sub.plan) {
      case SubscriptionPlan.plus:
        color = const Color(0xFF0ea5e9);
        icon = Icons.verified_rounded;
        break;
      case SubscriptionPlan.pro:
        color = const Color(0xFF8b5cf6);
        icon = Icons.domain_rounded;
        break;
      case SubscriptionPlan.ultra:
        color = const Color(0xFFf59e0b);
        icon = Icons.workspace_premium_rounded;
        break;
      default:
        color = AppTheme.primary;
        icon = Icons.star_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ${sub.planLabel} — ${sub.statusLabel}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  sub.isTrial
                      ? '${sub.daysRemaining} jours d\'essai restants'
                      : '${sub.daysRemaining} jours restants',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (sub.sponsoredListings)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFF97316),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sponsoring actif',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFFF97316),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sub.isTrial
                  ? AppTheme.warningLight
                  : AppTheme.successLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              sub.isTrial ? 'Essai' : 'Actif',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sub.isTrial ? AppTheme.warning : AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> planData, SubscriptionInfo sub) {
    final plan = planData['plan'] as SubscriptionPlan;
    final color = planData['color'] as Color;
    final features = planData['features'] as List<String>;
    final isCurrentPlan = sub.plan == plan && sub.isActive;
    final isExpired =
        sub.plan == plan && sub.status == SubscriptionStatus.expired;

    final isMonthly = _selectedBillingCycle == BillingCycle.monthly;
    final currentPrice = isMonthly ? planData['priceMonthly'] : planData['priceYearly'];
    final originalPrice = isMonthly ? planData['originalPriceMonthly'] : planData['originalPriceYearly'];
    final periodLabel = isMonthly ? 'mois' : 'an';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surface.withAlpha(240),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isCurrentPlan ? color : color.withAlpha(50),
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          if (isCurrentPlan)
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 32,
              spreadRadius: 8,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withAlpha(12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Icon(
                    planData['icon'] as IconData,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planData['title'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        planData['description'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyService.instance.format(currentPrice),
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: color,
                        shadows: [
                          Shadow(
                            color: color.withAlpha(100),
                            blurRadius: 16,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (originalPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          CurrencyService.instance.format(originalPrice),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/ $periodLabel',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '30j offerts',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),

                if (_wantSponsored) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFF97316),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMonthly
                            ? 'Sponsoring inclus ${CurrencyService.instance.format(3)}/mois'
                            : 'Sponsoring inclus ${CurrencyService.instance.format(30)}/an',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFFF97316),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Features
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // CTA buttons
                if (isCurrentPlan && sub.isTrial)
                  _buildPayButton(planData, color)
                else if (isCurrentPlan && !sub.isTrial)
                  _buildActiveButton(color)
                else if (isExpired)
                  _buildRenewButton(planData, color)
                else if (!sub.isActive)
                  _buildTrialAndPayButtons(planData, color)
                else
                  _buildSwitchButton(planData, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialAndPayButtons(Map<String, dynamic> planData, Color color) {
    final isMonthly = _selectedBillingCycle == BillingCycle.monthly;
    final basePrice = (isMonthly ? planData['priceMonthly'] : planData['priceYearly']) as int;
    final totalPrice = basePrice + (_wantSponsored ? (isMonthly ? 3 : 30) : 0);
    final period = isMonthly ? 'mois' : 'an';
    final hasUsedTrial = _subscriptionService.current.hasUsedTrial;

    if (hasUsedTrial) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _startPayment(planData),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: Text(
            'Payer maintenant — ${CurrencyService.instance.format(totalPrice)}/$period',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _startPayment(planData, isTrial: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Commencer l\'essai gratuit (30j)',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _startPayment(planData),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              'Payer maintenant — ${CurrencyService.instance.format(totalPrice)}/$period',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(Map<String, dynamic> planData, Color color) {
    final isMonthly = _selectedBillingCycle == BillingCycle.monthly;
    final basePrice = (isMonthly ? planData['priceMonthly'] : planData['priceYearly']) as int;
    final totalPrice = basePrice + (_wantSponsored ? (isMonthly ? 3 : 30) : 0);
    final period = isMonthly ? 'mois' : 'an';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startPayment(planData),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Text(
          'Activer — ${CurrencyService.instance.format(totalPrice)}/$period',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildActiveButton(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Plan actif',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewButton(Map<String, dynamic> planData, Color color) {
    final isMonthly = _selectedBillingCycle == BillingCycle.monthly;
    final basePrice = (isMonthly ? planData['priceMonthly'] : planData['priceYearly']) as int;
    final totalPrice = basePrice + (_wantSponsored ? (isMonthly ? 3 : 30) : 0);
    final period = isMonthly ? 'mois' : 'an';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startPayment(planData),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.warning,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Text(
          'Renouveler — ${CurrencyService.instance.format(totalPrice)}/$period',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSwitchButton(Map<String, dynamic> planData, Color color) {
    final isMonthly = _selectedBillingCycle == BillingCycle.monthly;
    final basePrice = (isMonthly ? planData['priceMonthly'] : planData['priceYearly']) as int;
    final totalPrice = basePrice + (_wantSponsored ? (isMonthly ? 3 : 30) : 0);
    final period = isMonthly ? 'mois' : 'an';
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _startPayment(planData),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Text(
          'Changer de plan — ${CurrencyService.instance.format(totalPrice)}/$period',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Annuler l\'abonnement',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir annuler votre abonnement ? Vous perdrez l\'accès aux fonctionnalités premium.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Garder',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _subscriptionService.cancelSubscription();
            },
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
