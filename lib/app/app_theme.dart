import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const primary = Color(0xFF5A54DE);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: const Color(0xFFF9FAFD),
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF9FAFD),
      fontFamilyFallback: const ['Noto Sans KR', 'Malgun Gothic', 'sans-serif'],
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF151927),
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF151927),
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF151927),
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: TextStyle(color: Color(0xFF717583), height: 1.45),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFF9FAFD),
        foregroundColor: Color(0xFF151927),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
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
          foregroundColor: const Color(0xFF151927),
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Color(0xFFD9DCE6)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
