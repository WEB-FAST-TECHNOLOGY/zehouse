// Web stub for CinetPay checkout
// The cinetpay package does not support web; this stub provides a no-op widget
import 'package:flutter/material.dart';

class CinetPayCheckoutWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Web: CinetPay SDK not available — show informational message
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payment_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Paiement CinetPay',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Le paiement CinetPay est disponible uniquement sur l\'application mobile.\n\nVeuillez télécharger l\'APK pour effectuer votre paiement.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
