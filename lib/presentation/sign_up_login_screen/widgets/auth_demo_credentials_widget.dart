import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AuthDemoCredentialsWidget extends StatefulWidget {
  final Function(String email, String password) onAutofill;

  const AuthDemoCredentialsWidget({super.key, required this.onAutofill});

  @override
  State<AuthDemoCredentialsWidget> createState() =>
      _AuthDemoCredentialsWidgetState();
}

class _AuthDemoCredentialsWidgetState extends State<AuthDemoCredentialsWidget> {
  int _selectedAccount = 0;

  static const List<Map<String, String>> _accounts = [
    {
      'label': 'Acheteur',
      'icon': 'buyer',
      'email': 'acheteur@zehouse.fr',
      'password': 'Zehouse2026!',
      'name': 'Marie Dupont',
    },
    {
      'label': 'Vendeur',
      'icon': 'seller',
      'email': 'vendeur@zehouse.fr',
      'password': 'Zehouse2026!',
      'name': 'Pierre Martin',
    },
    {
      'label': 'Agent',
      'icon': 'agent',
      'email': 'agent@zehouse.fr',
      'password': 'Zehouse2026!',
      'name': 'Sophie Bernard',
    },
  ];

  IconData _iconForRole(String icon) {
    switch (icon) {
      case 'buyer':
        return Icons.person_search_rounded;
      case 'seller':
        return Icons.sell_rounded;
      case 'agent':
        return Icons.badge_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _accounts[_selectedAccount];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Comptes de test',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Role tabs
          Row(
            children: List.generate(_accounts.length, (i) {
              final acc = _accounts[i];
              final isActive = _selectedAccount == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAccount = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary
                          : AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.primary.withAlpha(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _iconForRole(acc['icon']!),
                          size: 14,
                          color: isActive ? Colors.white : AppTheme.primary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          acc['label']!,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Name
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: AppTheme.muted,
              ),
              const SizedBox(width: 6),
              Text(
                account['name']!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Credentials
          _CredentialRow(label: 'Email', value: account['email']!),
          const SizedBox(height: 6),
          _CredentialRow(
            label: 'Mot de passe',
            value: account['password']!,
            isPassword: true,
          ),
          const SizedBox(height: 10),
          // Autofill button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () =>
                  widget.onAutofill(account['email']!, account['password']!),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary.withAlpha(20),
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Se connecter en tant que ${account['label']}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPassword;

  const _CredentialRow({
    required this.label,
    required this.value,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
          },
          child: Icon(
            Icons.copy_rounded,
            size: 14,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}
