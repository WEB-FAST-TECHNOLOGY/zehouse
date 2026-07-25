import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/currency_service.dart';

class PublishStep1Widget extends StatelessWidget {
  final Map<String, dynamic> formData;
  final bool isTablet;
  final Function(String key, dynamic value) onChanged;

  const PublishStep1Widget({
    super.key,
    required this.formData,
    required this.isTablet,
    required this.onChanged,
  });

  static const List<Map<String, dynamic>> _propertyTypes = [
    {
      'id': 'appartement',
      'label': 'Appartement',
      'icon': Icons.apartment_rounded,
    },
    {'id': 'maison', 'label': 'Maison', 'icon': Icons.house_rounded},
    {'id': 'studio', 'label': 'Studio', 'icon': Icons.single_bed_rounded},
    {'id': 'loft', 'label': 'Loft', 'icon': Icons.warehouse_rounded},
    {'id': 'duplex', 'label': 'Duplex', 'icon': Icons.layers_rounded},
    {'id': 'villa', 'label': 'Villa', 'icon': Icons.villa_rounded},
    {'id': 'hotel', 'label': 'Hôtel', 'icon': Icons.hotel_rounded},
    {'id': 'appt_meuble', 'label': 'Appt. Meublé', 'icon': Icons.chair_rounded},
    {
      'id': 'camping_car',
      'label': 'Camping-car',
      'icon': Icons.rv_hookup_rounded,
    },
    {
      'id': 'salle_fetes',
      'label': 'Salle de Fêtes',
      'icon': Icons.celebration_rounded,
    },
    {'id': 'bureau', 'label': 'Bureau', 'icon': Icons.business_center_rounded},
    {
      'id': 'demenagement',
      'label': 'Déménagement',
      'icon': Icons.local_shipping_rounded,
    },
    {'id': 'entretien', 'label': 'Entretien', 'icon': Icons.build_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Type de transaction'),
        const SizedBox(height: 12),
        Row(
          children: [
            _ToggleOption(
              label: 'Vente',
              icon: Icons.sell_rounded,
              isSelected: formData['listingType'] == 'sale',
              onTap: () => onChanged('listingType', 'sale'),
            ),
            const SizedBox(width: 12),
            _ToggleOption(
              label: 'Location',
              icon: Icons.key_rounded,
              isSelected: formData['listingType'] == 'rent',
              onTap: () => onChanged('listingType', 'rent'),
            ),
          ],
        ),

        const SizedBox(height: 28),
        _SectionTitle('Type de bien'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: isTablet ? 4 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.3,
          children: _propertyTypes.map((type) {
            final isSelected = formData['propertyType'] == type['id'];
            return GestureDetector(
              onTap: () => onChanged('propertyType', type['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 22,
                      color: isSelected ? Colors.white : AppTheme.muted,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type['label'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),
        _SectionTitle('Informations principales'),
        const SizedBox(height: 16),

        _buildTextField(
          label: 'Titre de l\'annonce',
          hint: 'ex. Bel appartement lumineux T3',
          initialValue: formData['title'] as String,
          onChanged: (v) => onChanged('title', v),
        ),

        const SizedBox(height: 20),

        // Price + Surface row
        if (isTablet)
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: formData['listingType'] == 'rent'
                      ? 'Loyer mensuel (${CurrencyService.instance.currentCurrency.symbol})'
                      : 'Prix de vente (${CurrencyService.instance.currentCurrency.symbol})',
                  hint: formData['listingType'] == 'rent' ? '1 800' : '450 000',
                  initialValue: formData['price'] as String,
                  onChanged: (v) => onChanged('price', v),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildNumberField(
                  label: 'Surface (m²)',
                  hint: '75',
                  initialValue: formData['surface'] as String,
                  onChanged: (v) => onChanged('surface', v),
                ),
              ),
            ],
          )
        else ...[
          _buildNumberField(
            label: formData['listingType'] == 'rent'
                ? 'Loyer mensuel (${CurrencyService.instance.currentCurrency.symbol})'
                : 'Prix de vente (${CurrencyService.instance.currentCurrency.symbol})',
            hint: formData['listingType'] == 'rent' ? '1 800' : '450 000',
            initialValue: formData['price'] as String,
            onChanged: (v) => onChanged('price', v),
          ),
          const SizedBox(height: 20),
          _buildNumberField(
            label: 'Surface (m²)',
            hint: '75',
            initialValue: formData['surface'] as String,
            onChanged: (v) => onChanged('surface', v),
          ),
        ],

        const SizedBox(height: 28),
        _SectionTitle('Détails du bien'),
        const SizedBox(height: 16),

        if (isTablet)
          Row(
            children: [
              Expanded(
                child: _buildRoomCounter(
                  label: 'Pièces',
                  value: int.tryParse(formData['rooms'] as String) ?? 3,
                  onChanged: (v) => onChanged('rooms', v.toString()),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildRoomCounter(
                  label: 'Chambres',
                  value: int.tryParse(formData['bedrooms'] as String) ?? 2,
                  onChanged: (v) => onChanged('bedrooms', v.toString()),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildNumberField(
                  label: 'Étage',
                  hint: '0',
                  initialValue: formData['floor'] as String,
                  onChanged: (v) => onChanged('floor', v),
                ),
              ),
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _buildRoomCounter(
                  label: 'Pièces',
                  value: int.tryParse(formData['rooms'] as String) ?? 3,
                  onChanged: (v) => onChanged('rooms', v.toString()),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildRoomCounter(
                  label: 'Chambres',
                  value: int.tryParse(formData['bedrooms'] as String) ?? 2,
                  onChanged: (v) => onChanged('bedrooms', v.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildNumberField(
            label: 'Étage',
            hint: '0 (rez-de-chaussée)',
            initialValue: formData['floor'] as String,
            onChanged: (v) => onChanged('floor', v),
          ),
        ],

        const SizedBox(height: 28),
        _SectionTitle('Classe énergétique (DPE)'),
        const SizedBox(height: 12),
        _buildEnergyClassSelector(formData['energyClass'] as String, onChanged),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: GoogleFonts.outfit(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  Widget _buildNumberField({
    required String label,
    required String hint,
    required String initialValue,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: AppTheme.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  Widget _buildRoomCounter({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (value > 1) onChanged(value - 1);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        value.toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onChanged(value + 1),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnergyClassSelector(
    String selected,
    Function(String, dynamic) onChanged,
  ) {
    const classes = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    const colors = [
      Color(0xFF16A34A),
      Color(0xFF65A30D),
      Color(0xFFD97706),
      Color(0xFFEA580C),
      Color(0xFFDC2626),
      Color(0xFF9F1239),
      Color(0xFF4C0519),
    ];

    return Row(
      children: List.generate(classes.length, (index) {
        final isSelected = selected == classes[index];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => onChanged('energyClass', classes[index]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors[index]
                      : colors[index].withAlpha(31),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: colors[index], width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    classes[index],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : colors[index],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
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

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
