import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import '../cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';
import '../cek_kecukupan_pakan/cek_kecukupan_pakan_screen.dart';
import '../master_pakan/master_pakan_screen.dart';
import '../rekomendasi_pakan/rekomendasi_pakan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _jumlahBahan = 0;

  @override
  void initState() {
    super.initState();
    _muatJumlahBahan();
  }

  Future<void> _muatJumlahBahan() async {
    try {
      final repo = BahanPakanRepository();
      await repo.initialize();
      if (!mounted) return;
      setState(() {
        _jumlahBahan = repo.dataAktif.length;
      });
    } catch (_) {
      // Fallback: just keep 0
    }
  }

  void _onTapBottomNav(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = index;
      });
      return;
    }

    // Show "Under Development" for Panduan and Pengaturan
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == 1
              ? 'Fitur Panduan segera hadir.'
              : 'Fitur Pengaturan segera hadir.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _bukaCekKecukupan() {
    Navigator.push(
      context,
      _createRoute(const CekKecukupanPakanScreen()),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  void _bukaCekKandungan() {
    Navigator.push(
      context,
      _createRoute(const CekKandunganNutrisiScreen()),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  void _bukaMasterPakan() {
    Navigator.push(
      context,
      _createRoute(const MasterPakanScreen()),
    ).then((_) {
      setState(() => _selectedIndex = 0);
      _muatJumlahBahan(); // refresh count after potential changes
    });
  }

  void _bukaFormulasi() {
    Navigator.push(
      context,
      _createRoute(const RekomendasiPakanScreen()),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05); // Start slightly lower
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var slideTween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(isHome: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingHeader(),
                const SizedBox(height: 20),
                _buildBentoGrid(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomNav(
              currentIndex: _selectedIndex,
              onTap: _onTapBottomNav,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact greeting header replacing the old large hero banner.
  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 11) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'RESEARCH-BASED FPP UNDIP',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Greeting + Tagline
          Text(
            '$greeting 👋',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optimalkan nutrisi ternak Anda',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          // Quick Stat Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: AppColors.secondaryGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_jumlahBahan Bahan Pakan',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 1,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Icon(
                  Icons.grid_view_rounded,
                  size: 14,
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  '4 Fitur Siap',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Asymmetric Bento Grid layout:
  /// Row 1: Full-width hero card (Cek Kecukupan)
  /// Row 2: Two medium cards side-by-side (Rekomendasi + Cek Kandungan)
  /// Row 3: Full-width card (Database Pakan)
  Widget _buildBentoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'Fitur Utama',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),

        // Row 1: Hero Card — Cek Kecukupan Pakan (full-width)
        QuickActionCard(
          title: 'Cek Kecukupan Pakan',
          description: 'Evaluasi kebutuhan vs asupan nutrisi ransum ternak Anda secara presisi',
          svgAsset: 'assets/icons/ic_evaluasi.svg',
          baseColor: AppColors.primaryBlue,
          onTap: _bukaCekKecukupan,
          isHero: true,
          chipLabels: const ['Sapi Potong', 'Sapi Perah', 'Kambing / Domba'],
        ),
        const SizedBox(height: 14),

        // Row 2: Two medium cards side-by-side
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Rekomendasi Pakan',
                description: 'Formulasi ransum otomatis',
                svgAsset: 'assets/icons/ic_rekomendasi.svg',
                baseColor: AppColors.accentOrange,
                onTap: _bukaFormulasi,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: QuickActionCard(
                title: 'Cek Kandungan Nutrisi',
                description: 'Kalkulasi nutrisi campuran',
                icon: Icons.analytics_rounded,
                baseColor: AppColors.secondaryGreen,
                onTap: _bukaCekKandungan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 3: Full-width card — Database Pakan
        QuickActionCard(
          title: 'Database Pakan',
          description: '$_jumlahBahan bahan pakan terdaftar — katalog & kandungan nutrien lengkap',
          svgAsset: 'assets/icons/ic_database.svg',
          baseColor: AppColors.expertPurple,
          onTap: _bukaMasterPakan,
          isHero: true,
        ),
      ],
    );
  }
}
