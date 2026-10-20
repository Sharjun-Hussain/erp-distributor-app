import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color brand = Color(0xFF6366F1); // Indigo

  // Light Theme
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceMutedLight = Color(0xFFE2E8F0);
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color glassBorderLight = Color(0x0D000000);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF000000);
  static const Color cardDark = Color(0xFF18181B);
  static const Color surfaceDark = Color(0xFF09090B);
  static const Color surfaceMutedDark = Color(0xFF27272A);
  static const Color textMainDark = Color(0xFFF4F4F5);
  static const Color textSecondaryDark = Color(0xFF71717A);
  static const Color glassBorderDark = Color(0x14FFFFFF);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}

extension ThemeColorsExt on ThemeData {
  bool get isDark => brightness == Brightness.dark;

  Color get bgColor =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get cardColor => isDark ? AppColors.cardDark : AppColors.cardLight;
  Color get surfaceColor =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get surfaceMutedColor =>
      isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight;

  Color get textMain =>
      isDark ? AppColors.textMainDark : AppColors.textMainLight;
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get glassBorder =>
      isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;
}
