import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'animated_press_card.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? svgAsset;
  final Color baseColor;
  final VoidCallback onTap;

  /// When true the card renders as a full-width hero variant with bigger icon,
  /// optional [chipLabels], and a taller minimum height.
  final bool isHero;

  /// Optional quick-access chip labels shown inside the hero card
  /// (e.g. ['Sapi Potong', 'Sapi Perah', 'Lainnya']).
  final List<String>? chipLabels;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.svgAsset,
    required this.baseColor,
    required this.onTap,
    this.isHero = false,
    this.chipLabels,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(isHero ? 20 : 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: baseColor.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: isHero ? _buildHeroContent() : _buildCompactContent(),
      ),
    );
  }

  /// Full-width hero card layout with larger icon, description, and chip pills.
  Widget _buildHeroContent() {
    return Row(
      children: [
        // Left gradient accent line
        Container(
          width: 3,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                baseColor,
                baseColor.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset!,
                  width: 28,
                  height: 28,
                  colorFilter: ColorFilter.mode(baseColor, BlendMode.srcIn),
                )
              : Icon(
                  icon ?? Icons.grid_view_rounded,
                  color: baseColor,
                  size: 28,
                ),
        ),
        const SizedBox(width: 14),
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (chipLabels != null && chipLabels!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: chipLabels!.map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: baseColor.withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: baseColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Arrow indicator
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: baseColor,
          ),
        ),
      ],
    );
  }

  /// Compact card layout (original grid style, enhanced).
  Widget _buildCompactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Icon Container + Mini Indicator Arrow
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left gradient accent line + icon
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        baseColor,
                        baseColor.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: svgAsset != null
                      ? SvgPicture.asset(
                          svgAsset!,
                          width: 24,
                          height: 24,
                          colorFilter:
                              ColorFilter.mode(baseColor, BlendMode.srcIn),
                        )
                      : Icon(
                          icon ?? Icons.grid_view_rounded,
                          color: baseColor,
                          size: 24,
                        ),
                ),
              ],
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        // Description
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
