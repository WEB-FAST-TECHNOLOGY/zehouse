import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:uuid/uuid.dart';

import '../../theme/app_theme.dart';
import '../../services/subscription_service.dart';
import '../../services/cinetpay_web.dart'
    if (dart.library.io) '../../services/cinetpay_io.dart';
import '../../services/moneroo_web.dart'
    if (dart.library.io) '../../services/moneroo_io.dart';

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

  static const String _cinetpayApiKey = String.fromEnvironment(
    'CINETPAY_API_KEY',
  );
  static const int _cinetpaySiteId = int.fromEnvironment(
    'CINETPAY_SITE_ID',
    defaultValue: 0,
  );
  static const String _notifyUrl =
      'https://zehouse2471.builtwithrocket.new/cinetpay/notify';

  static const String _monerooApiKey = String.fromEnvironment(
    'MONEROO_API_KEY',
  );

  // ─── Immobilier plans ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _immobilierPlans = [
    {
      'plan': SubscriptionPlan.hotel,
      'title': 'Hôtel',
      'price': 50,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.hotel_rounded,
      'color': const Color(0xFF1A2B4A),
      'description':
          'Publiez et gérez vos annonces hôtelières avec toutes les fonctionnalités premium.',
      'features': [
        'Annonces hôtelières illimitées',
        'Photos haute résolution',
        'Mise en avant dans les résultats',
        'Statistiques détaillées',
        'Support prioritaire',
      ],
    },
    {
      'plan': SubscriptionPlan.appartement,
      'title': 'Appartement Meublé',
      'price': 35,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.apartment_rounded,
      'color': const Color(0xFF7C3AED),
      'description':
          'Gérez vos appartements meublés et trouvez des locataires rapidement.',
      'features': [
        'Annonces appartements illimitées',
        'Galerie photos complète',
        'Visibilité accrue',
        'Messagerie intégrée',
        'Tableau de bord analytique',
      ],
    },
    {
      'plan': SubscriptionPlan.agent,
      'title': 'Agent Immobilier',
      'price': 45,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.real_estate_agent_rounded,
      'color': const Color(0xFF0891B2),
      'description':
          'Gérez votre portefeuille de biens et développez votre clientèle.',
      'features': [
        'Annonces illimitées (vente & location)',
        'Profil agent vérifié',
        'Mise en avant dans les recherches',
        'Messagerie intégrée',
        'Statistiques de performance',
      ],
    },
  ];

  // ─── Professionnels plans ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _professionnelPlans = [
    {
      'plan': SubscriptionPlan.architecte,
      'title': 'Architecte',
      'price': 50,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.architecture_rounded,
      'color': const Color(0xFF7C3AED),
      'description': 'Présentez vos projets et attirez de nouveaux clients.',
      'features': [
        'Profil professionnel complet',
        'Portfolio de projets',
        'Mise en avant dans les résultats',
        'Messagerie clients',
        'Badge certifié',
      ],
    },
    {
      'plan': SubscriptionPlan.plombier,
      'title': 'Plombier',
      'price': 30,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF0891B2),
      'description': 'Développez votre activité et recevez plus de demandes.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.electricien,
      'title': 'Électricien',
      'price': 30,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFFD97706),
      'description': 'Attirez plus de clients pour vos travaux électriques.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.macon,
      'title': 'Maçon',
      'price': 30,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.foundation_rounded,
      'color': const Color(0xFF92400E),
      'description': 'Trouvez des chantiers et développez votre réputation.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.peintre,
      'title': 'Peintre',
      'price': 25,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.format_paint_rounded,
      'color': const Color(0xFFE85D4A),
      'description': 'Montrez vos réalisations et obtenez plus de contrats.',
      'features': [
        'Profil professionnel visible',
        'Galerie de réalisations',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.menuisier,
      'title': 'Menuisier',
      'price': 30,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.carpenter_rounded,
      'color': const Color(0xFF92400E),
      'description': 'Présentez vos créations sur mesure à vos futurs clients.',
      'features': [
        'Profil professionnel visible',
        'Galerie de réalisations',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.carreleur,
      'title': 'Carreleur',
      'price': 25,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.grid_4x4_rounded,
      'color': const Color(0xFF0891B2),
      'description': 'Développez votre clientèle dans votre zone.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.couvreur,
      'title': 'Couvreur',
      'price': 30,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.roofing_rounded,
      'color': const Color(0xFF1A2B4A),
      'description': 'Trouvez des chantiers de toiture dans votre région.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.serrurier,
      'title': 'Serrurier',
      'price': 25,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.lock_rounded,
      'color': const Color(0xFF374151),
      'description': 'Soyez visible pour les urgences et interventions.',
      'features': [
        'Profil professionnel visible',
        'Disponibilité urgence 24h',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.chauffagiste,
      'title': 'Chauffagiste',
      'price': 30,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFDC2626),
      'description':
          'Attirez des clients pour l\'installation et l\'entretien.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.decorateur,
      'title': 'Décorateur',
      'price': 40,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.palette_rounded,
      'color': const Color(0xFFEC4899),
      'description': 'Présentez vos créations et développez votre clientèle.',
      'features': [
        'Profil professionnel visible',
        'Portfolio de projets',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.soudeur,
      'title': 'Soudeur',
      'price': 25,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.hardware_rounded,
      'color': const Color(0xFF374151),
      'description': 'Trouvez des chantiers de soudure et métallerie.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.charpentier,
      'title': 'Charpentier',
      'price': 30,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.cabin_rounded,
      'color': const Color(0xFF92400E),
      'description': 'Développez votre activité de charpente et ossature bois.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
    {
      'plan': SubscriptionPlan.ferrailleur,
      'title': 'Ferrailleur',
      'price': 20,
      'currency': 'USD',
      'period': 'an',
      'icon': Icons.construction_rounded,
      'color': const Color(0xFF374151),
      'description': 'Trouvez des chantiers de ferraillage et béton armé.',
      'features': [
        'Profil professionnel visible',
        'Zone d\'intervention configurable',
        'Mise en avant dans les résultats',
        'Messagerie intégrée',
        'Badge vérifié',
      ],
    },
  ];

  void _onSubscriptionUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscriptionService.addListener(_onSubscriptionUpdated);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subscriptionService.removeListener(_onSubscriptionUpdated);
    super.dispose();
  }

  Future<void> _startTrial(SubscriptionPlan plan) async {
    setState(() => _isLoading = true);
    await _subscriptionService.activateTrial(plan, sponsored: _wantSponsored);
    setState(() => _isLoading = false);
    if (mounted) {
      _showSuccessDialog(
        'Essai gratuit activé !',
        'Votre période d\'essai de 30 jours a été activée. Profitez de toutes les fonctionnalités.',
      );
    }
  }

  void _startPayment(Map<String, dynamic> planData) {
    _showPaymentProviderDialog(planData);
  }

  void _showPaymentProviderDialog(Map<String, dynamic> planData) {
    final color = planData['color'] as Color;
    final title = planData['title'] as String;
    final baseAmount = planData['price'] as int;
    final sponsoredExtra = _wantSponsored ? 30 : 0;
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
              'Choisir le moyen de paiement',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Abonnement $title — $totalAmount\$/an${_wantSponsored ? ' (dont 30\$ sponsoring)' : ''}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildProviderTile(
              icon: Icons.credit_card_rounded,
              providerName: 'CinetPay',
              subtitle: 'Mobile Money, cartes bancaires',
              color: const Color(0xFF0066CC),
              onTap: () {
                Navigator.pop(context);
                _startCinetPayPayment(planData, totalAmount);
              },
            ),
            const SizedBox(height: 12),
            _buildProviderTile(
              icon: Icons.account_balance_wallet_rounded,
              providerName: 'Moneroo',
              subtitle: 'Mobile Money, transferts, cartes',
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(context);
                _startMonerooPayment(planData, totalAmount);
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

  void _startCinetPayPayment(Map<String, dynamic> planData, int amount) {
    final plan = planData['plan'] as SubscriptionPlan;
    final currency = planData['currency'] as String;
    final title = planData['title'] as String;
    final transactionId = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 20);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinetPayCheckoutWidget(
          title: 'Abonnement $title',
          configData: {
            'apikey': _cinetpayApiKey.isEmpty
                ? 'YOUR_CINETPAY_API_KEY'
                : _cinetpayApiKey,
            'site_id': _cinetpaySiteId == 0 ? 12345678 : _cinetpaySiteId,
            'notify_url': _notifyUrl,
          },
          paymentData: {
            'transaction_id': transactionId,
            'amount': amount,
            'currency': currency,
            'channels': 'ALL',
            'description': 'Abonnement annuel $title - ZEHOUSE',
          },
          waitResponse: (response) {
            Navigator.pop(context);
            _handlePaymentResponse(response, plan, transactionId);
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonerooCheckoutWidget(
          title: 'Abonnement $title',
          amount: amount,
          currency: 'XOF',
          description: 'Abonnement annuel $title - ZEHOUSE',
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
                    sponsored: _wantSponsored,
                  )
                  .then((_) {
                    if (mounted) {
                      _showSuccessDialog(
                        'Paiement accepté !',
                        'Votre abonnement annuel a été activé avec succès. Profitez de toutes les fonctionnalités.',
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

  void _handlePaymentResponse(
    Map<String, dynamic> response,
    SubscriptionPlan plan,
    String transactionId,
  ) async {
    final status = response['status'] as String? ?? '';
    if (status == 'ACCEPTED') {
      await _subscriptionService.activatePaidSubscription(
        plan,
        transactionId,
        sponsored: _wantSponsored,
      );
      if (mounted) {
        _showSuccessDialog(
          'Paiement accepté !',
          'Votre abonnement annuel a été activé avec succès. Profitez de toutes les fonctionnalités.',
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

  void _showSuccessDialog(String title, String message) {
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
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
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
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
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
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Immobilier'),
            Tab(text: 'Professionnels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlanList(_immobilierPlans, sub),
          _buildPlanList(_professionnelPlans, sub),
        ],
      ),
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
    final color = sub.plan == SubscriptionPlan.hotel
        ? AppTheme.primary
        : const Color(0xFF7C3AED);

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
              sub.plan == SubscriptionPlan.hotel
                  ? Icons.hotel_rounded
                  : Icons.work_rounded,
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

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isCurrentPlan ? color : AppTheme.border,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                      '${planData['price']}\$',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/ ${planData['period']}',
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
                        'Sponsoring inclus +30\$/an',
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
    final basePrice = planData['price'] as int;
    final totalPrice = basePrice + (_wantSponsored ? 30 : 0);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _startTrial(planData['plan'] as SubscriptionPlan),
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
              'Payer maintenant — $totalPrice\$/an',
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
    final basePrice = planData['price'] as int;
    final totalPrice = basePrice + (_wantSponsored ? 30 : 0);
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
          'Activer — $totalPrice\$/an',
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
    final basePrice = planData['price'] as int;
    final totalPrice = basePrice + (_wantSponsored ? 30 : 0);
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
          'Renouveler — $totalPrice\$/an',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSwitchButton(Map<String, dynamic> planData, Color color) {
    final basePrice = planData['price'] as int;
    final totalPrice = basePrice + (_wantSponsored ? 30 : 0);
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
          'Changer de plan — $totalPrice\$/an',
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
