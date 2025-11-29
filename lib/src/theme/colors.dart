import 'package:flutter/material.dart';

class AppColors {
  // Primary & Accent
  static const Color primary = Color(0xFF1E88E5); // Royal Blue 700
  static const Color accent = Color(0xFFFF9800); // Bright Orange

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color backgroundLight = Color(
    0xFFF5F7FA,
  ); // Slightly off-white for neumorphism
  static const Color backgroundDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Shadows
  static const Color shadowLight = Color.fromRGBO(30, 136, 229, 0.08);
  static const Color shadowDark = Color.fromRGBO(0, 0, 0, 0.5);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Getters for current theme
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? surfaceLight
      : surfaceDark;

  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? backgroundLight
      : backgroundDark;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? textPrimaryLight
      : textPrimaryDark;
}
