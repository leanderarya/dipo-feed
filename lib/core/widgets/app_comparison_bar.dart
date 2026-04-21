import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = limit > 0 ? (current / limit).clamp(0.0, 1.2) : 0;
    final isOver = current >= limit;
    final color = isOver ? AppColors.accentGreen : AppColors.errorRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${current.toStringAsFixed(2)} / ${limit.toStringAsFixed(2)} $unit',
              style: TextStyle(
                color: isOver ? AppColors.primaryGreen : AppColors.errorRed,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (percentage / 1.2).clamp(0.0, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Target line
            if (limit > 0)
              Positioned(
                left: (MediaQuery.of(context).size.width - 64) * (1.0 / 1.2),
                child: Container(
                  height: 12,
                  width: 2,
                  color: AppColors.textDark.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOver ? 'Tercukupi' : 'Kurang',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isOver)
              Text(
                'Butuh ${(limit - current).toStringAsFixed(2)} lagi',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
          ],
        ),
      ],
    );
  }
}
