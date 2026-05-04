import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AntigravityTheme {
  // Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFFEC4899); // Pink
  static const Color accent = Color(0xFF10B981); // Emerald
  
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  
  static const Color glassBase = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Shadows
  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withAlpha((255 * 0.1).toInt()),
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: primary.withAlpha((255 * 0.1).toInt()),
          blurRadius: 40,
          spreadRadius: -5,
          offset: const Offset(0, 20),
        ),
      ];

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surfaceDark,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
    );
  }
}
