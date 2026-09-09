import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/quick_action_card.dart';
import '../cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';
import '../cek_kecukupan_pakan/cek_kecukupan_pakan_screen.dart';
import '../master_pakan/master_pakan_screen.dart';
import '../rekomendasi_pakan/rekomendasi_pakan_screen.dart';
import '../tentang/tentang_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onTapBottomNav(int index) {
    if (index == 1) {
      // Show "Under Development" for Panduan
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Fitur Panduan segera hadir.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primaryBlue,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
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
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHomeTab = _selectedIndex == 0;
    final overlayStyle = isHomeTab
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: Stack(
          children: [
            _selectedIndex == 2
                ? const SafeArea(
                    bottom: false,
                    child: TentangScreen(isTab: true),
                  )
                : _buildHomeContent(),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNav(
                currentIndex: _selectedIndex,
                onTap: _onTapBottomNav,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 640;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeaderSection(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fitur Utama',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureGrid(isWideScreen: isWideScreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeaderSection() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Hero Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_banner_sapi.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay to ensure contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Content on top of hero
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Floating Capsules Header
                _buildFloatingHeaderRow(),
                const SizedBox(height: 36),
                // Badge Kapsul RESEARCH-BASED
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052CC), // Royal Blue
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0052CC).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'RESEARCH-BASED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Judul Hero
                const Text(
                  'Optimalkan Nutrisi\nTernak Anda',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
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

  Widget _buildFloatingHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Kapsul Kiri: DipoFeed (Compact White Capsule - Optical Center)
        Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(left: 10, right: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo_dipofeed.jpeg',
                  height: 24,
                  width: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 7),
              Transform.translate(
                offset: const Offset(0, -0.5),
                child: Image.asset(
                  'assets/images/DIPOFeed.png',
                  height: 15,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),

        // Kapsul Kanan: Kemitraan (Compact White Capsule)
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_aciar.png',
                height: 23,
                fit: BoxFit.contain,
              ),
              Container(
                height: 12,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.black.withValues(alpha: 0.12),
              ),
              Image.asset(
                'assets/images/logo_undip.png',
                height: 23,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid({bool isWideScreen = false}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWideScreen ? 1.25 : 1.12,
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
          description:
              'Rekomendasi pemberian pakan untuk mencukupi kebutuhan nutrisi ternak',
          svgAsset: 'assets/icons/ic_rekomendasi.svg',
          baseColor: AppColors.accentOrange,
          onTap: _bukaFormulasi,
        ),
      ],
    );
  }
}
