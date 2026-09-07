import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../env.dart';

import '../../../theme/app_theme.dart';
import '../../../services/cinetpay_web.dart'
    if (dart.library.io) '../../../services/cinetpay_io.dart';
import '../../../services/moneroo_web.dart'
    if (dart.library.io) '../../../services/moneroo_io.dart';
import '../../../services/currency_service.dart';

/// Payment gate that charges non-professional users $10 before publishing a listing.
class ListingPaymentGateWidget extends StatefulWidget {
  final VoidCallback onPaymentSuccess;
  final VoidCallback onCancel;

  const ListingPaymentGateWidget({
    super.key,
    required this.onPaymentSuccess,
    required this.onCancel,
  });

  @override
  State<ListingPaymentGateWidget> createState() =>
      _ListingPaymentGateWidgetState();
}

class _ListingPaymentGateWidgetState extends State<ListingPaymentGateWidget> {
  static final String _cinetpayApiKey = Env.cinetpayApiKey;
  static final String _cinetpayApiPassword = Env.cinetpayApiPassword;
  static final String _cinetpaySiteId = Env.cinetpaySiteId;
  static final String _monerooApiKey = Env.monerooApiKey;

  static const int _listingFeeUsd = 10;
  // 10 USD ≈ 6000 XAF (Cameroun)

  void _payCinetPay() {
    // CinetPay compte Cameroun → toujours XAF
    // (même si l'utilisateur affiche en EUR/USD, on paye en XAF sur ce compte)
    final String cinetpayCurrency = 'XAF';
    const int amountInXaf = 6000; // ~10 USD


    _printYellowLog(
      'INITIATING CINETPAY PUBLISH PAYMENT\n'
      'Amount: $amountInXaf $cinetpayCurrency\n'
      'Site ID: $_cinetpaySiteId\n'
      'API Key: ${_cinetpayApiKey.isEmpty ? 'MISSING' : 'PROVIDED'}'
    );

    final transactionId = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 20);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinetPayCheckoutWidget(
          title: 'Frais de publication',
          configData: {
            'apikey': _cinetpayApiKey,
            'api_password': _cinetpayApiPassword,
            'site_id': _cinetpaySiteId,
            'notify_url':
                'https://zehouse2471.builtwithrocket.new/cinetpay/notify',
            'return_url': 'https://zehouse2471.builtwithrocket.new',
          },
          paymentData: {
            'transaction_id': transactionId,
            'amount': amountInXaf,
            'currency': cinetpayCurrency,
            'channels': 'ALL',
            'description': 'Frais de publication d\'annonce immobilière',
            'lang': 'fr',
          },
          waitResponse: (response) {
            final status = response['status']?.toString() ?? '';
            if (status == 'ACCEPTED' || status == 'SUCCESS') {
              Navigator.pop(context);
              widget.onPaymentSuccess();
            } else {
              Navigator.pop(context);
              _showError('Paiement non complété. Veuillez réessayer.');
            }
          },
          onError: (error) {
            Navigator.pop(context);
            _showError('Erreur de paiement. Veuillez réessayer.');
          },
        ),
      ),
    );
  }

  void _payMoneroo() {
    _printYellowLog(
      'INITIATING MONEROO PUBLISH PAYMENT\n'
      'Amount: 6000 XAF\n'
      'API Key: ${_monerooApiKey.isEmpty ? 'MISSING' : 'PROVIDED'}'
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonerooCheckoutWidget(
          title: 'Frais de publication',
          amount: _listingFeeUsd,
          currency: 'USD',
          description: 'Frais de publication d\'annonce immobilière',
          apiKey: _monerooApiKey,
          customerEmail: '',
          customerFirstName: 'Utilisateur',
          customerLastName: 'ZEHOUSE',
          onPaymentCompleted: (success) {
            Navigator.pop(context);
            if (success) {
              widget.onPaymentSuccess();
            } else {
              _showError('Paiement non complété. Veuillez réessayer.');
            }
          },
          onError: (error) {
            Navigator.pop(context);
            _showError('Erreur de paiement. Veuillez réessayer.');
          },
        ),
      ),
    );
  }

  void _printYellowLog(String message) {
    debugPrint('\x1B[33m========================================\x1B[0m');
    debugPrint('\x1B[33m🚀 ZEHOUSE PUBLISH LOG:\x1B[0m');
    debugPrint('\x1B[33m$message\x1B[0m');
    debugPrint('\x1B[33m========================================\x1B[0m');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Publication payante',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'En tant qu\'utilisateur standard, chaque publication d\'annonce immobilière est facturée',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accent.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_money_rounded,
                      color: AppTheme.accent,
                      size: 28,
                    ),
                    Text(
                      '10 USD',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accent,
                      ),
                    ),
                    Text(
                      ' / annonce',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.check_circle_rounded,
                      AppTheme.success,
                      'Annonce visible sur la carte',
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.check_circle_rounded,
                      AppTheme.success,
                      'Accessible aux acheteurs et locataires',
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.star_rounded,
                      AppTheme.primary,
                      'Abonnez-vous pour publier sans frais',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Tip: subscribe to avoid fees
              TextButton.icon(
                onPressed: () {
                  widget.onCancel();
                  Navigator.pushNamed(context, '/subscription-plans-screen');
                },
                icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                label: Text(
                  'Voir les abonnements professionnels',
                  style: GoogleFonts.outfit(fontSize: 13),
                ),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
              const SizedBox(height: 24),
              // Bouton de paiement unique
              _PaymentButton(
                label: 'Accéder au paiement',
                subtitle: 'Mobile Money, Orange Money, Wave...',
                icon: Icons.payment_rounded,
                color: const Color(0xFF0066CC),
                onTap: _payCinetPay,
              ),
              const SizedBox(height: 24),
              // Cancel
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Annuler',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PaymentButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
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
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
