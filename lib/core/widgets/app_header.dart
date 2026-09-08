import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Centered title in the top bar
  final String title;

  /// Large heading text inside the header (optional)
  final String? heading;

  /// Subtitle or description text inside the header (optional)
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
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 6,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(color: AppColors.backgroundCream),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kapsul Kiri: DipoFeed (Logo Lingkaran + Teks Tulisan DIPOFeed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/logo_dipofeed.jpeg',
                    height: 30,
                    width: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/DIPOFeed.png',
                  height: 18,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // Kapsul Kanan: Kemitraan (UNDIP & ACIAR Australia)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_aciar.png',
                  height: 24,
                  fit: BoxFit.contain,
                ),
                Container(
                  height: 16,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  color: Colors.grey.shade300,
                ),
                Image.asset(
                  'assets/images/logo_undip.png',
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    final bool shouldShowBack = showBackButton ?? (onBackTap != null || canPop);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ensure we don't draw under the status bar if not handled by Scaffold
          SizedBox(height: MediaQuery.of(context).padding.top),
          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 56,
              child: NavigationToolbar(
                leading: shouldShowBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed:
                            onBackTap ?? () => Navigator.of(context).pop(),
                      )
                    : null,
                centerMiddle: true,
                middle: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: actions != null
                    ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    : const SizedBox(
                        width: 48,
                      ), // Spacer to keep title centered
              ),
            ),
          ),
          // Expanded content (heading & subtitle)
          if (heading != null || subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (heading != null)
                    Text(
                      heading!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  if (heading != null && subtitle != null)
                    const SizedBox(height: 12),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize {
    if (isHome) return const Size.fromHeight(78);

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
