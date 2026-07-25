import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/app_export.dart';
import '../../services/language_service.dart';
import './widgets/auth_form_widget.dart';
import './widgets/auth_role_selector_widget.dart';
import './widgets/auth_social_buttons_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  String _selectedRole = 'particulier';
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  final _formKey = GlobalKey<AuthFormWidgetState>();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _toggleTheme() async {
    final currentMode = AppTheme.themeModeNotifier.value;
    ThemeMode newMode;
    if (currentMode == ThemeMode.light) {
      newMode = ThemeMode.dark;
    } else {
      newMode = ThemeMode.light;
    }
    
    AppTheme.themeModeNotifier.value = newMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.6)),
    );
    _logoController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LanguageService.instance.setContext(context);
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _onSubmit(
    String email,
    String password,
    String? fullName,
    String? phone,
    Uint8List? profilePhotoBytes,
    String? profession,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        final response = await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        if (response.user != null && mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.mapScreen,
            (route) => false,
          );
        }
      } else {
        final response = await _client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {
            'full_name': fullName ?? '',
            'role': _selectedRole,
            'phone': phone ?? '',
          },
        );
        if (response.user != null) {
          // Upload profile photo if provided
          String? avatarUrl;
          if (profilePhotoBytes != null) {
            try {
              final fileName =
                  'avatar_${response.user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
              await _client.storage
                  .from('avatars')
                  .uploadBinary(fileName, profilePhotoBytes);
              avatarUrl = _client.storage
                  .from('avatars')
                  .getPublicUrl(fileName);
            } catch (_) {}
          }

          // Upsert profile with role
          await _client.from('user_profiles').upsert({
            'id': response.user!.id,
            'email': email.trim(),
            'full_name': fullName ?? '',
            'role': _selectedRole,
            'phone': phone ?? '',
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            if (profession != null && profession.isNotEmpty)
              'profession': profession,
            'is_verified': false,
          });

          if (mounted) {
            _showEmailVerificationDialog(email);
          }
        }
      }
    } on AuthException catch (e) {
      debugPrint('[AuthException during Login/SignUp]: ${e.message} (Status: ${e.statusCode})');
      if (mounted) {
        setState(() => _errorMessage = '${_translateAuthError(e.message)} (${e.message})');
      }
    } catch (e) {
      debugPrint('[Generic Exception during Login/SignUp]: $e');
      if (mounted) {
        setState(() => _errorMessage = '${tr('auth_generic_error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 32,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('email_verify_title'),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              tr('email_verify_body', namedArgs: {'email': email}),
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.mapScreen,
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  tr('btn_understood'),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onForgotPassword(String email) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = tr('email_reset_enter'));
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('email_reset_sent', namedArgs: {'email': email}),
              style: GoogleFonts.outfit(fontSize: 13),
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      debugPrint('[AuthException during ForgotPassword]: ${e.message}');
      if (mounted) {
        setState(() => _errorMessage = '${_translateAuthError(e.message)} (${e.message})');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'https://zehouse2471.builtwithrocket.new',
        );
      } else {
        const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
        final googleSignIn = GoogleSignIn(serverClientId: webClientId);
        GoogleSignInAccount? user = await googleSignIn.signInSilently();
        user ??= await googleSignIn.signIn();
        if (user == null) {
          setState(() => _isGoogleLoading = false);
          return;
        }
        final googleAuth = await user.authentication;
        final idToken = googleAuth.idToken;
        if (idToken == null) throw AuthException('No ID Token found.');
        final response = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: googleAuth.accessToken,
        );
        if (response.user != null) {
          // Check if user profile already exists
          try {
            final profile = await _client
                .from('user_profiles')
                .select()
                .eq('id', response.user!.id)
                .maybeSingle();

            if (profile == null) {
              final fullName = response.user!.userMetadata?['full_name'] as String? ?? '';
              final avatarUrl = response.user!.userMetadata?['avatar_url'] as String? ?? '';

              await _client.from('user_profiles').insert({
                'id': response.user!.id,
                'email': response.user!.email ?? '',
                'full_name': fullName,
                'avatar_url': avatarUrl,
                'role': _selectedRole,
                'phone': '',
                'is_verified': false,
              });
            }
          } catch (profileError) {
            debugPrint('[Google Sign-In Profile Creation Error]: $profileError');
          }

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.mapScreen,
              (route) => false,
            );
          }
        }
      }
    } on AuthException catch (e) {
      debugPrint('[AuthException during GoogleSignIn]: ${e.message}');
      if (mounted) {
        setState(() => _errorMessage = '${_translateAuthError(e.message)} (${e.message})');
      }
    } catch (e) {
      debugPrint('[Generic Exception during GoogleSignIn]: $e');
      if (mounted) {
        setState(() => _errorMessage = '${tr('auth_google_failed')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _translateAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('invalid_credentials')) {
      return tr('auth_error_invalid_credentials');
    }
    if (m.contains('email already registered') ||
        m.contains('already registered')) {
      return tr('auth_error_email_taken');
    }
    if (m.contains('password should be at least')) {
      return tr('auth_error_password_too_short');
    }
    if (m.contains('unable to validate email address')) {
      return tr('auth_error_invalid_email');
    }
    if (m.contains('email rate limit exceeded')) {
      return tr('auth_error_rate_limit');
    }
    if (m.contains('user not found')) {
      return tr('auth_error_user_not_found');
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            isTablet
                ? Center(child: SizedBox(width: 480, child: _buildContent()))
                : SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: _buildContent(),
                    ),
                  ),
            // Theme toggle button top-left
            Positioned(
              top: 8,
              left: 12,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.themeModeNotifier,
                builder: (context, themeMode, _) {
                  final isCurrentlyDark = AppTheme.isDark;
                  return GestureDetector(
                    onTap: _toggleTheme,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Icon(
                        isCurrentlyDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Language picker button top-right
            Positioned(
              top: 8,
              right: 12,
              child: ListenableBuilder(
                listenable: LanguageService.instance,
                builder: (context, _) {
                  final lang = LanguageService.instance.currentLanguage;
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.languageSelectionScreen,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang.flag, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            lang.code.toUpperCase().substring(0, 2),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: AppTheme.muted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),

          // Logo
          AnimatedBuilder(
            animation: _logoController,
            builder: (_, child) => Opacity(
              opacity: _logoOpacity.value,
              child: Transform.scale(scale: _logoScale.value, child: child),
            ),
            child: Column(
              children: [
                CustomImageWidget(
                  imageUrl: 'assets/images/logo_simple.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  semanticLabel: 'Logo ZeHouse',
                ),
                const SizedBox(height: 12),
                Text(
                  tr('app_name'),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  tr('app_tagline'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Tab toggle
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: tr('auth_login'),
                  isActive: _isLogin,
                  onTap: () => setState(() {
                    _isLogin = true;
                    _errorMessage = null;
                  }),
                ),
                _TabButton(
                  label: tr('auth_signup'),
                  isActive: !_isLogin,
                  onTap: () => setState(() {
                    _isLogin = false;
                    _errorMessage = null;
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Role selector (only on signup)
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tr('auth_i_am'),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (AuthRoleSelectorWidget.isProfessional(_selectedRole))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tr('auth_verification_required'),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AuthRoleSelectorWidget(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) => setState(() => _selectedRole = role),
                ),
                const SizedBox(height: 24),
              ],
            ),
            crossFadeState: _isLogin
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Form
          AuthFormWidget(
            key: _formKey,
            isLogin: _isLogin,
            isLoading: _isLoading,
            selectedRole: _selectedRole,
            onSubmit: _onSubmit,
            onForgotPassword: _onForgotPassword,
          ),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr('auth_or_continue_with'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.muted,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 20),

          // Social buttons
          AuthSocialButtonsWidget(
            onGoogleTap: _onGoogleSignIn,
            isGoogleLoading: _isGoogleLoading,
          ),

          const SizedBox(height: 24),

          // Switch mode
          RichText(
            text: TextSpan(
              text: _isLogin
                  ? '${tr('auth_already_account')} '
                  : '${tr('auth_no_account')} ',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              children: [
                TextSpan(
                  text: _isLogin ? tr('auth_register') : tr('auth_sign_in'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                    }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Copyright
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              tr('copyright'),
              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
