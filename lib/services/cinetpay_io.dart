// Mobile implementation for CinetPay checkout
import 'package:flutter/material.dart';
import 'package:cinetpay/cinetpay.dart';

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
    return CinetPayCheckout(
      title: title,
      configData: configData,
      paymentData: paymentData,
      waitResponse: waitResponse,
      onError: onError,
    );
  }
}
