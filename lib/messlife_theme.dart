import 'package:flutter/material.dart';

abstract final class MessLifeColors {
  // Palette sampled from assets/icons/messlife_appicon.png
  static const ink = Color(0xFF0F2A52); // buttons, app bar, outlines
  static const gradientStart = Color(0xFF0B1F3A);
  static const gradientEnd = Color(0xFF153F6F);
  static const inkDark = Color(0xFF0B1F3A); // splash / dark backgrounds

  static const orange = Color(0xFFFF7B3D); // logo pin accent
  static const cream = Color(0xFFFFF8F2);
  static const red = Color(0xFFD42026); // errors
  static const redDark = Color(0xFF98151A);

  static const textPrimary = ink;
  static const background = Color(0xFFF6F8FC);
}

final messLifeTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: MessLifeColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: MessLifeColors.ink,
    primary: MessLifeColors.ink,
    secondary: MessLifeColors.orange,
    error: MessLifeColors.red,
    surface: MessLifeColors.cream,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: MessLifeColors.ink,
    foregroundColor: MessLifeColors.cream,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: MessLifeColors.orange,
    foregroundColor: MessLifeColors.inkDark,
  ),
);