import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/currency_service.dart';

class AddListingModalWidget extends StatefulWidget {
  final VoidCallback onListingAdded;

  const AddListingModalWidget({super.key, required this.onListingAdded});

  @override
  State<AddListingModalWidget> createState() => _AddListingModalWidgetState();
}

class _AddListingModalWidgetState extends State<AddListingModalWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // Form fields
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _latController = TextEditingController(text: '48.8566');
  final _lngController = TextEditingController(text: '2.3522');

  String _listingType = 'sale';
  String _propertyType = 'Appartement';
  int _rooms = 2;

  final List<String> _propertyTypes = [
    'Appartement',
    'Maison',
    'Studio',
    'Loft',
    'Bureau',
    'Duplex',
    'Hôtel',
    'Salle de Fêtes',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _surfaceController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(
        () => _errorMessage =
            'Vous devez être connecté pour publier une annonce.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lat = double.tryParse(_latController.text.trim()) ?? 48.8566;
      final lng = double.tryParse(_lngController.text.trim()) ?? 2.3522;
      final price = int.tryParse(_priceController.text.trim()) ?? 0;
      final surface = double.tryParse(_surfaceController.text.trim()) ?? 0.0;

      await Supabase.instance.client.from('user_listings').insert({
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'address': _addressController.text.trim(),
        'price': price,
        'surface': surface,
        'rooms': _rooms,
        'listing_type': _listingType,
        'property_type': _propertyType,
        'description': '',
        'image_url':
            'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
        'lat': lat,
        'lng': lng,
        'is_active': true,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onListingAdded();
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage = 'Une erreur est survenue. Veuillez réessayer.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_location_alt_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Nouvelle annonce',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Listing type toggle
                    _SectionLabel(label: 'Type d\'annonce'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeToggleButton(
                            label: 'Vente',
                            icon: Icons.sell_rounded,
                            isSelected: _listingType == 'sale',
                            color: AppTheme.primary,
                            onTap: () => setState(() => _listingType = 'sale'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeToggleButton(
                            label: 'Location',
                            icon: Icons.key_rounded,
                            isSelected: _listingType == 'rent',
                            color: AppTheme.info,
                            onTap: () => setState(() => _listingType = 'rent'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Property type
                    _SectionLabel(label: 'Catégorie'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _propertyType,
                      decoration: _inputDecoration('Type de bien'),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      items: _propertyTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _propertyType = v ?? _propertyType),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    _SectionLabel(label: 'Titre'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: _inputDecoration(
                        'Ex: Appartement lumineux 3 pièces',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Titre requis'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Address
                    _SectionLabel(label: 'Adresse'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: _inputDecoration(
                        'Ex: 12 Rue de la Paix, Paris',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Adresse requise'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Price & Surface
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(
                                label:
                                    'Prix (${CurrencyService.instance.currentCurrency.symbol})',
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: _inputDecoration('Ex: 350000'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Requis';
                                  }
                                  if (int.tryParse(v.trim()) == null) {
                                    return 'Invalide';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(label: 'Surface (m²)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _surfaceController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: _inputDecoration('Ex: 65'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Requis';
                                  }
                                  if (double.tryParse(v.trim()) == null) {
                                    return 'Invalide';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Rooms
                    _SectionLabel(label: 'Pièces: $_rooms'),
                    Slider(
                      value: _rooms.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: AppTheme.primary,
                      inactiveColor: AppTheme.border,
                      label: '$_rooms pièce${_rooms > 1 ? 's' : ''}',
                      onChanged: (v) => setState(() => _rooms = v.round()),
                    ),
                    const SizedBox(height: 14),

                    // Coordinates
                    _SectionLabel(label: 'Position sur la carte'),
                    const SizedBox(height: 4),
                    Text(
                      'Entrez les coordonnées GPS pour placer le pin sur la carte',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: _inputDecoration('Latitude'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Requis';
                              }
                              if (double.tryParse(v.trim()) == null) {
                                return 'Invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: _inputDecoration('Longitude'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Requis';
                              }
                              if (double.tryParse(v.trim()) == null) {
                                return 'Invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitListing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Publier l\'annonce',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
      filled: true,
      fillColor: AppTheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(18) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : AppTheme.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
