import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppSliverHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBackTap;
  final bool showBackButton;

  const AppSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBackTap,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final double expandedHeight = subtitle != null ? 200.0 : 140.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackTap ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      centerTitle: true,
      // Collapsed title that fades in
      title: _CollapsedTitle(title: title),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Expanded content
            Positioned(
              left: 24,
              right: 24,
              bottom: 32, // Adjusted padding for smaller radius
              child: _ExpandedContent(
                title: title,
                subtitle: subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedTitle extends StatelessWidget {
  final String title;

  const _CollapsedTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    if (settings == null) return const SizedBox.shrink();

    final deltaExtent = settings.maxExtent - settings.minExtent;
    final t =
        (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent)
            .clamp(0.0, 1.0);

    // Fade in when collapsed
    final opacity = Curves.easeIn.transform(t > 0.8 ? (t - 0.8) / 0.2 : 0.0);

    return Opacity(
      opacity: opacity,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _ExpandedContent({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    if (settings == null) return const SizedBox.shrink();

    final deltaExtent = settings.maxExtent - settings.minExtent;
    final t =
        (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent)
            .clamp(0.0, 1.0);

    // Fade out when collapsing
    final opacity = (1.0 - t * 1.5).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
