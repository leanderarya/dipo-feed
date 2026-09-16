import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/partnership_constants.dart';
import '../../core/widgets/partnership_branding_widget.dart';
import '../../core/widgets/partnership_info_dialog.dart';

class TentangScreen extends StatelessWidget {
  final bool isTab;

  const TentangScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentang DipoFeed',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inovasi formulasi ransum pakan sapi perah presisi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 1: Pilar Kolaborasi (DipoFeed, UNDIP, ACIAR Australia)
          _buildSectionHeader('Pilar Kolaborasi'),
          const SizedBox(height: 10),
          _buildPartnershipCard(context),
          const SizedBox(height: 24),

          // Section 2: Informasi Versi & Rilis
          _buildSectionHeader('Informasi Aplikasi'),
          const SizedBox(height: 10),
          _buildAppReleaseCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _buildPartnershipCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.handshake_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilar Kolaborasi Strategis',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ACIAR Australia, UNDIP & DipoFeed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Logo Kemitraan (Urutan: ACIAR, UNDIP, DipoFeed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: PartnershipBrandingWidget(
              height: 48,
              isCardStyle: false,
              showInfoBadge: false,
              onTap: () => PartnershipInfoDialog.show(context),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            PartnershipConstants.introText,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // 3 Kartu Detail Per Pihak Sesuai Brief
          _buildPartnerCard(
            assetPath: PartnershipConstants.aciarStackedLogo,
            fallbackLabel: PartnershipConstants.aciarTitle,
            brandColor: const Color(0xFF658D1B),
            title: PartnershipConstants.aciarTitle,
            subtitle: PartnershipConstants.aciarDescription,
            logoPadding: 2,
          ),
          const SizedBox(height: 10),
          _buildPartnerCard(
            assetPath: PartnershipConstants.undipLogo,
            fallbackLabel: PartnershipConstants.undipTitle,
            brandColor: AppColors.primaryBlue,
            title: PartnershipConstants.undipTitle,
            subtitle: PartnershipConstants.undipDescription,
            logoPadding: 5,
          ),
          const SizedBox(height: 10),
          _buildPartnerCard(
            assetPath: PartnershipConstants.dipoFeedLogo,
            fallbackLabel: PartnershipConstants.dipoFeedTitle,
            brandColor: AppColors.secondaryGreen,
            title: PartnershipConstants.dipoFeedTitle,
            subtitle: PartnershipConstants.dipoFeedDescription,
            logoPadding: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard({
    required String assetPath,
    required String fallbackLabel,
    required Color brandColor,
    required String title,
    required String subtitle,
    double logoPadding = 4,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            padding: EdgeInsets.all(logoPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: brandColor.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    alignment: Alignment.center,
                    color: brandColor.withValues(alpha: 0.08),
                    child: Text(
                      fallbackLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: brandColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppReleaseCard(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        String versionText = 'v1.4.0 (Build 7)';
        bool isBeta = false;

        if (snapshot.hasData && snapshot.data != null) {
          final info = snapshot.data!;
          final v = info.version.isNotEmpty ? info.version : '1.4.0';
          final b = info.buildNumber.isNotEmpty ? info.buildNumber : '7';
          versionText = 'v$v (Build $b)';
          isBeta = v.contains('beta') || v.contains('dev') || v.contains('b');
        }

        final badgeColor =
            isBeta ? AppColors.primaryBlue : AppColors.secondaryGreen;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DipoFeed Mobile & Web',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          versionText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isBeta ? 'Beta' : 'Rilis Resmi',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0x0F000000)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tanggal Rilis',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '2 September 2026',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
