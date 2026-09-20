import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../env.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/cinetpay_web.dart'
    if (dart.library.io) '../../services/cinetpay_io.dart';
import '../../services/cinetpay_api_service.dart';

class CinetPayTestScreen extends StatefulWidget {
  const CinetPayTestScreen({super.key});

  @override
  State<CinetPayTestScreen> createState() => _CinetPayTestScreenState();
}

class _CinetPayTestScreenState extends State<CinetPayTestScreen> {
  final TextEditingController _amountController = TextEditingController(text: '100');
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Test de paiement CinetPay Zehouse',
  );

  int _selectedPreset = 100;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _testHistory = [];

  final String _cinetpayApiKey = Env.cinetpayApiKey;
  final String _cinetpayApiPassword = Env.cinetpayApiPassword;
  final String _cinetpaySiteId = Env.cinetpaySiteId;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onPresetSelected(int amount) {
    setState(() {
      _selectedPreset = amount;
      _amountController.text = amount.toString();
    });
  }

  void _startTestPayment() {
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);
    if (amount == null || amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant valide (minimum 10 XAF).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final transactionId = 'TEST-${const Uuid().v4().replaceAll('-', '').substring(0, 12)}';
    final description = _descriptionController.text.trim().isEmpty
        ? 'Test CinetPay Zehouse'
        : _descriptionController.text.trim();

    final user = SupabaseService.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'testeur@zehouse.cm';

    final testRecord = {
      'transaction_id': transactionId,
      'amount': amount,
      'currency': 'XAF',
      'description': description,
      'status': 'PENDING',
      'created_at': DateTime.now(),
    };

    setState(() {
      _testHistory.insert(0, testRecord);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CinetPayCheckoutWidget(
          title: 'Test CinetPay ($amount XAF)',
          configData: {
            'apikey': _cinetpayApiKey,
            'api_password': _cinetpayApiPassword,
            'site_id': _cinetpaySiteId,
            'notify_url': 'https://zehouse2471.builtwithrocket.new/cinetpay/notify',
            'return_url': 'https://google.com',
          },
          paymentData: {
            'transaction_id': transactionId,
            'amount': amount,
            'currency': 'XAF',
            'channels': 'ALL',
            'description': description,
            'customer_email': userEmail,
            'lang': 'fr',
          },
          waitResponse: (response) {
            Navigator.pop(context);
            _updateTransactionStatus(transactionId, 'ACCEPTED', response);
            _showResultDialog(
              success: true,
              title: 'Paiement Réussi !',
              message: 'Le paiement de test de $amount XAF a été validé par CinetPay.',
              transactionId: transactionId,
              data: response,
            );
          },
          onError: (error) {
            Navigator.pop(context);
            _updateTransactionStatus(transactionId, 'REFUSED', error);
            _showResultDialog(
              success: false,
              title: 'Échec du Paiement',
              message: error['message'] ?? 'Erreur lors du traitement du paiement.',
              transactionId: transactionId,
              data: error,
            );
          },
        ),
      ),
    );
  }

  void _updateTransactionStatus(String txId, String status, Map<String, dynamic> data) {
    setState(() {
      final index = _testHistory.indexWhere((t) => t['transaction_id'] == txId);
      if (index != -1) {
        _testHistory[index]['status'] = status;
        _testHistory[index]['response'] = data;
      }
    });
  }

  Future<void> _recheckStatus(Map<String, dynamic> item) async {
    final txId = item['transaction_id'] as String;
    setState(() => _isLoading = true);

    final status = await CinetPayApiService.checkPaymentStatus(
      apiKey: _cinetpayApiKey,
      apiPassword: _cinetpayApiPassword,
      siteId: _cinetpaySiteId,
      transactionId: txId,
    );

    setState(() => _isLoading = false);

    _updateTransactionStatus(txId, status, {'manual_check': true, 'status': status});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut de $txId: $status'),
          backgroundColor: status == 'ACCEPTED' || status == 'SUCCESS'
              ? Colors.green
              : (status == 'REFUSED' ? Colors.red : Colors.orange),
        ),
      );
    }
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
    required String transactionId,
    required Map<String, dynamic> data,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? Colors.green : Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Transaction: $transactionId',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Données retournées:\n$data',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Fermer',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasConfig = _cinetpayApiKey.isNotEmpty && _cinetpaySiteId.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '🧪 Test CinetPay (Sandbox)',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasConfig
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasConfig ? Colors.green : Colors.orange,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasConfig ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    color: hasConfig ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasConfig ? 'CinetPay Configuré' : 'Configuration CinetPay Incomplète',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Site ID: $_cinetpaySiteId | Key: ${_cinetpayApiKey.isEmpty ? "Manquant" : "OK"}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount Selection Section
            Text(
              '1. Choisir le montant de test (XAF)',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [10, 50, 100, 500, 1000].map((preset) {
                final isSelected = _selectedPreset == preset;
                return ChoiceChip(
                  label: Text(
                    '$preset XAF',
                    style: GoogleFonts.outfit(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (val) {
                    if (val) _onPresetSelected(preset);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant personnalisé (XAF)',
                prefixIcon: const Icon(Icons.numbers_rounded),
                suffixText: 'XAF',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.surface,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null) {
                  setState(() => _selectedPreset = parsed);
                }
              },
            ),

            const SizedBox(height: 20),

            // Description field
            Text(
              '2. Description du test',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Libellé de la transaction',
                prefixIcon: const Icon(Icons.description_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.surface,
              ),
            ),

            const SizedBox(height: 24),

            // Launch Test Payment Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startTestPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.credit_card_rounded, size: 22),
                label: Text(
                  'Lancer le paiement (${_amountController.text} XAF)',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Test History Section
            if (_testHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historique des tests récents',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _testHistory.length,
                itemBuilder: (context, index) {
                  final item = _testHistory[index];
                  final status = item['status'] as String;
                  Color statusColor;
                  IconData statusIcon;

                  switch (status) {
                    case 'ACCEPTED':
                    case 'SUCCESS':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle_rounded;
                      break;
                    case 'REFUSED':
                      statusColor = Colors.redAccent;
                      statusIcon = Icons.cancel_rounded;
                      break;
                    default:
                      statusColor = Colors.orange;
                      statusIcon = Icons.pending_rounded;
                      break;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['amount']} XAF — ${item['description']}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${item['transaction_id']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _recheckStatus(item),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: Text(
                            'Vérifier',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
