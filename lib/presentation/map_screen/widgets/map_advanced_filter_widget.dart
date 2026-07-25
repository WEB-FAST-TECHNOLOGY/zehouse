import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MapFilterState {
  final RangeValues priceRange;
  final RangeValues surfaceRange;
  final int? minRooms;
  final String? propertyType;
  final String listingType; // 'all', 'sale', 'rent'
  final bool onlyAroundMe;

  const MapFilterState({
    this.priceRange = const RangeValues(0, 5000000),
    this.surfaceRange = const RangeValues(0, 500),
    this.minRooms,
    this.propertyType,
    this.listingType = 'all',
    this.onlyAroundMe = true,
  });

  MapFilterState copyWith({
    RangeValues? priceRange,
    RangeValues? surfaceRange,
    int? minRooms,
    String? propertyType,
    String? listingType,
    bool? onlyAroundMe,
    bool clearMinRooms = false,
    bool clearPropertyType = false,
  }) {
    return MapFilterState(
      priceRange: priceRange ?? this.priceRange,
      surfaceRange: surfaceRange ?? this.surfaceRange,
      minRooms: clearMinRooms ? null : (minRooms ?? this.minRooms),
      propertyType: clearPropertyType
          ? null
          : (propertyType ?? this.propertyType),
      listingType: listingType ?? this.listingType,
      onlyAroundMe: onlyAroundMe ?? this.onlyAroundMe,
    );
  }

  bool get isDefault =>
      priceRange.start == 0 &&
      priceRange.end == 5000000 &&
      surfaceRange.start == 0 &&
      surfaceRange.end == 500 &&
      minRooms == null &&
      propertyType == null &&
      listingType == 'all' &&
      onlyAroundMe == true;

  bool matchesProperty(Map<String, dynamic> property) {
    final price = (property['price'] as num).toDouble();
    final surface = (property['surface'] as num).toDouble();
    final rooms = property['rooms'] as int;
    final type = property['type'] as String;
    final lType = property['listingType'] as String;

    // Price filter
    if (price < priceRange.start || price > priceRange.end) return false;

    // Surface filter (skip for services with 0 surface)
    if (surface > 0 &&
        (surface < surfaceRange.start || surface > surfaceRange.end)) {
      return false;
    }

    // Rooms filter
    if (minRooms != null && rooms > 0 && rooms < minRooms!) return false;

    // Property type filter
    if (propertyType != null &&
        propertyType!.isNotEmpty &&
        type != propertyType) {
      return false;
    }

    // Listing type filter
    if (listingType == 'sale' && lType != 'sale') return false;
    if (listingType == 'rent' && lType != 'rent') return false;

    return true;
  }
}

class MapAdvancedFilterWidget extends StatefulWidget {
  final MapFilterState currentFilter;
  final Function(MapFilterState) onApply;

  const MapAdvancedFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<MapAdvancedFilterWidget> createState() =>
      _MapAdvancedFilterWidgetState();
}

class _MapAdvancedFilterWidgetState extends State<MapAdvancedFilterWidget> {
  late MapFilterState _filter;

  static const List<String> _propertyTypes = [
    'Appartement',
    'Maison',
    'Studio',
    'Loft',
    'Duplex',
    'Hôtel',
    'Appt. Meublé',
    'Camping-car',
    'Salle de Fêtes',
    'Bureau',
    'Déménagement',
    'Entretien',
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  String _formatPrice(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M€';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k€';
    return '${value.toStringAsFixed(0)}€';
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres avancés',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _filter = const MapFilterState());
                  },
                  child: Text(
                    'Réinitialiser',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing type
                  _SectionTitle('Type de transaction'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TypeChip(
                        label: 'Tous',
                        isSelected: _filter.listingType == 'all',
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(listingType: 'all'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Acheter',
                        isSelected: _filter.listingType == 'sale',
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(listingType: 'sale'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Louer',
                        isSelected: _filter.listingType == 'rent',
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(listingType: 'rent'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Around me switch
                  _SectionTitle('Géolocalisation'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Autour de moi (< 25 km)',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Switch(
                        value: _filter.onlyAroundMe,
                        activeColor: AppTheme.accent,
                        activeTrackColor: AppTheme.accent.withAlpha(80),
                        inactiveThumbColor: AppTheme.muted,
                        inactiveTrackColor: AppTheme.border,
                        onChanged: (val) {
                          setState(() {
                            _filter = _filter.copyWith(onlyAroundMe: val);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle('Fourchette de prix'),
                      Text(
                        '${_formatPrice(_filter.priceRange.start)} – ${_formatPrice(_filter.priceRange.end)}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _filter.priceRange,
                    min: 0,
                    max: 5000000,
                    divisions: 100,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.border,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(priceRange: v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Surface range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle('Surface (m²)'),
                      Text(
                        '${_filter.surfaceRange.start.toStringAsFixed(0)} – ${_filter.surfaceRange.end.toStringAsFixed(0)} m²',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _filter.surfaceRange,
                    min: 0,
                    max: 500,
                    divisions: 50,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.border,
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(surfaceRange: v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rooms
                  _SectionTitle('Nombre de pièces minimum'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RoomChip(
                        label: 'Tous',
                        isSelected: _filter.minRooms == null,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(clearMinRooms: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (final r in [1, 2, 3, 4, 5]) ...[
                        _RoomChip(
                          label: r == 5 ? '5+' : '$r',
                          isSelected: _filter.minRooms == r,
                          onTap: () => setState(
                            () => _filter = _filter.copyWith(minRooms: r),
                          ),
                        ),
                        if (r < 5) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Property type
                  _SectionTitle('Type de bien'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TypeChip(
                        label: 'Tous',
                        isSelected: _filter.propertyType == null,
                        onTap: () => setState(
                          () => _filter = _filter.copyWith(
                            clearPropertyType: true,
                          ),
                        ),
                      ),
                      ..._propertyTypes.map(
                        (t) => _TypeChip(
                          label: t,
                          isSelected: _filter.propertyType == t,
                          onTap: () => setState(
                            () => _filter = _filter.copyWith(propertyType: t),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_filter);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Appliquer les filtres',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoomChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
