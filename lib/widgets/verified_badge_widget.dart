import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Displays a "Vérifié" badge for validated profiles and listings.
class VerifiedBadgeWidget extends StatelessWidget {
  final bool isVerified;
  final bool compact;
  final bool showLabel;

  const VerifiedBadgeWidget({
    super.key,
    required this.isVerified,
    this.compact = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1DA1F2).withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF1DA1F2).withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 12 : 14,
            color: const Color(0xFF1DA1F2),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'Vérifié',
              style: GoogleFonts.outfit(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1DA1F2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
