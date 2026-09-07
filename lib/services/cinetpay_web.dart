import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cinetpay_api_service.dart';

class CinetPayCheckoutWidget extends StatefulWidget {
  final String title;
  final Map<String, dynamic> configData;
  final Map<String, dynamic> paymentData;
  final void Function(Map<String, dynamic> response) waitResponse;
  final void Function(Map<String, dynamic> error) onError;

  const CinetPayCheckoutWidget({
    super.key,
    required this.title,
    required this.configData,
    required this.paymentData,
    required this.waitResponse,
    required this.onError,
  });

  @override
  State<CinetPayCheckoutWidget> createState() => _CinetPayCheckoutWidgetState();
}

class _CinetPayCheckoutWidgetState extends State<CinetPayCheckoutWidget> {
  bool _isInit = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    setState(() => _isLoading = true);

    final paymentUrl = await CinetPayApiService.initiatePayment(
      apiKey: widget.configData['apikey'] ?? '',
      apiPassword: widget.configData['api_password'] ?? '',
      siteId: widget.configData['site_id'] ?? '',
      transactionId: widget.paymentData['transaction_id'],
      amount: widget.paymentData['amount'],
      currency: widget.paymentData['currency'],
      description: widget.paymentData['description'],
      notifyUrl: widget.configData['notify_url'] ?? 'https://google.com',
      returnUrl: widget.configData['return_url'] ?? 'https://google.com',
      lang: widget.paymentData['lang'] ?? 'fr',
    );

    setState(() {
      _isLoading = false;
      _isInit = false;
    });

    if (paymentUrl != null) {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        // webOnlyWindowName: '_blank' allows opening a new tab on web
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView, webOnlyWindowName: '_blank');
      } else {
        widget.onError({'message': 'Impossible d\'ouvrir la page de paiement.'});
      }
    } else {
      widget.onError({'message': 'Erreur lors de l\'initialisation CinetPay.'});
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final status = await CinetPayApiService.checkPaymentStatus(
      apiKey: widget.configData['apikey'] ?? '',
      apiPassword: widget.configData['api_password'] ?? '',
      siteId: widget.configData['site_id'] ?? '',
      transactionId: widget.paymentData['transaction_id'],
    );
    setState(() => _isLoading = false);

    if (status == 'ACCEPTED' || status == 'SUCCESS') {
      widget.waitResponse({'status': 'ACCEPTED'});
    } else if (status == 'REFUSED') {
      widget.onError({'message': 'Paiement refusé'});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le paiement est toujours en attente...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.outfit(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: _isInit || _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment_rounded, size: 64, color: Colors.blue),
                    const SizedBox(height: 24),
                    Text(
                      'Paiement en cours',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Une page sécurisée a été ouverte pour votre paiement. Une fois terminé, cliquez sur le bouton ci-dessous.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _checkStatus,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'J\'ai terminé mon paiement',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
