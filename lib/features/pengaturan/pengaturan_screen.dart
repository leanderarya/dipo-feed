import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_press_card.dart';
import '../master_pakan/master_pakan_screen.dart';

class PengaturanScreen extends StatelessWidget {
  final bool isTab;

  const PengaturanScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Text(
            'Pengaturan',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola data lokal dan informasi aplikasi DipoFeed',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Basis Data
          _buildSectionHeader('Basis Data & Pakan'),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primaryBlue,
            title: 'Katalog Master Pakan',
            subtitle: 'Tambah, ubah, atau impor/ekspor data pakan via CSV',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MasterPakanScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.restore_rounded,
            iconColor: AppColors.accentOrange,
            title: 'Reset Data ke Standar',
            subtitle: 'Kembalikan komposisi nutrien bahan pakan ke nilai riset awal',
            onTap: () {
              _showResetDialog(context);
            },
          ),
          const SizedBox(height: 24),

          // Section 2: Informasi & Kemitraan
          _buildSectionHeader('Informasi & Kemitraan'),
          const SizedBox(height: 10),
          _buildInfoCard(),
          const SizedBox(height: 24),

          // Section 3: Pengembang & Versi
          _buildSectionHeader('Tentang Aplikasi'),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'Versi Aplikasi',
            subtitle: 'DipoFeed v1.3.2 (Build 6)',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Terbaru',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryGreen,
                ),
              ),
            ),
          ),
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return AnimatedPressCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x040F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo_undip.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.school, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'FPP Universitas Diponegoro',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'DipoFeed dikembangkan oleh Tim Riset Fakultas Peternakan dan Pertanian (FPP) Universitas Diponegoro bekerjasama dengan Australian Centre for International Agricultural Research (ACIAR).',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Basis Data?'),
        content: const Text(
          'Semua perubahan harga dan bahan pakan kustom akan dikembalikan ke data default standar FPP Undip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentOrange),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Basis data berhasil disinkronkan ke default.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
