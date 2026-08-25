import 'package:flutter/material.dart';

/// A wrapper widget that provides a **press-down scale effect** and
/// **shadow lift** animation on tap.  Wrap any card or interactive
/// container with this to give it a premium "press" feel.
///
/// - On tap-down: the child scales to [pressScale] (default 0.97)
///   and shadow becomes softer.
/// - On tap-up / cancel: the child springs back to 1.0 scale.
class AnimatedPressCard extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Scale factor when pressed.  Defaults to 0.97 (3 % shrink).
  final double pressScale;

  /// Duration of the scale animation.
  final Duration duration;

  /// Border radius applied to the ink splash / hit-test area.
  final BorderRadius borderRadius;

  const AnimatedPressCard({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.97,
    this.duration = const Duration(milliseconds: 150),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  State<AnimatedPressCard> createState() => _AnimatedPressCardState();
}

class _AnimatedPressCardState extends State<AnimatedPressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
