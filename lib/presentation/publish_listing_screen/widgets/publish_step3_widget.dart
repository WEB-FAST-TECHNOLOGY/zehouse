import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../../../theme/app_theme.dart';
import '../../../services/currency_service.dart';
import '../../../services/mapbox_service.dart';
import '../../property_detail_screen/widgets/property_mini_map_widget.dart';

class PublishStep3Widget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String key, dynamic value) onChanged;

  const PublishStep3Widget({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<PublishStep3Widget> createState() => _PublishStep3WidgetState();
}

class _PublishStep3WidgetState extends State<PublishStep3Widget> {
  bool _isLocating = false;
  bool _searchLocal = false; // Default to global, switch enables local
  Position? _biasPosition;
  Key _addressKey = UniqueKey();
  
  late TextEditingController _cityController;
  late TextEditingController _zipCodeController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.formData['city'] as String? ?? '');
    _zipCodeController = TextEditingController(text: widget.formData['zipCode'] as String? ?? '');
    _initLocationBias();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _initLocationBias() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _biasPosition = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      }
    } catch (_) {}
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isLocating = false);
        return;
      }
      
      final position = await Geolocator.getCurrentPosition();
      _biasPosition = position;
      _searchLocal = true;
      final data = await MapboxService.reverseGeocode(position.latitude, position.longitude);
      
      if (data != null && mounted) {
        widget.onChanged('address', data['address'] ?? '');
        widget.onChanged('city', data['city'] ?? '');
        widget.onChanged('zipCode', data['zipCode'] ?? '');
        widget.onChanged('lat', data['lat']);
        widget.onChanged('lng', data['lng']);
        
        _cityController.text = data['city'] ?? '';
        _zipCodeController.text = data['zipCode'] ?? '';
        _addressKey = UniqueKey(); // Force rebuild Autocomplete
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
    if (mounted) setState(() => _isLocating = false);
  }

  Future<void> _toggleSearchLocal(bool value) async {
    setState(() => _searchLocal = value);
    if (value && _biasPosition == null) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          _biasPosition = await Geolocator.getCurrentPosition();
        }
      } catch (_) {}
    }
  }

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
        const SizedBox(height: 12),

        // Toggle Local Search
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Privilégier les résultats près de moi', style: GoogleFonts.outfit(fontSize: 14)),
          subtitle: Text('Recherche locale vs. mondiale', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
          value: _searchLocal,
          activeColor: AppTheme.primary,
          onChanged: _toggleSearchLocal,
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLocating ? null : _useCurrentLocation,
                icon: _isLocating 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Utiliser ma position actuelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary.withAlpha(25),
                  foregroundColor: AppTheme.primary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Autocomplete<Map<String, dynamic>>(
          key: _addressKey,
          initialValue: TextEditingValue(text: widget.formData['address'] as String? ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty || textEditingValue.text.length < 3) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            String? proximity;
            if (_searchLocal && _biasPosition != null) {
              proximity = '${_biasPosition!.longitude},${_biasPosition!.latitude}';
            }
            return await MapboxService.searchPlaces(textEditingValue.text, proximity: proximity);
          },
          displayStringForOption: (Map<String, dynamic> option) => option['place_name'] ?? '',
          onSelected: (Map<String, dynamic> selection) {
            String address = selection['text'] ?? '';
            if (selection['address'] != null) {
              address = '${selection['address']} $address';
            }
            
            String city = '';
            String zipCode = '';
            
            final contextList = selection['context'] as List?;
            if (contextList != null) {
              for (final ctx in contextList) {
                final id = ctx['id'] as String? ?? '';
                if (id.startsWith('place')) city = ctx['text'] ?? '';
                if (id.startsWith('postcode')) zipCode = ctx['text'] ?? '';
              }
            }

            // Fallback for city
            if (city.isEmpty && selection['place_type'] != null) {
              final placeTypes = (selection['place_type'] as List).cast<String>();
              if (placeTypes.contains('place')) {
                city = selection['text'] ?? '';
              }
            }

            widget.onChanged('address', address);
            if (city.isNotEmpty) {
              widget.onChanged('city', city);
              _cityController.text = city;
            }
            if (zipCode.isNotEmpty) {
              widget.onChanged('zipCode', zipCode);
              _zipCodeController.text = zipCode;
            }

            // Coordinates
            if (selection['geometry'] != null) {
              final coords = selection['geometry']['coordinates'] as List?;
              if (coords != null && coords.length >= 2) {
                widget.onChanged('lng', coords[0]);
                widget.onChanged('lat', coords[1]);
              }
            }
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (v) => widget.onChanged('address', v),
              style: GoogleFonts.outfit(fontSize: 15, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Numéro et rue',
                hintText: 'ex. 12 Rue de la Paix',
                prefixIcon: Icon(Icons.home_outlined, size: 18, color: AppTheme.muted),
                labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
                border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.border)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 250,
                    maxWidth: MediaQuery.of(context).size.width - 32,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: Icon(Icons.location_on_outlined, color: AppTheme.primary),
                        title: Text(
                          option['text'] ?? '',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          option['place_name'] ?? '',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'Ville',
                hint: 'Paris',
                controller: _cityController,
                onChanged: (v) => widget.onChanged('city', v),
                icon: Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Code postal',
                hint: '75001',
                controller: _zipCodeController,
                onChanged: (v) => widget.onChanged('zipCode', v),
                icon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Map pin placement
        _SectionTitle('Positionnez le bien sur la carte'),
        const SizedBox(height: 12),
        _MapPinWidget(
          lat: widget.formData['lat'] as double?,
          lng: widget.formData['lng'] as double?,
        ),

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
                '${widget.formData['propertyType']} · ${widget.formData['listingType'] == 'sale' ? 'Vente' : 'Location'}',
              ),
              _SummaryRow(
                'Surface',
                '${widget.formData['surface'].isEmpty ? '—' : widget.formData['surface']} m²',
              ),
              _SummaryRow(
                'Prix',
                widget.formData['price'].isEmpty
                    ? '—'
                    : CurrencyService.instance.format(
                        int.tryParse(widget.formData['price'] as String) ?? 0,
                        isRent: widget.formData['listingType'] == 'rent',
                      ),
              ),
              _SummaryRow(
                'Pièces',
                '${widget.formData['rooms']} pièces · ${widget.formData['bedrooms']} chambres',
              ),
              _SummaryRow(
                'Adresse',
                widget.formData['address'].isEmpty
                    ? '—'
                    : '${widget.formData['address']}, ${widget.formData['zipCode']} ${widget.formData['city']}',
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
    TextEditingController? controller,
    String? initialValue,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          keyboardType: keyboardType,
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
        ),
      ],
    );
  }
}

class _MapPinWidget extends StatelessWidget {
  final double? lat;
  final double? lng;

  const _MapPinWidget({this.lat, this.lng});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          PropertyMiniMapWidget(
            address: '',
            lat: lat,
            lng: lng,
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
