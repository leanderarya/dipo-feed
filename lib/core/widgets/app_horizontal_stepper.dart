import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Customized horizontal stepper matching the Pill Track & Numbered Marker style.
class AppHorizontalStepper extends StatelessWidget {
  /// 0-indexed current active step
  final int currentStep;

  /// Labels for each step (e.g. ['Data Sapi', 'Pemberian Pakan'])
  final List<String> steps;

  /// Optional tap handler for completed/active steps
  final ValueChanged<int>? onStepTapped;

  const AppHorizontalStepper({
    super.key,
    required this.currentStep,
    required this.steps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final totalSteps = steps.length;
    final safeStep = currentStep.clamp(0, totalSteps - 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info: Badge "Tahap X dari Y" & Current Step Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  'Tahap ${safeStep + 1} dari $totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  steps[safeStep],
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Pill Track Stepper (Circles & Connecting Lines)
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                // Step Circle
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < safeStep;
                final isActive = stepIndex == safeStep;

                Widget circle = AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.secondaryGreen
                        : (isActive
                            ? AppColors.accentOrange
                            : AppColors.surfaceLow),
                    shape: BoxShape.circle,
                    border: (!isCompleted && !isActive)
                        ? Border.all(color: AppColors.border, width: 1.5)
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.accentOrange.withValues(alpha: 0.38),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: GoogleFonts.inter(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                );

                if (onStepTapped != null && stepIndex <= safeStep) {
                  circle = GestureDetector(
                    onTap: () => onStepTapped!(stepIndex),
                    child: circle,
                  );
                }

                return circle;
              } else {
                // Connecting Line between Step Circles
                final prevStepIndex = index ~/ 2;
                final isLineFilled = prevStepIndex < safeStep;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: isLineFilled
                            ? AppColors.secondaryGreen
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}
