import 'package:flutter/material.dart';

/// Palet warna Universitas Mulia (diambil dari slide materi & lambang universitas).
class UmColors {
  static const navy = Color(0xFF002060);
  static const red = Color(0xFFE31B23);
  static const yellow = Color(0xFFF4C400);
  static const blue = Color(0xFF1155CC);
  static const green = Color(0xFF20A464);
  static const background = Color(0xFFF4F6FB);
}

ThemeData buildUmTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: UmColors.navy,
    brightness: Brightness.light,
  ).copyWith(
    primary: UmColors.navy,
    onPrimary: Colors.white,
    secondary: UmColors.red,
    onSecondary: Colors.white,
    tertiary: UmColors.yellow,
    onTertiary: UmColors.navy,
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: UmColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: UmColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: UmColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: UmColors.navy,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: UmColors.navy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: UmColors.navy, width: 2),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: UmColors.navy,
    ),
  );
}
