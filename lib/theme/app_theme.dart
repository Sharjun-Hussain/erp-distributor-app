import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    },
  );

  static AppBarTheme _appBarTheme({
    required Color background,
    required Color foreground,
  }) {
    return AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 48,
      titleSpacing: 16,
      iconTheme: const IconThemeData(size: 20),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    );
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.light,
        ),
        primaryColor: AppColors.brand,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: GoogleFonts.interTextTheme(),
        pageTransitionsTheme: _pageTransitions,
        appBarTheme: _appBarTheme(
          background: AppColors.backgroundLight,
          foreground: AppColors.textMainLight,
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: AppColors.brand,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.dark,
        ),
        primaryColor: AppColors.brand,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: AppColors.textMainDark,
          displayColor: AppColors.textMainDark,
        ),
        pageTransitionsTheme: _pageTransitions,
        appBarTheme: _appBarTheme(
          background: AppColors.backgroundDark,
          foreground: AppColors.textMainDark,
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: AppColors.brand,
          brightness: Brightness.dark,
        ),
      );
}
