import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (from color-guide.md)
  static const Color primaryBlue = Color(0xFF1E3A8A); // Biru Undip
  static const Color secondaryGreen = Color(
    0xFF00BF63,
  ); // Official Emerald Green (High Contrast & Saturated)
  static const Color accentOrange = Color(0xFFF97316); // Oranye
  static const Color expertPurple = Color(0xFF4D2647); // Ungu Veterinarian

  // Neutral & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceLow = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Soft Tint Backgrounds (for Chips, Cards, Badges)
  static const Color primaryLight = Color(0xFFEFF6FF); // Blue 50
  static const Color secondaryLight = Color(0xFFECFDF5); // Emerald 50
  static const Color accentLight = Color(0xFFFFF7ED); // Orange 50
  static const Color expertLight = Color(0xFFFDF4FA); // Purple 50
  static const Color dangerLight = Color(0xFFFEF2F2); // Red 50

  // Status Colors (Indikator Kecukupan Nutrisi)
  static const Color statusPas = Color(0xFF00BF63); // 🟢 Pas (Emerald Green)
  static const Color statusBerlebih = Color(0xFF1E3A8A); // 🔵 Berlebih (Biru Undip)
  static const Color statusKurang = Color(0xFFBA1A1A); // 🔴 Kurang (Merah)

  // Aliases for compatibility
  static const Color primaryGreen = Color(0xFF1E3A8A); // primaryBlue
  static const Color backgroundCream = Color(0xFFF8FAFC); // background
  static const Color backgroundKrem = Color(0xFFF8FAFC); // background
  static const Color cardWhite = Colors.white; // surface
  static const Color textDark = Color(0xFF0F172A); // textPrimary
  static const Color textLight = Color(0xFF64748B); // textSecondary
  static const Color textGrey = Color(0xFF64748B); // textSecondary
  static const Color accentGreen = Color(0xFF00BF63); // secondaryGreen
  static const Color errorRed = Color(0xFFBA1A1A);
}

