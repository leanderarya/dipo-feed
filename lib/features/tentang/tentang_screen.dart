import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
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

          // Section 1: Kerja Sama Kemitraan (ACIAR Australia, UNDIP, DipoFeed)
          _buildSectionHeader('Kerja Sama Kemitraan'),
          const SizedBox(height: 10),
          _buildPartnershipCard(context),
          const SizedBox(height: 24),

          // Section 2: Pilar Kolaborasi
          _buildSectionHeader('Pilar Kolaborasi'),
          const SizedBox(height: 10),
          _buildPillarsSection(),
          const SizedBox(height: 24),

          // Section 3: Informasi Versi & Rilis
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
                      'Kolaborasi Riset Strategis',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FPP UNDIP & ACIAR Australia',
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
          // Logo Kemitraan (DipoFeed, UNDIP, ACIAR)
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
            'DipoFeed merupakan platform digital formulasi ransum pakan sapi perah yang dikembangkan oleh Tim Riset Fakultas Peternakan dan Pertanian (FPP) Universitas Diponegoro bekerja sama dengan Australian Centre for International Agricultural Research (ACIAR) Australia untuk mendukung peternak sapi perah Indonesia.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => PartnershipInfoDialog.show(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lihat Detail Kolaborasi',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsSection() {
    return Column(
      children: [
        _buildPillarCard(
          icon: Icons.school_rounded,
          iconColor: AppColors.primaryBlue,
          title: 'Universitas Diponegoro (UNDIP)',
          subtitle:
              'Fakultas Peternakan dan Pertanian memimpin formulasi riset pakan berbasis potensi bahan pakan lokal serta pendampingan peternak sapi perah.',
        ),
        const SizedBox(height: 10),
        _buildPillarCard(
          icon: Icons.public_rounded,
          iconColor: const Color(0xFF006644),
          title: 'ACIAR Australia',
          subtitle:
              'Lembaga riset pertanian Pemerintah Australia yang mendanai dan mendukung transfer teknologi untuk ketahanan pakan dan produktivitas peternak.',
        ),
        const SizedBox(height: 10),
        _buildPillarCard(
          icon: Icons.grass_rounded,
          iconColor: AppColors.secondaryGreen,
          title: 'Inovasi DipoFeed',
          subtitle:
              'Solusi formulasi ransum pakan sapi perah secara presisi, praktis, dan berbasis standar ilmiah untuk efisiensi biaya dan nutrisi optimal.',
        ),
      ],
    );
  }

  Widget _buildPillarCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
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
          isBeta = v.contains('beta') || v.contains('dev');
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
