// Mobile implementation for Moneroo checkout
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moneroo_flutter_sdk/moneroo_flutter_sdk.dart';

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

  MonerooCurrency _parseCurrency(String code) {
    switch (code.toUpperCase()) {
      case 'XOF':
        return MonerooCurrency.XOF;
      case 'XAF':
        return MonerooCurrency.XAF;
      case 'GHS':
        return MonerooCurrency.GHS;
      case 'NGN':
        return MonerooCurrency.NGN;
      default:
        return MonerooCurrency.XOF;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (apiKey.isEmpty || apiKey == 'YOUR_MONEROO_API_KEY') {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Clé API Moneroo manquante',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez configurer votre clé API Moneroo (MONEROO_API_KEY) pour activer les paiements.',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
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

    return Moneroo(
      amount: amount,
      apiKey: apiKey,
      currency: _parseCurrency(currency),
      customer: MonerooCustomer(
        email: customerEmail,
        firstName: customerFirstName,
        lastName: customerLastName,
      ),
      description: description,
      onPaymentCompleted: (infos, ctx) {
        if (infos.status == MonerooStatus.success) {
          onPaymentCompleted(true);
        } else {
          onPaymentCompleted(false);
        }
      },
      onError: (error, ctx) {
        onError(error.message ?? 'Une erreur est survenue');
        Navigator.pop(ctx);
      },
    );
  }
}
