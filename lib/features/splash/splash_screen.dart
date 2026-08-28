import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for 3 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Center Content (Logo DipoFeed + Loading Indicator + Text)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DipoFeed Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo_dipofeed.jpeg',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Loading Indicator
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Loading Text
                    Text(
                      'Menyiapkan data pakan & nutrisi...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Partnership Footer (UNDIP & ACIAR)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KOLABORASI RISET',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_undip.png',
                        height: 34,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 20,
                        width: 1.2,
                        color: Colors.grey.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/images/logo_aciar.png',
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
