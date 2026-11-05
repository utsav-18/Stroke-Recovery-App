import 'package:flutter/material.dart';

// Hospital-Grade Clinical Light Palette
const Color appBackground = Color(0xFFF8FAFC); // Clean clinical slate-50
const Color appSurface = Color(0xFFFFFFFF); // Pure hospital white
const Color appSurfaceVariant = Color(0xFFF1F5F9); // Light clinical slate-100
const Color appPrimary = Color(0xFF0D47A1); // Deep Hospital Navy (Medical authoritative)
const Color appSecondary = Color(0xFF0284C7); // Clinical Sky/Teal accent
const Color appBorder = Color(0xFFE2E8F0); // Subtle 1px medical divider border
const Color appTextPrimary = Color(0xFF0F172A); // Slate-900 high contrast text
const Color appTextSecondary = Color(0xFF475569); // Slate-600 clinical body
const Color appTextMuted = Color(0xFF94A3B8); // Slate-400 label text

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: appPrimary,
    brightness: Brightness.light,
    surface: appSurface,
  ).copyWith(
    primary: appPrimary,
    secondary: appSecondary,
    surface: appSurface,
    onSurface: appTextPrimary,
    onPrimary: Colors.white,
    outline: appBorder,
  ),
  scaffoldBackgroundColor: appBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: appSurface,
    surfaceTintColor: Colors.transparent,
    foregroundColor: appTextPrimary,
    centerTitle: false,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: appTextPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    iconTheme: IconThemeData(color: appTextPrimary),
    shape: Border(bottom: BorderSide(color: appBorder, width: 1)),
  ),
  cardTheme: CardThemeData(
    color: appSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: appBorder, width: 1),
    ),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: appSurface,
    hintStyle: const TextStyle(color: appTextMuted, fontSize: 14),
    labelStyle: const TextStyle(color: appTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: appBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: appBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: appPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: appPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: appPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: appPrimary,
      side: const BorderSide(color: appBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: appTextPrimary, fontWeight: FontWeight.w800),
    headlineLarge: TextStyle(color: appTextPrimary, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(color: appTextPrimary, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(color: appTextPrimary, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(color: appTextPrimary, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(color: appTextPrimary, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: appTextSecondary, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: appTextPrimary, fontSize: 16),
    bodyMedium: TextStyle(color: appTextSecondary, fontSize: 14),
    bodySmall: TextStyle(color: appTextMuted, fontSize: 12),
  ),
  dividerTheme: const DividerThemeData(color: appBorder, thickness: 1),
);
