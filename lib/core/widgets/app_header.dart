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
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
      ),
      child: const Center(
        child: Text(
          'DipoFeed',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryGreen,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHeader(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    final bool shouldShowBack = showBackButton ?? canPop;

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
                        onPressed: onBackTap ?? () => Navigator.of(context).pop(),
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
                    : const SizedBox(width: 48), // Spacer to keep title centered
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
    if (isHome) return const Size.fromHeight(70);
    
    // Start with top bar height
    double height = 56;
    
    // Add estimated heights for heading and subtitle
    if (heading != null) height += 40;
    if (subtitle != null) {
      // Allow more space for multi-line subtitles
      height += 60; 
    }
    if (heading != null || subtitle != null) {
      height += 40; // Extra padding
    }
    
    return Size.fromHeight(height);
  }
}
