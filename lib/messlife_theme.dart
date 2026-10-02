import 'package:flutter/material.dart';

abstract final class MessLifeColors {
  // Palette taken from messlife_appicon.png
  static const ink = Color(0xFF2B2D8A); // fork / spoon / outlines
  static const gradientStart = Color(0xFF3F4BA8);
  static const gradientEnd = Color(0xFF261C66);
  static const inkDark = Color(0xFF1B1550); // darker shade for splash background

  static const cream = Color(0xFFF5F2EA);
  static const red = Color(0xFFD42026);
  static const redDark = Color(0xFF98151A);

  static const textPrimary = ink;
  static const background = Color(0xFFF7F5EF);
}

final messLifeTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: MessLifeColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: MessLifeColors.ink,
    primary: MessLifeColors.ink,
    secondary: MessLifeColors.red,
    error: MessLifeColors.red,
    surface: MessLifeColors.cream,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: MessLifeColors.ink,
    foregroundColor: MessLifeColors.cream,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: MessLifeColors.red,
    foregroundColor: MessLifeColors.cream,
  ),
);