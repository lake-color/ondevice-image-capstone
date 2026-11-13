import 'package:flutter/material.dart';

/// Colors that define the app's look and are shared across pages.
/// A tint used by a single widget stays next to that widget.
abstract final class AppColors {
  static const primary = Color(0xFF5A54DE);
  static const primarySoft = Color(0xFFEAE8FF);
  static const background = Color(0xFFF9FAFD);

  static const text = Color(0xFF151927);
  static const textMuted = Color(0xFF717583);

  static const border = Color(0xFFD9DCE6);
  static const borderStrong = Color(0xFFABADB5);

  // Notice cards and destructive actions.
  static const danger = Color(0xFFFF6B72);
  static const dangerSurface = Color(0xFFFFFBFB);
  static const dangerSoft = Color(0xFFFFEEEE);
  static const dangerBorder = Color(0xFFFFC5C8);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.background,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamilyFallback: const ['Noto Sans KR', 'Malgun Gothic', 'sans-serif'],
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(color: AppColors.textMuted, height: 1.45),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
