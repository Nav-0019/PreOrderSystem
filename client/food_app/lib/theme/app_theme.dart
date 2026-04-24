import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primaryBg = Color(0xFFFFF7ED);
  static const Color primaryBdr = Color(0xFFFED7AA);

  static const Color green = Color(0xFF22C55E);
  static const Color red = Color(0xFFEF4444);
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoBg = Color(0xFFEEF2FF);
  static const Color indigoBdr = Color(0xFFC7D2FE);
  static const Color yellow = Color(0xFFF59E0B);

  // Premium Membership Colors
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFFF8E1);
  static const Color goldBorder = Color(0xFFFFD54F);
  static const Color goldDark = Color(0xFFB8860B);
  
  static const Color darkHdr = Color(0xFF0F172A);

  // Light Theme Colors
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bg2Light = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textLight = Color(0xFF1E293B);
  static const Color text2Light = Color(0xFF64748B);
  static const Color text3Light = Color(0xFF94A3B8);

  // Dark Theme Colors
  static const Color bgDark = Color(0xFF0F172A);
  static const Color bg2Dark = Color(0xFF1E293B);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color text2Dark = Color(0xFF94A3B8);
  static const Color text3Dark = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bg2Light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: surfaceLight,
        error: red,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: surfaceLight,
      dividerColor: borderLight,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: bg2Dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: surfaceDark,
        error: red,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardColor: surfaceDark,
      dividerColor: borderDark,
    );
  }
}
