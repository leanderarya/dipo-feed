import 'package:flutter/material.dart';

/// A lightweight widget that animates its [child] with a subtle
/// **fade-in** and **slide-up** transition, with an optional [delay]
/// for creating staggered visual entrances on cards and sections.
class StaggeredEntryCard extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideOffset;

  const StaggeredEntryCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 350),
    this.slideOffset = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        // If there's a delay, we calculate effective progress after delay factor
        final delayFraction =
            (duration + delay).inMilliseconds > 0
                ? delay.inMilliseconds / (duration + delay).inMilliseconds
                : 0.0;

        final effectiveProgress = progress <= delayFraction
            ? 0.0
            : ((progress - delayFraction) / (1.0 - delayFraction)).clamp(0.0, 1.0);

        return Opacity(
          opacity: effectiveProgress,
          child: Transform.translate(
            offset: Offset(0, slideOffset * (1.0 - effectiveProgress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
