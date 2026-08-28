import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Enum jenis Toast Notification di DipoFeed.
enum ToastType { success, error, warning, info }

/// Utility helper terpusat untuk menampilkan Toast / Top-Floating Banner notification di seluruh modul DipoFeed.
class AppToast {
  const AppToast._();

  static OverlayEntry? _currentEntry;

  /// Tampilkan Toast Berhasil (Success Toast)
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Berhasil',
      type: ToastType.success,
      duration: duration,
    );
  }

  /// Tampilkan Toast Gagal / Error (Error Toast)
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Gagal',
      type: ToastType.error,
      duration: duration,
    );
  }

  /// Tampilkan Toast Peringatan (Warning Toast)
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Peringatan',
      type: ToastType.warning,
      duration: duration,
    );
  }

  /// Tampilkan Toast Informasi (Info Toast)
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Informasi',
      type: ToastType.info,
      duration: duration,
    );
  }

  /// Tampilkan Top Floating Toast Banner
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Haptic feedback lembut
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    // Hapus toast sebelumnya jika masih aktif
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);

    if (overlay == null) {
      // Fallback ke SnackBar standar jika overlay tidak tersedia
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        final config = _getToastConfig(type);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            duration: duration,
            behavior: SnackBarBehavior.floating,
            backgroundColor: config.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: config.borderColor),
            ),
            content: Row(
              children: [
                Icon(config.icon, color: config.iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: config.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    final config = _getToastConfig(type);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _TopFloatingToastWidget(
        title: title,
        message: message,
        config: config,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          backgroundColor: const Color(0xFFEFFDF5),
          borderColor: AppColors.secondaryGreen.withValues(alpha: 0.5),
          iconBgColor: AppColors.secondaryGreen.withValues(alpha: 0.18),
          iconColor: AppColors.secondaryGreen,
          textColor: const Color(0xFF064E3B),
          icon: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return _ToastConfig(
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: AppColors.errorRed.withValues(alpha: 0.5),
          iconBgColor: AppColors.errorRed.withValues(alpha: 0.18),
          iconColor: AppColors.errorRed,
          textColor: const Color(0xFF7F1D1D),
          icon: Icons.error_rounded,
        );
      case ToastType.warning:
        return _ToastConfig(
          backgroundColor: const Color(0xFFFFFBEB),
          borderColor: AppColors.accentOrange.withValues(alpha: 0.5),
          iconBgColor: AppColors.accentOrange.withValues(alpha: 0.18),
          iconColor: AppColors.accentOrange,
          textColor: const Color(0xFF78350F),
          icon: Icons.warning_rounded,
        );
      case ToastType.info:
        return _ToastConfig(
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: AppColors.primaryBlue.withValues(alpha: 0.5),
          iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.18),
          iconColor: AppColors.primaryBlue,
          textColor: const Color(0xFF1E3A8A),
          icon: Icons.info_rounded,
        );
    }
  }
}

class _TopFloatingToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final _ToastConfig config;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopFloatingToastWidget({
    required this.title,
    required this.message,
    required this.config,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopFloatingToastWidget> createState() =>
      _TopFloatingToastWidgetState();
}

class _TopFloatingToastWidgetState extends State<_TopFloatingToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _timer = Timer(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Timer? _timer;

  void _dismiss() {
    _timer?.cancel();
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding > 0 ? topPadding + 64 : 64,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null &&
                    details.primaryDelta! < -6) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.config.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.config.borderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.config.iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.config.icon,
                        color: widget.config.iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.title != null &&
                              widget.title!.isNotEmpty) ...[
                            Text(
                              widget.title!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: widget.config.textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.config.textColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close,
                      size: 16,
                      color: widget.config.textColor.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _ToastConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
