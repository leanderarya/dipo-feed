import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/staggered_entry_card.dart';
import '../cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';
import '../cek_kecukupan_pakan/cek_kecukupan_pakan_screen.dart';
import '../master_pakan/master_pakan_screen.dart';
import '../rekomendasi_pakan/rekomendasi_pakan_screen.dart';
import '../panduan/panduan_screen.dart';
import '../pengaturan/pengaturan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onTapBottomNav(int index) {
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
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Stack(
        children: [
          _buildBody(context),
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

  Widget _buildBody(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 0.04),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _getActiveTabContent(context),
      ),
    );
  }

  Widget _getActiveTabContent(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        return const Column(
          children: [
            AppHeader(
              title: 'Panduan Nutrisi',
              subtitle: 'Edukasi formulasi pakan',
              showBackButton: false,
            ),
            Expanded(
              child: PanduanScreen(isTab: true),
            ),
          ],
        );
      case 2:
        return const Column(
          children: [
            AppHeader(
              title: 'Pengaturan',
              subtitle: 'Kelola data & aplikasi',
              showBackButton: false,
            ),
            Expanded(
              child: PengaturanScreen(isTab: true),
            ),
          ],
        );
      case 0:
      default:
        return _buildHomeContent(context);
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredEntryCard(
            delay: Duration.zero,
            child: _buildTopDisplay(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaggeredEntryCard(
                  delay: const Duration(milliseconds: 60),
                  child: const Text(
                    'Fitur Utama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDisplay(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Hero Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_banner_sapi.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Multi-layer rich gradient overlay for crystal clear contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF071120).withValues(alpha: 0.82), // Dark header area for logos
                    const Color(0xFF0F172A).withValues(alpha: 0.35), // Visible cow middle
                    const Color(0xFF071120).withValues(alpha: 0.88), // High-contrast bottom for title
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Content inside Top Display
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              topPadding > 0 ? topPadding + 10 : 20,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: DipoFeed Brand Badge + Partner Logos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // DipoFeed Brand Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo_dipofeed.jpeg',
                              height: 30,
                              width: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'DIPO',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Feed',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF4ADE80), // Vibrant Green
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Partner Badges (UNDIP & ACIAR)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo_undip.png',
                            height: 22,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 16,
                            width: 1,
                            color: Colors.black.withValues(alpha: 0.15),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/images/logo_aciar.png',
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // Research Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004AAD),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 5),
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
                const SizedBox(height: 10),
                // Main Tagline
                const Text(
                  'Optimalkan Nutrisi\nTernak Anda',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
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
      childAspectRatio: 0.88,
      children: [
        StaggeredEntryCard(
          delay: const Duration(milliseconds: 100),
          child: QuickActionCard(
            title: 'Cek Kecukupan Pakan',
            description: 'Evaluasi kecukupan nutrien pada pemberian pakan ternak',
            svgAsset: 'assets/icons/ic_evaluasi.svg',
            baseColor: AppColors.secondaryGreen,
            onTap: _bukaCekKecukupan,
          ),
        ),
        StaggeredEntryCard(
          delay: const Duration(milliseconds: 160),
          child: QuickActionCard(
            title: 'Database Pakan',
            description: 'Database bahan pakan',
            svgAsset: 'assets/icons/ic_database.svg',
            baseColor: AppColors.primaryBlue,
            onTap: _bukaMasterPakan,
          ),
        ),
        StaggeredEntryCard(
          delay: const Duration(milliseconds: 220),
          child: QuickActionCard(
            title: 'Cek Kandungan Pakan',
            description: 'Cek kandungan nutrisi pada pakan',
            icon: Icons.analytics_rounded,
            baseColor: AppColors.expertPurple,
            onTap: _bukaCekKandungan,
          ),
        ),
        StaggeredEntryCard(
          delay: const Duration(milliseconds: 280),
          child: QuickActionCard(
            title: 'Rekomendasi Pakan',
            description:
                'Rekomendasi pemberian pakan untuk mencukupi kebutuhan nutrisi ternak',
            svgAsset: 'assets/icons/ic_rekomendasi.svg',
            baseColor: AppColors.accentOrange,
            onTap: _bukaFormulasi,
          ),
        ),
      ],
    );
  }
}

