import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import './auth_role_selector_widget.dart';

/// Screen shown after Google Sign-In when the user has no existing profile.
/// Collects: role, full name (pre-filled from Google), phone, profession, photo (if professional).
class GoogleProfileCompletionScreen extends StatefulWidget {
  /// Data already known from Google account
  final String googleFullName;
  final String googleAvatarUrl;
  final String userId;
  final String email;

  const GoogleProfileCompletionScreen({
    super.key,
    required this.googleFullName,
    required this.googleAvatarUrl,
    required this.userId,
    required this.email,
  });

  @override
  State<GoogleProfileCompletionScreen> createState() =>
      _GoogleProfileCompletionScreenState();
}

class _GoogleProfileCompletionScreenState
    extends State<GoogleProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'particulier';
  String? _selectedProfession;
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoName;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isProfessional =>
      AuthRoleSelectorWidget.isProfessional(_selectedRole);

  SupabaseClient get _client => Supabase.instance.client;

  static const Map<String, List<Map<String, dynamic>>> _professionsByRole = {
    'particulier': [
      {'id': 'acheteur', 'labelKey': 'profession_acheteur', 'icon': Icons.shopping_bag_outlined},
      {'id': 'locataire', 'labelKey': 'profession_locataire', 'icon': Icons.key_outlined},
      {'id': 'investisseur', 'labelKey': 'profession_investisseur', 'icon': Icons.trending_up_rounded},
      {'id': 'autre', 'labelKey': 'profession_autre', 'icon': Icons.person_outline_rounded},
    ],
    'professionnel': [
      {'id': 'architecte', 'labelKey': 'profession_architecte', 'icon': Icons.architecture_rounded},
      {'id': 'ingenieur', 'labelKey': 'profession_ingenieur', 'icon': Icons.engineering_rounded},
      {'id': 'promoteur', 'labelKey': 'profession_promoteur', 'icon': Icons.apartment_rounded},
      {'id': 'notaire', 'labelKey': 'profession_notaire', 'icon': Icons.gavel_rounded},
      {'id': 'geometre', 'labelKey': 'profession_geometre', 'icon': Icons.straighten_rounded},
      {'id': 'entrepreneur', 'labelKey': 'profession_entrepreneur', 'icon': Icons.construction_rounded},
      {'id': 'designer', 'labelKey': 'profession_designer', 'icon': Icons.design_services_rounded},
      {'id': 'expert_immobilier', 'labelKey': 'profession_expert_immobilier', 'icon': Icons.find_in_page_rounded},
      {'id': 'juriste', 'labelKey': 'profession_juriste', 'icon': Icons.balance_rounded},
      {'id': 'autre_pro', 'labelKey': 'profession_autre_pro', 'icon': Icons.business_center_rounded},
    ],
    'agent': [
      {'id': 'agent_immobilier', 'labelKey': 'profession_agent_immobilier', 'icon': Icons.badge_rounded},
      {'id': 'courtier', 'labelKey': 'profession_courtier', 'icon': Icons.handshake_rounded},
      {'id': 'mandataire', 'labelKey': 'profession_mandataire', 'icon': Icons.assignment_ind_rounded},
      {'id': 'gestionnaire', 'labelKey': 'profession_gestionnaire', 'icon': Icons.manage_accounts_rounded},
    ],
    'proprietaire': [
      {'id': 'bailleur', 'labelKey': 'profession_bailleur', 'icon': Icons.home_rounded},
      {'id': 'vendeur', 'labelKey': 'profession_vendeur', 'icon': Icons.sell_rounded},
      {'id': 'promoteur_prive', 'labelKey': 'profession_promoteur_prive', 'icon': Icons.villa_rounded},
      {'id': 'sci', 'labelKey': 'profession_sci', 'icon': Icons.business_rounded},
    ],
  };

  List<Map<String, dynamic>> get _currentProfessions =>
      _professionsByRole[_selectedRole] ?? [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.googleFullName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profilePhotoBytes = bytes;
          _profilePhotoName = picked.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // For professionals, phone is mandatory
    if (_isProfessional && _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('field_phone_required_pro'), style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    // For professionals, photo is mandatory
    if (_isProfessional && _profilePhotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('photo_required_pro'), style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload photo if provided (overrides Google avatar for professionals)
      String? avatarUrl = widget.googleAvatarUrl.isNotEmpty
          ? widget.googleAvatarUrl
          : null;

      if (_profilePhotoBytes != null) {
        final fileName =
            'avatar_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _client.storage
            .from('avatars')
            .uploadBinary(fileName, _profilePhotoBytes!);
        avatarUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      }

      // Create / update the profile
      await _client.from('user_profiles').upsert({
        'id': widget.userId,
        'email': widget.email,
        'full_name': _nameController.text.trim(),
        'role': _selectedRole,
        'phone': _phoneController.text.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (_selectedProfession != null && _selectedProfession!.isNotEmpty)
          'profession': _selectedProfession,
        'is_verified': false,
      });

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mapScreen,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('[GoogleProfileCompletion] Error: $e');
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      // Google avatar preview
                      if (widget.googleAvatarUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(widget.googleAvatarUrl),
                        )
                      else
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primary.withAlpha(30),
                          child: Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppTheme.primary,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        tr('google_complete_title'),
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('google_complete_subtitle'),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Role selector ────────────────────────────────────────────
                Text(
                  tr('role_title'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                AuthRoleSelectorWidget(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) => setState(() {
                    _selectedRole = role;
                    _selectedProfession = null;
                  }),
                ),

                const SizedBox(height: 24),

                // ── Full name ────────────────────────────────────────────────
                _buildField(
                  controller: _nameController,
                  label: tr('field_full_name'),
                  hint: tr('field_full_name_hint'),
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? tr('field_full_name_required') : null,
                ),

                const SizedBox(height: 20),

                // ── Phone ────────────────────────────────────────────────────
                _buildField(
                  controller: _phoneController,
                  label: _isProfessional
                      ? tr('field_phone_pro')
                      : tr('field_phone'),
                  hint: tr('field_phone_hint'),
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (_) => null, // validated manually above
                ),

                const SizedBox(height: 24),

                // ── Profession selector ──────────────────────────────────────
                if (_currentProfessions.isNotEmpty) ...[
                  Text(
                    tr('profession_title'),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentProfessions.map((prof) {
                      final isSelected = _selectedProfession == prof['id'];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedProfession =
                              isSelected ? null : prof['id'] as String;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                prof['icon'] as IconData,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tr(prof['labelKey'] as String),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Profile photo (professionals only) ───────────────────────
                if (_isProfessional) ...[
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                ],

                // ── Error message ────────────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.error.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: AppTheme.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Submit button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      disabledBackgroundColor: AppTheme.primary.withAlpha(153),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            tr('google_complete_btn'),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip link
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.mapScreen,
                              (route) => false,
                            ),
                    child: Text(
                      tr('google_complete_skip'),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.muted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.muted),
        labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              tr('photo_profile'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tr('photo_required'),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickProfilePhoto,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _profilePhotoBytes != null
                    ? AppTheme.success
                    : AppTheme.border,
                width: _profilePhotoBytes != null ? 2 : 1,
              ),
            ),
            child: _profilePhotoBytes != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.memory(
                          _profilePhotoBytes!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('photo_selected'),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success,
                              ),
                            ),
                            Text(
                              _profilePhotoName ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppTheme.muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 20),
                      const SizedBox(width: 12),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 28, color: AppTheme.muted),
                      const SizedBox(height: 6),
                      Text(
                        tr('photo_add'),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        tr('photo_format'),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
