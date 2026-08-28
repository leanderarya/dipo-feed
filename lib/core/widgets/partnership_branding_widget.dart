import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Reusable branding widget displaying partner logos (DipoFeed, UNDIP, ACIAR)
/// with graceful fallback handling if image assets fail to load.
class PartnershipBrandingWidget extends StatelessWidget {
  final double height;
  final VoidCallback? onTap;
  final bool isCardStyle;
  final bool showInfoBadge;

  const PartnershipBrandingWidget({
    super.key,
    this.height = 36,
    this.onTap,
    this.isCardStyle = true,
    this.showInfoBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Logo DipoFeed
        _buildLogoItem(
          assetPath: 'assets/images/logo_dipofeed.jpeg',
          fallbackLabel: 'DipoFeed',
          fallbackColor: AppColors.secondaryGreen,
          height: height,
          fit: BoxFit.contain,
        ),
        _buildDivider(),

        // 2. Logo UNDIP
        _buildLogoItem(
          assetPath: 'assets/images/logo_undip.png',
          fallbackLabel: 'UNDIP',
          fallbackColor: AppColors.primaryBlue,
          height: height,
          fit: BoxFit.contain,
        ),
        _buildDivider(),

        // 3. Logo ACIAR Australia
        _buildLogoItem(
          assetPath: 'assets/images/logo_aciar.png',
          fallbackLabel: 'ACIAR',
          fallbackColor: const Color(0xFF006644),
          height: height * 0.85, // Scale proportionally to match UNDIP crest height
          fit: BoxFit.contain,
        ),

        if (showInfoBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ],
    );

    if (isCardStyle) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildDivider() {
    return Container(
      height: height * 0.5,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.withValues(alpha: 0.25),
    );
  }

  Widget _buildLogoItem({
    required String assetPath,
    required String fallbackLabel,
    required Color fallbackColor,
    required double height,
    required BoxFit fit,
  }) {
    return Image.asset(
      assetPath,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        // Elegant text placeholder fallback if asset is missing/unavailable
        return Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fallbackColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: fallbackColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            fallbackLabel,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fallbackColor,
            ),
          ),
        );
      },
    );
  }
}
