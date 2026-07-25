import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.border.withOpacity(AppTheme.isDark ? 0.2 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppTheme.isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (AppTheme.isDark)
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.03),
              blurRadius: 40,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: AppTheme.surface.withOpacity(AppTheme.isDark ? 0.75 : 0.85),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: tr('nav_map'),
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: tr('nav_messages'),
                  badge: 3,
                ),
                _buildMiddlePublishButton(context),
                _buildNavItem(
                  context: context,
                  index: 4,
                  icon: Icons.home_work_outlined,
                  activeIcon: Icons.home_work_rounded,
                  label: tr('nav_listings'),
                ),
                _buildNavItem(
                  context: context,
                  index: 5,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: tr('nav_profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiddlePublishButton(BuildContext context) {
    final bool isActive = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive
                ? [AppTheme.accent, AppTheme.accent.withBlue(255)]
                : [AppTheme.primary, AppTheme.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? AppTheme.accent : AppTheme.primary).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            if (AppTheme.isDark)
              BoxShadow(
                color: (isActive ? AppTheme.accent : AppTheme.primary).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(AppTheme.isDark ? 0.3 : 0.6),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badge,
  }) {
    final bool isActive = currentIndex == index;
    final activeColor = AppTheme.primary;
    final inactiveColor = AppTheme.muted;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isActive ? 1.15 : 1.0,
                  child: Icon(
                    isActive ? activeIcon : icon,
                    size: 22,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.surface, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badge.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isActive && AppTheme.isDark)
                    BoxShadow(
                      color: activeColor.withOpacity(0.8),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tablet NavigationRail
class AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Map internal indices to rail destination indices
  int _getRailIndex(int index) {
    switch (index) {
      case 0:
        return 0; // Map
      case 3:
        return 1; // Messages
      case 2:
        return 2; // Publish
      case 4:
        return 3; // Listings
      case 5:
        return 4; // Profile
      default:
        return 0;
    }
  }

  // Map rail destination indices to internal indices
  int _getInternalIndex(int railIndex) {
    switch (railIndex) {
      case 0:
        return 0; // Map
      case 1:
        return 3; // Messages
      case 2:
        return 2; // Publish
      case 3:
        return 4; // Listings
      case 4:
        return 5; // Profile
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: _getRailIndex(currentIndex),
      onDestinationSelected: (railIdx) => onTap(_getInternalIndex(railIdx)),
      backgroundColor: AppTheme.surface,
      indicatorColor: AppTheme.primary.withAlpha(26),
      selectedIconTheme: IconThemeData(color: AppTheme.primary),
      unselectedIconTheme: IconThemeData(color: AppTheme.muted),
      selectedLabelTextStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
      unselectedLabelTextStyle: GoogleFonts.outfit(
        fontSize: 12,
        color: AppTheme.muted,
      ),
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map_rounded),
          label: Text(tr('nav_map')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(Icons.chat_bubble_rounded),
          label: Text(tr('nav_messages')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.add_circle_outline_rounded),
          selectedIcon: const Icon(Icons.add_circle_rounded),
          label: Text(tr('nav_publish')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.home_work_outlined),
          selectedIcon: const Icon(Icons.home_work_rounded),
          label: Text(tr('nav_listings')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: Text(tr('nav_profile')),
        ),
      ],
    );
  }
}
