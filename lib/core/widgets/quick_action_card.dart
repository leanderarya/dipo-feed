import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? svgAsset;
  final Color baseColor;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.svgAsset,
    required this.baseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // Reduced from 16 for compact look
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Slightly smaller radius for sleekness
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Reduced from 12
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset!,
                      width: 24, // Reduced from 26
                      height: 24, // Reduced from 26
                      colorFilter: ColorFilter.mode(baseColor, BlendMode.srcIn),
                    )
                  : Icon(
                      icon,
                      color: baseColor,
                      size: 24, // Reduced from 26
                    ),
            ),
            const SizedBox(height: 10), // Reduced from 16
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14, // Slightly smaller from 16 to fit beautifully in 2 lines
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1.1,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4), // Reduced from 6
            Expanded(
              child: Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey.withValues(alpha: 0.8),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
