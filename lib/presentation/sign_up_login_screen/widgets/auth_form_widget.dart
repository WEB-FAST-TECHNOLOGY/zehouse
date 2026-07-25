import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import './auth_role_selector_widget.dart';

class AuthFormWidget extends StatefulWidget {
  final bool isLogin;
  final bool isLoading;
  final String selectedRole;
  final Function(
    String email,
    String password,
    String? fullName,
    String? phone,
    Uint8List? profilePhotoBytes,
    String? profession,
  )
  onSubmit;
  final Function(String email)? onForgotPassword;

  const AuthFormWidget({
    super.key,
    required this.isLogin,
    required this.isLoading,
    required this.selectedRole,
    required this.onSubmit,
    this.onForgotPassword,
  });

  @override
  State<AuthFormWidget> createState() => AuthFormWidgetState();
}

class AuthFormWidgetState extends State<AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoName;
  String? _selectedProfession;

  // Professions per role — labels now use translation keys
  static const Map<String, List<Map<String, dynamic>>> _professionsByRole = {
    'particulier': [
      {
        'id': 'acheteur',
        'labelKey': 'profession_acheteur',
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'id': 'locataire',
        'labelKey': 'profession_locataire',
        'icon': Icons.key_outlined,
      },
      {
        'id': 'investisseur',
        'labelKey': 'profession_investisseur',
        'icon': Icons.trending_up_rounded,
      },
      {
        'id': 'autre',
        'labelKey': 'profession_autre',
        'icon': Icons.person_outline_rounded,
      },
    ],
    'professionnel': [
      {
        'id': 'architecte',
        'labelKey': 'profession_architecte',
        'icon': Icons.architecture_rounded,
      },
      {
        'id': 'ingenieur',
        'labelKey': 'profession_ingenieur',
        'icon': Icons.engineering_rounded,
      },
      {
        'id': 'promoteur',
        'labelKey': 'profession_promoteur',
        'icon': Icons.apartment_rounded,
      },
      {
        'id': 'notaire',
        'labelKey': 'profession_notaire',
        'icon': Icons.gavel_rounded,
      },
      {
        'id': 'geometre',
        'labelKey': 'profession_geometre',
        'icon': Icons.straighten_rounded,
      },
      {
        'id': 'entrepreneur',
        'labelKey': 'profession_entrepreneur',
        'icon': Icons.construction_rounded,
      },
      {
        'id': 'designer',
        'labelKey': 'profession_designer',
        'icon': Icons.design_services_rounded,
      },
      {
        'id': 'expert_immobilier',
        'labelKey': 'profession_expert_immobilier',
        'icon': Icons.find_in_page_rounded,
      },
      {
        'id': 'juriste',
        'labelKey': 'profession_juriste',
        'icon': Icons.balance_rounded,
      },
      {
        'id': 'autre_pro',
        'labelKey': 'profession_autre_pro',
        'icon': Icons.business_center_rounded,
      },
    ],
    'agent': [
      {
        'id': 'agent_immobilier',
        'labelKey': 'profession_agent_immobilier',
        'icon': Icons.badge_rounded,
      },
      {
        'id': 'courtier',
        'labelKey': 'profession_courtier',
        'icon': Icons.handshake_rounded,
      },
      {
        'id': 'mandataire',
        'labelKey': 'profession_mandataire',
        'icon': Icons.assignment_ind_rounded,
      },
      {
        'id': 'gestionnaire',
        'labelKey': 'profession_gestionnaire',
        'icon': Icons.manage_accounts_rounded,
      },
    ],
    'proprietaire': [
      {
        'id': 'bailleur',
        'labelKey': 'profession_bailleur',
        'icon': Icons.home_rounded,
      },
      {
        'id': 'vendeur',
        'labelKey': 'profession_vendeur',
        'icon': Icons.sell_rounded,
      },
      {
        'id': 'promoteur_prive',
        'labelKey': 'profession_promoteur_prive',
        'icon': Icons.villa_rounded,
      },
      {
        'id': 'sci',
        'labelKey': 'profession_sci',
        'icon': Icons.business_rounded,
      },
    ],
  };

  List<Map<String, dynamic>> get _currentProfessions =>
      _professionsByRole[widget.selectedRole] ?? [];

  // Password strength indicators
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSymbol => _passwordController.text.contains(
    RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'),
  );

  bool get _isProfessional =>
      AuthRoleSelectorWidget.isProfessional(widget.selectedRole);

  void autofill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full name (signup only)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  controller: _nameController,
                  label: tr('field_full_name'),
                  hint: tr('field_full_name_hint'),
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (widget.isLogin) return null;
                    return v == null || v.isEmpty
                        ? tr('field_full_name_required')
                        : null;
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
            crossFadeState: widget.isLogin
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          // Email
          _buildField(
            controller: _emailController,
            label: tr('field_email'),
            hint: tr('field_email_hint'),
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return tr('field_email_required');
              if (!v.contains('@')) return tr('field_email_invalid');
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Phone (signup only, mandatory for professionals)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  controller: _phoneController,
                  label: _isProfessional
                      ? tr('field_phone_pro')
                      : tr('field_phone'),
                  hint: tr('field_phone_hint'),
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (widget.isLogin) return null;
                    if (_isProfessional && (v == null || v.trim().isEmpty)) {
                      return tr('field_phone_required_pro');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
            crossFadeState: widget.isLogin
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          // Password
          _buildField(
            controller: _passwordController,
            label: tr('field_password'),
            hint: tr('field_password_hint'),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppTheme.muted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return tr('field_password_required');
              if (!widget.isLogin) {
                if (v.length < 8) return tr('field_password_min');
                if (!_hasUppercase) return tr('field_password_uppercase');
                if (!_hasNumber) return tr('field_password_number');
                if (!_hasSymbol) return tr('field_password_symbol');
              }
              return null;
            },
          ),

          // Password strength indicators (signup only)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildPasswordStrength(),
            ),
            crossFadeState: widget.isLogin
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          if (widget.isLogin) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  widget.onForgotPassword?.call(_emailController.text);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  tr('field_forgot_password'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // Profession selector (signup only)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildProfessionSelector(),
              ],
            ),
            crossFadeState: widget.isLogin
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          // Profile photo (signup + professional only)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildProfilePhotoSection(),
              ],
            ),
            crossFadeState: (!widget.isLogin && _isProfessional)
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // CGU consent (signup only)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [const SizedBox(height: 20), _buildConsentCheckbox()],
            ),
            crossFadeState: widget.isLogin
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      debugPrint('Submit button pressed. isLogin: ${widget.isLogin}, isLoading: ${widget.isLoading}');
                      FocusScope.of(context).unfocus(); // Ferme le clavier pour voir le formulaire
                      if (_formKey.currentState == null) {
                        debugPrint('Form state is null!');
                        return;
                      }
                      final isValid = _formKey.currentState!.validate();
                      debugPrint('Form validation result: $isValid');
                      if (!isValid) {
                        debugPrint('Form validation failed. Reasons:');
                        final errors = <String>[];
                        if (_emailController.text.isEmpty) {
                          errors.add(tr('field_email_required'));
                        } else if (!_emailController.text.contains('@')) {
                          errors.add(tr('field_email_invalid'));
                        }
                        if (_passwordController.text.isEmpty) {
                          errors.add(tr('field_password_required'));
                        } else if (!widget.isLogin) {
                          if (_passwordController.text.length < 8) errors.add(tr('field_password_min'));
                          if (!_hasUppercase) errors.add(tr('field_password_uppercase'));
                          if (!_hasNumber) errors.add(tr('field_password_number'));
                          if (!_hasSymbol) errors.add(tr('field_password_symbol'));
                        }
                        if (!widget.isLogin) {
                          if (_nameController.text.isEmpty) errors.add(tr('field_full_name_required'));
                          if (_isProfessional && _phoneController.text.trim().isEmpty) errors.add(tr('field_phone_required_pro'));
                        }
                        
                        for (final err in errors) {
                          debugPrint('  - $err');
                        }

                        if (errors.isNotEmpty) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                errors.first,
                                style: GoogleFonts.outfit(fontSize: 13),
                              ),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      if (!widget.isLogin && !_acceptedTerms) {
                        debugPrint('Validation passed, but Terms not accepted.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr('cgu_required'),
                              style: GoogleFonts.outfit(fontSize: 13),
                            ),
                            backgroundColor: AppTheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      if (!widget.isLogin &&
                          _isProfessional &&
                          _profilePhotoBytes == null) {
                        debugPrint('Validation passed, but profile photo missing for Professional.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              tr('photo_required_pro'),
                              style: GoogleFonts.outfit(fontSize: 13),
                            ),
                            backgroundColor: AppTheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      debugPrint('Form validation succeeded. Calling onSubmit callback...');
                      widget.onSubmit(
                        _emailController.text.trim(),
                        _passwordController.text,
                        widget.isLogin ? null : _nameController.text,
                        widget.isLogin ? null : _phoneController.text.trim(),
                        widget.isLogin ? null : _profilePhotoBytes,
                        widget.isLogin ? null : _selectedProfession,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: AppTheme.primary.withAlpha(153),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      widget.isLogin
                          ? tr('btn_login')
                          : tr('btn_create_account'),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionSelector() {
    final professions = _currentProfessions;
    if (professions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_outline_rounded, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              tr('profession_title'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              tr('profession_optional'),
              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: professions.map((prof) {
            final isSelected = _selectedProfession == prof['id'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProfession = isSelected
                      ? null
                      : prof['id'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      prof['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : AppTheme.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr(prof['labelKey'] as String),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('password_strength'),
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _StrengthChip(label: tr('password_8chars'), met: _hasMinLength),
            _StrengthChip(label: tr('password_uppercase'), met: _hasUppercase),
            _StrengthChip(label: tr('password_number'), met: _hasNumber),
            _StrengthChip(label: tr('password_symbol'), met: _hasSymbol),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePhotoSection() {
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
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 28,
                        color: AppTheme.muted,
                      ),
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

  Widget _buildConsentCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _acceptedTerms ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _acceptedTerms ? AppTheme.primary : AppTheme.border,
                width: 2,
              ),
            ),
            child: _acceptedTerms
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: tr('cgu_accept'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: tr('cgu_terms'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushNamed(context, AppRoutes.termsScreen);
                      },
                  ),
                  TextSpan(
                    text: tr('cgu_and'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: tr('cgu_privacy'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushNamed(context, AppRoutes.termsScreen);
                      },
                  ),
                  TextSpan(
                    text: tr('cgu_of'),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.outfit(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.muted),
        suffixIcon: suffixIcon,
        labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.muted),
        hintStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: AppTheme.muted.withAlpha(153),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _StrengthChip extends StatelessWidget {
  final String label;
  final bool met;

  const _StrengthChip({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: met ? AppTheme.successLight : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: met ? AppTheme.success : AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 11,
            color: met ? AppTheme.success : AppTheme.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: met ? AppTheme.success : AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}
