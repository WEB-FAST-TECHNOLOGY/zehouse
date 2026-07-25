import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/currency_service.dart';

class PublishStep3Widget extends StatelessWidget {
  final Map<String, dynamic> formData;
  final Function(String key, dynamic value) onChanged;

  const PublishStep3Widget({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Adresse du bien'),
        const SizedBox(height: 6),
        Text(
          'L\'adresse exacte ne sera visible qu\'aux acheteurs/locataires intéressés.',
          style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        ),
        const SizedBox(height: 20),

        _buildTextField(
          label: 'Numéro et rue',
          hint: 'ex. 12 Rue de la Paix',
          initialValue: formData['address'] as String,
          onChanged: (v) => onChanged('address', v),
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'Ville',
                hint: 'Paris',
                initialValue: formData['city'] as String,
                onChanged: (v) => onChanged('city', v),
                icon: Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Code postal',
                hint: '75001',
                initialValue: formData['zipCode'] as String,
                onChanged: (v) => onChanged('zipCode', v),
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Map pin placement
        _SectionTitle('Positionnez le bien sur la carte'),
        const SizedBox(height: 12),
        _MapPinWidget(),

        const SizedBox(height: 28),

        // Publication settings
        _SectionTitle('Paramètres de publication'),
        const SizedBox(height: 16),

        _PublicationSettingTile(
          icon: Icons.visibility_rounded,
          title: 'Annonce publique',
          subtitle: 'Visible par tous les utilisateurs',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
            activeThumbColor: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _PublicationSettingTile(
          icon: Icons.notifications_rounded,
          title: 'Alertes automatiques',
          subtitle: 'Notifier les acheteurs correspondants',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
            activeThumbColor: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _PublicationSettingTile(
          icon: Icons.chat_bubble_rounded,
          title: 'Messages directs',
          subtitle: 'Autoriser les contacts via l\'app',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
            activeThumbColor: AppTheme.primary,
          ),
        ),

        const SizedBox(height: 28),

        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withAlpha(38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Récapitulatif',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SummaryRow(
                'Type',
                '${formData['propertyType']} · ${formData['listingType'] == 'sale' ? 'Vente' : 'Location'}',
              ),
              _SummaryRow(
                'Surface',
                '${formData['surface'].isEmpty ? '—' : formData['surface']} m²',
              ),
              _SummaryRow(
                'Prix',
                formData['price'].isEmpty
                    ? '—'
                    : CurrencyService.instance.format(
                        int.tryParse(formData['price'] as String) ?? 0,
                        isRent: formData['listingType'] == 'rent',
                      ),
              ),
              _SummaryRow(
                'Pièces',
                '${formData['rooms']} pièces · ${formData['bedrooms']} chambres',
              ),
              _SummaryRow(
                'Adresse',
                formData['address'].isEmpty
                    ? '—'
                    : '${formData['address']}, ${formData['zipCode']} ${formData['city']}',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String initialValue,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.outfit(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.muted),
        labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _MapPinWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: const Color(0xFFE8EFF6),
            child: CustomPaint(painter: _SimpleMapPainter()),
          ),
          Positioned.fill(
            child: Center(
              child: Icon(
                Icons.location_on_rounded,
                size: 40,
                color: AppTheme.accent,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_location_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ajuster la position',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;
    final m = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      p,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      p,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      m,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      m,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.75, size.height),
      m,
    );
    final block = Paint()..color = const Color(0xFFD1DCE8);
    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.width * 0.26, size.height * 0.44),
      block,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.3 + 4,
        4,
        size.width * 0.19,
        size.height * 0.44,
      ),
      block,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5 + 4,
        size.height * 0.5 + 4,
        size.width * 0.23,
        size.height * 0.44,
      ),
      block,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PublicationSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PublicationSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
