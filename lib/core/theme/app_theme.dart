import 'package:flutter/material.dart';

class AppTheme {
  static const teal = Color(0xFF00897B);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      );
}

extension ColorSchemeX on ColorScheme {
  Color get success => brightness == Brightness.light
      ? const Color(0xFF2E7D32)
      : const Color(0xFF66BB6A);

  Color get warning => brightness == Brightness.light
      ? const Color(0xFFF57C00)
      : const Color(0xFFFFB74D);

  Color get info => brightness == Brightness.light
      ? const Color(0xFF0288D1)
      : const Color(0xFF4FC3F7);

  Color get modified => warning;
  Color get added => success;
  Color get deleted => error;
  Color get untracked => info;
}
