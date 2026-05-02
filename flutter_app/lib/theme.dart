import 'package:flutter/material.dart';

const Color _appBackground = Color(0xFF070B14);
const Color _appSurface = Color(0xFF101826);
const Color _appSurfaceVariant = Color(0xFF182235);
const Color _appPrimary = Color(0xFF2F80FF);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _appPrimary,
    brightness: Brightness.dark,
    surface: _appSurface,
    background: _appBackground,
  ).copyWith(
    primary: _appPrimary,
    secondary: const Color(0xFF60A5FA),
    surface: _appSurface,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: _appBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: _appSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _appSurfaceVariant,
    hintStyle: const TextStyle(color: Color(0xFF8CA3C0)),
    labelStyle: const TextStyle(color: Color(0xFFB8C7D9)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF25344D)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _appPrimary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _appPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _appPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF33507A)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Color(0xFFD3DCE8)),
    bodyMedium: TextStyle(color: Color(0xFFB8C7D9)),
    bodySmall: TextStyle(color: Color(0xFF90A2B9)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF24334B), thickness: 1),
);