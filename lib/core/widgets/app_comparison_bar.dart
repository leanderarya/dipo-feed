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
    final double percentage = limit > 0 ? (current / limit).clamp(0.0, 1.2) : 0;
    final bool isKurang = current < limit * 0.95;
    final bool isBerlebih = limit > 0 && current > limit * 1.05;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bar Container
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 1.2).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Target line (100% target marker)
              if (limit > 0)
                Positioned(
                  left: (MediaQuery.of(context).size.width - 68) * (1.0 / 1.2),
                  child: Container(
                    height: 10,
                    width: 2,
                    color: AppColors.textPrimary.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Realisasi: ${IndonesianNumberFormatter.format(current, decimals: 2)} / Target: ${IndonesianNumberFormatter.format(limit, decimals: 2)}$unitSuffix',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isKurang)
                Text(
                  'Butuh ${IndonesianNumberFormatter.format(limit - current, decimals: 2)}$unitSuffix lagi',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusKurang,
                  ),
                )
              else if (isBerlebih)
                Text(
                  'Kelebihan ${IndonesianNumberFormatter.format(current - limit, decimals: 2)}$unitSuffix',
                  style: GoogleFonts.inter(
                    fontSize: 11,
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

