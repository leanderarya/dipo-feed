import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Centered title in the top bar
  final String title;

  /// Large heading text inside the header (optional, kept for backwards compatibility)
  final String? heading;

  /// Subtitle or description text inside the header (optional, kept for backwards compatibility)
  final String? subtitle;

  /// Whether to show the back button. Defaults to true if not home.
  final bool? showBackButton;

  /// Actions to show on the right side of the top bar
  final List<Widget>? actions;

  /// Whether this is the home screen header (uses specific logo style)
  final bool isHome;

  /// Callback for the back button
  final VoidCallback? onBackTap;

  const AppHeader({
    super.key,
    this.title = '',
    this.heading,
    this.subtitle,
    this.showBackButton,
    this.actions,
    this.isHome = false,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isHome) {
      return _buildHomeHeader(context);
    }
    return _buildFeatureHeader(context);
  }

  Widget _buildHomeHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Left: Logo DipoFeed + Text DIPO Feed
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/logo_dipofeed.jpeg',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'DIPO',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Feed',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondaryGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Partner Logos (UNDIP & ACIAR)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo_undip.png',
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 18,
                        width: 1,
                        color: AppColors.border,
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/logo_aciar.png',
                        height: 26,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Vibrant gradient accent bottom border
            Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.secondaryGreen,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    final bool shouldShowBack = showBackButton ?? canPop;
    final displayTitle = title.isNotEmpty ? title : (heading ?? '');
    final bool hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    final Widget leftWidget = shouldShowBack
        ? Material(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onBackTap ?? () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
        : const SizedBox(width: 36);

    final Widget rightWidget = actions != null && actions!.isNotEmpty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: actions!,
          )
        : const SizedBox(width: 36);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  leftWidget,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  rightWidget,
                ],
              ),
            ),
            // Vibrant gradient accent bottom border
            Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.secondaryGreen,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    if (isHome) return const Size.fromHeight(62);

    double height = 56;

    if (heading != null || subtitle != null) {
      height += 128;
    }

    if ((subtitle?.length ?? 0) > 80) {
      height += 24;
    }

    return Size.fromHeight(height);
  }
}
