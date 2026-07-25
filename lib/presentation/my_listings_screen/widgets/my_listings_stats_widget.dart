import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MyListingsStatsWidget extends StatelessWidget {
  final int activeListings;
  final int totalViews;
  final int totalContacts;
  final int newInquiries;

  const MyListingsStatsWidget({
    super.key,
    required this.activeListings,
    required this.totalViews,
    required this.totalContacts,
    required this.newInquiries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _StatCard(
            value: activeListings.toString(),
            label: 'Actives',
            icon: Icons.home_work_rounded,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: totalViews.toString(),
            label: 'Vues',
            icon: Icons.visibility_rounded,
            color: AppTheme.info,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: totalContacts.toString(),
            label: 'Contacts',
            icon: Icons.people_rounded,
            color: AppTheme.success,
          ),
          const SizedBox(width: 10),
          _StatCard(
            value: newInquiries.toString(),
            label: 'Nouveaux',
            icon: Icons.notifications_rounded,
            color: AppTheme.accent,
            isAlert: newInquiries > 0,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isAlert ? color.withAlpha(20) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isAlert ? Border.all(color: color.withAlpha(77)) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isAlert ? color : AppTheme.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
