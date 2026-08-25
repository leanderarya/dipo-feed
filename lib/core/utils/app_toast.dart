import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enum jenis Toast Notification di DipoFeed.
enum ToastType { success, error, warning, info }

/// Utility helper terpusat untuk menampilkan Toast / SnackBar notification di seluruh modul DipoFeed.
class AppToast {
  const AppToast._();

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
      title: title,
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
      title: title,
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
      title: title,
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
      title: title,
      type: ToastType.info,
      duration: duration,
    );
  }

  /// Tampilkan Toast umum dengan konfigurasi type & gaya DipoFeed
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final config = _getToastConfig(type);

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: config.borderColor, width: 1),
        ),
        backgroundColor: config.backgroundColor,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: config.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: config.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: config.textColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          backgroundColor: const Color(0xFFEFFDF5),
          borderColor: AppColors.secondaryGreen.withValues(alpha: 0.4),
          iconBgColor: AppColors.secondaryGreen.withValues(alpha: 0.15),
          iconColor: AppColors.secondaryGreen,
          textColor: const Color(0xFF064E3B),
          icon: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return _ToastConfig(
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: AppColors.errorRed.withValues(alpha: 0.4),
          iconBgColor: AppColors.errorRed.withValues(alpha: 0.15),
          iconColor: AppColors.errorRed,
          textColor: const Color(0xFF7F1D1D),
          icon: Icons.error_rounded,
        );
      case ToastType.warning:
        return _ToastConfig(
          backgroundColor: const Color(0xFFFFFBEB),
          borderColor: AppColors.accentOrange.withValues(alpha: 0.4),
          iconBgColor: AppColors.accentOrange.withValues(alpha: 0.15),
          iconColor: AppColors.accentOrange,
          textColor: const Color(0xFF78350F),
          icon: Icons.warning_rounded,
        );
      case ToastType.info:
        return _ToastConfig(
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: AppColors.primaryBlue.withValues(alpha: 0.4),
          iconBgColor: AppColors.primaryBlue.withValues(alpha: 0.15),
          iconColor: AppColors.primaryBlue,
          textColor: const Color(0xFF1E3A8A),
          icon: Icons.info_rounded,
        );
    }
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
