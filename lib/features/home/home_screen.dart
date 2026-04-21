import 'package:flutter/material.dart';


import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/quick_action_card.dart';
import '../cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';
import '../cek_kecukupan_pakan/cek_kecukupan_pakan_screen.dart';
import '../formulasi_ransum/formulasi_ransum_screen.dart';
import '../master_pakan/master_pakan_screen.dart';

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
    
    // Simple direct navigation for the demo/stabilization
    switch (index) {
      case 1: _bukaCekKecukupan(); break;
      case 2: _bukaMasterPakan(); break;
      case 3: _bukaFormulasi(); break;
    }
  }

  void _bukaCekKecukupan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CekKecukupanPakanScreen()),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  void _bukaCekKandungan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CekKandunganNutrisiScreen()),
    );
  }

  void _bukaMasterPakan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MasterPakanScreen()),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  void _bukaFormulasi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FormulasiRansumScreen(),
      ),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(
        isHome: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Halaman Setelan segera hadir.')),
              );
            },
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primaryGreen,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroBanner(),
                const SizedBox(height: 32),
                const Text(
                  'Layanan Utama',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
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
            child: Image.asset(
              'assets/design/hero-bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Subtle Overlay to ensure readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceLow.withValues(alpha: 0.8),
                    AppColors.surfaceLow.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco_rounded, size: 14, color: AppColors.primaryGreen),
                      SizedBox(width: 6),
                      Text(
                        'RESEARCH-BASED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Optimalkan Nutrisi\nTernak Anda',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Standar riset terkini dari FPP Universitas Diponegoro.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight.withValues(alpha: 0.8),
                    height: 1.4,
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
      childAspectRatio: 0.9,
      children: [
        QuickActionCard(
          title: 'Cek Kecukupan',
          description: 'Evaluasi gizi harian sapi',
          icon: Icons.health_and_safety_rounded,
          baseColor: AppColors.primaryGreen,
          onTap: _bukaCekKecukupan,
        ),
        QuickActionCard(
          title: 'Database Pakan',
          description: 'Katalog kimiawi pakan lokal',
          icon: Icons.inventory_2_rounded,
          baseColor: const Color(0xFF476553), // Secondary
          onTap: _bukaMasterPakan,
        ),
        QuickActionCard(
          title: 'Cek Nutrisi',
          description: 'Estimasi gizi campuran pakan',
          icon: Icons.analytics_rounded,
          baseColor: const Color(0xFF3C2B12), // Tertiary
          onTap: _bukaCekKandungan,
        ),
        QuickActionCard(
          title: 'Simulasi Ransum',
          description: 'Formula pakan biaya terendah',
          icon: Icons.calculate_rounded,
          baseColor: AppColors.primaryGreen,
          onTap: _bukaFormulasi,
        ),
      ],
    );
  }
}
