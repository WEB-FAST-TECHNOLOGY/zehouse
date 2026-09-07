import 'dart:convert';
import 'package:http/http.dart' as http;

/// CinetPay API Service — Aurore v1
/// Flow: 1) POST /v1/oauth/login → token  2) POST /v1/payment (Bearer token)
class CinetPayApiService {
  static const String _baseUrl = 'https://api.cinetpay.net/v1';

  // ─── Step 1 : OAuth Login → bearer token ───────────────────────────────────
  static Future<String?> _getToken({
    required String apiKey,
    required String apiPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/oauth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'api_key': apiKey,
              'api_password': apiPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      print('CINETPAY LOGIN: ${response.statusCode} → ${response.body}');

      if (response.statusCode == 200) {
        // CinetPay Aurore returns access_token at root level
        return data['access_token'] ??
            data['data']?['token'] ??
            data['data']?['access_token'] ??
            data['token'];
      }
      print('CINETPAY LOGIN FAILED: ${response.body}');
      return null;
    } catch (e) {
      print('CINETPAY LOGIN EXCEPTION: $e');
      return null;
    }
  }

  // ─── Step 2 : Initiate Payment → payment_url ───────────────────────────────
  static Future<String?> initiatePayment({
    required String apiKey,
    required String apiPassword,
    required String siteId,
    required String transactionId,
    required int amount,
    required String currency,
    required String description,
    required String notifyUrl,
    required String returnUrl,
    String lang = 'fr',
  }) async {
    // 1. Get token
    final token = await _getToken(apiKey: apiKey, apiPassword: apiPassword);
    if (token == null) {
      print('CINETPAY: Impossible d\'obtenir le token d\'authentification.');
      return null;
    }

    // 2. Initiate payment
    final payload = {
      'site_id': siteId,
      'merchant_transaction_id': transactionId,
      'amount': amount,
      'currency': currency,
      'designation': description,
      'notify_url': notifyUrl,
      'success_url': returnUrl,
      'failed_url': returnUrl,
      'channels': 'ALL',
      'lang': lang,
    };

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/payment'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      print('CINETPAY PAYMENT: ${response.statusCode} → ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // CinetPay Aurore: payment_url is at root level when status is OK
        final paymentUrl = data['payment_url'];
        if (paymentUrl != null) {
          return paymentUrl as String;
        }
        print('CINETPAY PAYMENT: No payment_url — ${data['details']?['message'] ?? data}');
        return null;
      }
      print('CINETPAY PAYMENT HTTP ERROR: ${response.statusCode} → ${response.body}');
      return null;
    } catch (e) {
      print('CINETPAY PAYMENT EXCEPTION: $e');
      return null;
    }
  }

  // ─── Check payment status ──────────────────────────────────────────────────
  static Future<String> checkPaymentStatus({
    required String apiKey,
    required String apiPassword,
    required String siteId,
    required String transactionId,
  }) async {
    final token = await _getToken(apiKey: apiKey, apiPassword: apiPassword);
    if (token == null) return 'ERROR';

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/payment/$transactionId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      print('CINETPAY STATUS: ${response.statusCode} → ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['status'] ?? 'PENDING';
      }
      return 'PENDING';
    } catch (e) {
      print('CINETPAY STATUS EXCEPTION: $e');
      return 'ERROR';
    }
  }
}
