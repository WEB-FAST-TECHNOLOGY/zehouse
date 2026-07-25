// Web stub for Moneroo checkout
// The moneroo_flutter_sdk package does not support web; this stub provides an informational widget
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonerooCheckoutWidget extends StatelessWidget {
  final String title;
  final int amount;
  final String currency;
  final String description;
  final String apiKey;
  final String customerEmail;
  final String customerFirstName;
  final String customerLastName;
  final void Function(bool success) onPaymentCompleted;
  final void Function(String error) onError;

  const MonerooCheckoutWidget({
    super.key,
    required this.title,
    required this.amount,
    required this.currency,
    required this.description,
    required this.apiKey,
    required this.customerEmail,
    required this.customerFirstName,
    required this.customerLastName,
    required this.onPaymentCompleted,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  size: 36,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Paiement Moneroo',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Le paiement Moneroo est disponible uniquement sur l\'application mobile.\n\nVeuillez télécharger l\'APK pour effectuer votre paiement.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
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
