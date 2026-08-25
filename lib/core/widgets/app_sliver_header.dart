import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return SliverAppBar(
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.border),
      ),
      leading: showBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Material(
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
                ),
              ),
            )
          : null,
      leadingWidth: showBackButton ? 64 : 16,
      titleSpacing: 0,
      centerTitle: false,
      actions: actions != null && actions!.isNotEmpty
          ? [
              ...actions!,
              const SizedBox(width: 8),
            ]
          : null,
      title: (subtitle != null && subtitle!.isNotEmpty)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Text(
              title,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}

