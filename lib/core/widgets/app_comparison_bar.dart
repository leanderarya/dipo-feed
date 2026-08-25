import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../utils/indonesian_number_formatter.dart';

class AppComparisonBar extends StatelessWidget {
  final String label;
  final double limit;
  final double current;
  final String unit;

  const AppComparisonBar({
    super.key,
    required this.label,
    required this.limit,
    required this.current,
    this.unit = 'kg',
  });

  @override
  Widget build(BuildContext context) {
    final double targetPercentage =
        limit > 0 ? (current / limit).clamp(0.0, 1.2) : 0;
    final bool isKurang = current < limit * 0.95;
    final bool isBerlebih = limit > 0 && current > limit * 1.05;
    final bool isPas = !isKurang && !isBerlebih;

    final color = isKurang
        ? AppColors.statusKurang
        : (isBerlebih ? AppColors.statusBerlebih : AppColors.statusPas);

    final statusBgColor = isKurang
        ? AppColors.dangerLight
        : (isBerlebih ? AppColors.primaryLight : AppColors.secondaryLight);

    final statusText = isKurang
        ? 'Kurang'
        : (isBerlebih ? 'Berlebih' : 'Tercukupi (Pas)');

    final unitSuffix = unit.isNotEmpty ? ' $unit' : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: isPas
                      ? [
                          BoxShadow(
                            color: AppColors.statusPas.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Animated Bar Container
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              // 100% target marker position (at 1.0 / 1.2 = 83.33% of bar width)
              final targetLineX = totalWidth * (1.0 / 1.2);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track Background
                  Container(
                    height: 10,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                  ),
                  // Animated Progress Fill
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: (targetPercentage / 1.2).clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, fillFactor, child) {
                      return Container(
                        height: 10,
                        width: totalWidth * fillFactor,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isPas
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    },
                  ),
                  // Target marker line (100% reference)
                  if (limit > 0)
                    Positioned(
                      left: targetLineX - 1,
                      top: -1,
                      child: Container(
                        height: 12,
                        width: 2,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${IndonesianNumberFormatter.format(current, decimals: 2)} / ${IndonesianNumberFormatter.format(limit, decimals: 2)}$unitSuffix',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isKurang)
                Text(
                  'Butuh ${IndonesianNumberFormatter.format(limit - current, decimals: 2)} lagi',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusKurang,
                  ),
                )
              else if (isBerlebih)
                Text(
                  'Kelebihan ${IndonesianNumberFormatter.format(current - limit, decimals: 2)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusBerlebih,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
