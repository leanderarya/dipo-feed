import 'package:flutter/material.dart';

import '../cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';
import '../cek_kecukupan_pakan/cek_kecukupan_pakan_screen.dart';
import '../formulasi_ransum/formulasi_ransum_screen.dart';

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

    if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman panduan belum dibuat.')),
      );
    }

    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman tentang belum dibuat.')),
      );
    }
  }

  void _bukaCekKecukupan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CekKecukupanPakanScreen()),
    );
  }

  void _bukaCekKandungan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CekKandunganNutrisiScreen()),
    );
  }

  void _bukaFormulasi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FormulasiRansumScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF1EBDD);
    const greenDark = Color(0xFF0F6A2C);
    const greenLight = Color(0xFFA6CE39);
    const cardColor = Color(0xFFF7F3E8);
    const brownText = Color(0xFF5A4A35);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER HIJAU
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [greenDark, Color(0xFF1B7F34)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Spacer(),
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Dipo',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: 'Feed',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: greenLight,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'oleh Universitas Diponegoro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // BANNER GAMBAR
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/banner_sapi.webp'),
                        fit: BoxFit.cover,
                      ),
                      color: Colors.white24,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // STRIP SAMBUTAN
                  Container(
                    width: double.infinity,
                    color: greenDark,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Center(
                      child: Text(
                        'Selamat Datang di Kalkulator Pakan Sapi Perah',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // MENU
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  _MenuCard(
                    title: 'Cek Kecukupan Pakan',
                    subtitle: 'Periksa kecukupan pakan sapi Anda',
                    icon: Icons.verified,
                    iconBg: const Color(0xFFE2F1DB),
                    iconColor: const Color(0xFF2E7D32),
                    cardColor: cardColor,
                    textColor: brownText,
                    onTap: _bukaCekKecukupan,
                  ),
                  const SizedBox(height: 14),
                  _MenuCard(
                    title: 'Master Bahan Pakan',
                    subtitle: 'Kelola sediaan & cek kandungan nutrisi',
                    icon: Icons.inventory_2,
                    iconBg: const Color(0xFFF4E7C5),
                    iconColor: const Color(0xFF9C6B00),
                    cardColor: cardColor,
                    textColor: brownText,
                    onTap: _bukaCekKandungan,
                  ),
                  const SizedBox(height: 14),
                  _MenuCard(
                    title: 'Simulator Formulasi Ransum',
                    subtitle: 'Rancang ransum dari sediaan pakan',
                    icon: Icons.calculate,
                    iconBg: const Color(0xFFEADBC8),
                    iconColor: const Color(0xFF8D5B2A),
                    cardColor: cardColor,
                    textColor: brownText,
                    onTap: _bukaFormulasi,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTapBottomNav,
        selectedItemColor: greenDark,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: backgroundColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Tentang'),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.cardColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 30, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 30,
                color: textColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}