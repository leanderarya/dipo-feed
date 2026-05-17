import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/quick_action_card.dart';
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
          index == 1 ? 'Fitur Panduan segera hadir.' : 'Fitur Pengaturan segera hadir.',
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
    ).then((_) => setState(() => _selectedIndex = 0));
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

        var slideTween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: const AppHeader(
        isHome: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110), // Optimized padding for iOS and screen viewports
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 20), // Reduced from 32
                const Text(
                  'Fitur Utama',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12), // Reduced from 16
                _buildFeatureGrid(),
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

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // SVG Background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/hero_banner.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Rich Overlay to ensure high readability of both dark blue title and white description text
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.2), // Light at the top
                    const Color(0xFF0F172A).withValues(alpha: 0.8), // Dark at the bottom
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20), // Reduced from 24
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004AAD), // Solid Royal Blue for high visibility
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'RESEARCH-BASED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12), // Reduced from 16
                const Text(
                  'Optimalkan Nutrisi\nTernak Anda',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white, // High-contrast premium white
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8), // Reduced from 12
                const Text(
                  'Standar riset terkini dari Fakultas Peternakan dan Pertanian (FPP) Universitas Diponegoro',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600, // Thicker weight for premium contrast
                    height: 1.4,
                    shadows: [
                      Shadow(
                        color: Colors.black45, // Darker shadow for solid pop
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.12, // Slightly wider and shorter for a modern, compact look
      children: [
        QuickActionCard(
          title: 'Cek Kecukupan Pakan',
          description: 'Evaluasi kecukupan nutrien pada pemberian pakan ternak',
          svgAsset: 'assets/icons/ic_evaluasi.svg',
          baseColor: AppColors.secondaryGreen,
          onTap: _bukaCekKecukupan,
        ),
        QuickActionCard(
          title: 'Database Pakan',
          description: 'Database bahan pakan',
          svgAsset: 'assets/icons/ic_database.svg',
          baseColor: AppColors.primaryBlue,
          onTap: _bukaMasterPakan,
        ),
        QuickActionCard(
          title: 'Cek Kandungan Pakan',
          description: 'Cek kandungan nutrisi pada pakan',
          icon: Icons.analytics_rounded,
          baseColor: AppColors.expertPurple,
          onTap: _bukaCekKandungan,
        ),
        QuickActionCard(
          title: 'Rekomendasi Pakan',
          description: 'Rekomendasi pemberian pakan untuk mencukupi kebutuhan nutrisi ternak',
          svgAsset: 'assets/icons/ic_rekomendasi.svg',
          baseColor: AppColors.accentOrange,
          onTap: _bukaFormulasi,
        ),
      ],
    );
  }
}
