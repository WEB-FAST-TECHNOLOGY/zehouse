import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AuthRoleSelectorWidget extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;

  const AuthRoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  static const List<Map<String, dynamic>> _roles = [
    {
      'id': 'particulier',
      'label': 'Particulier',
      'icon': Icons.person_rounded,
      'description': 'Acheteur / Locataire',
    },
    {
      'id': 'professionnel',
      'label': 'Professionnel',
      'icon': Icons.business_center_rounded,
      'description': 'Architecte / Promoteur',
    },
    {
      'id': 'agent',
      'label': 'Agent',
      'icon': Icons.badge_rounded,
      'description': 'Agent immobilier',
    },
    {
      'id': 'proprietaire',
      'label': 'Propriétaire',
      'icon': Icons.home_work_rounded,
      'description': 'Bailleur / Vendeur',
    },
  ];

  static bool isProfessional(String role) =>
      role == 'professionnel' || role == 'agent';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: _roles.sublist(0, 2).map((role) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RoleCard(
                  role: role,
                  isSelected: selectedRole == role['id'],
                  onTap: () => onRoleChanged(role['id'] as String),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: _roles.sublist(2, 4).map((role) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RoleCard(
                  role: role,
                  isSelected: selectedRole == role['id'],
                  onTap: () => onRoleChanged(role['id'] as String),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final Map<String, dynamic> role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              role['icon'] as IconData,
              size: 22,
              color: isSelected ? Colors.white : AppTheme.muted,
            ),
            const SizedBox(height: 4),
            Text(
              role['label'] as String,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              role['description'] as String,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: isSelected
                    ? Colors.white.withAlpha(180)
                    : AppTheme.muted,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
