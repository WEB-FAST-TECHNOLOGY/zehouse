import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PublishStepIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final List<String> stepTitles;

  const PublishStepIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepTitles.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              color: isCompleted ? AppTheme.primary : AppTheme.border,
            ),
          );
        }
        // Step circle
        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.primary
                    : isCurrent
                    ? AppTheme.primary
                    : AppTheme.surfaceVariant,
                shape: BoxShape.circle,
                border: isCurrent && !isCompleted
                    ? Border.all(color: AppTheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? Colors.white : AppTheme.muted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stepTitles[stepIndex],
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCurrent ? AppTheme.primary : AppTheme.muted,
              ),
            ),
          ],
        );
      }),
    );
  }
}
