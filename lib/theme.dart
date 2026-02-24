// lib/theme.dart
import 'package:flutter/material.dart';

// ────────────────────────────────────────────────
// AÇIK TEMA (Light Theme) - Soft lavanta mor palet
// ────────────────────────────────────────────────

const Color lightPrimary = Color(0xFF6A1B9A);       // ana mor buton/accent
const Color lightSecondary = Color(0xFF8E24AA);     // ikincil mor
const Color lightBackground = Color(0xFFF3E8FF);    // çok açık mor arka plan
const Color lightSurface = Color(0xFFEDE7F6);       // kart/input dolgusu
const Color lightAccent = Color(0xFFBA68C8);        // vurgu, ikonlar
const Color lightTextPrimary = Color(0xFF1A0F24);   // ana metin (koyu)
const Color lightTextSecondary = Color(0xFF4A148C); // yardımcı metin

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: lightPrimary,
  scaffoldBackgroundColor: lightBackground,
  colorScheme: ColorScheme.light(
    primary: lightPrimary,
    secondary: lightSecondary,
    surface: lightSurface,
    background: lightBackground,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: lightTextPrimary,
    onBackground: lightTextPrimary,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: lightTextPrimary,
  ),
  cardTheme: CardThemeData(  // ← CardThemeData kullanıyoruz
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightPrimary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 3,
      shadowColor: lightPrimary.withAlpha(102), // 0.4 * 255 = 102
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: lightAccent, width: 2),
    ),
    labelStyle: TextStyle(color: lightTextSecondary),
    prefixIconColor: lightAccent,
    suffixIconColor: lightAccent,
  ),
  textTheme: TextTheme(
    headlineMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: lightTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: lightTextPrimary,
    ),
    bodyLarge: TextStyle(color: lightTextPrimary),
    bodyMedium: TextStyle(color: lightTextSecondary),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: lightAccent,
    circularTrackColor: lightSecondary.withAlpha(77), // 0.3 * 255 = 76.5 ≈ 77
  ),
);

// ────────────────────────────────────────────────
// KARANLIK TEMA (Dark Theme) - Derin mor/siyah palet
// ────────────────────────────────────────────────

const Color darkPrimary = Color(0xFF100725);       // en koyu mor - buton/accent
const Color darkSecondary = Color(0xFF220B39);     // kart/surface
const Color darkTertiary = Color(0xFF491358);      // hover/border vurgu
const Color darkAccent = Color(0xFF6E1F86);        // ikon, progress bar
const Color darkBackground = Color(0xFF0A0412);    // scaffold arka plan
const Color darkSurface = Color(0xFF1A0F24);       // kart/input dolgusu
const Color darkTextPrimary = Color(0xFFEBD9FF);   // ana metin (açık mor-beyaz)
const Color darkTextSecondary = Color(0xFFB79CFF); // yardımcı metin

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: darkPrimary,
  scaffoldBackgroundColor: darkBackground,
  colorScheme: ColorScheme.dark(
    primary: darkPrimary,
    secondary: darkSecondary,
    tertiary: darkTertiary,
    surface: darkSurface,
    background: darkBackground,
    onPrimary: darkTextPrimary,
    onSecondary: darkTextPrimary,
    onSurface: darkTextPrimary,
    onBackground: darkTextPrimary,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: darkTextPrimary,
  ),
  cardTheme: CardThemeData(
    color: darkSecondary.withAlpha(192), // 0.75 * 255 = 192
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkPrimary,
      foregroundColor: darkTextPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      elevation: 4,
      shadowColor: darkPrimary.withAlpha(128), // 0.5 * 255 = 128
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: darkAccent, width: 2),
    ),
    labelStyle: TextStyle(color: darkTextSecondary),
    prefixIconColor: darkAccent,
    suffixIconColor: darkAccent,
  ),
  textTheme: TextTheme(
    headlineMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: darkTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: darkTextPrimary,
    ),
    bodyLarge: TextStyle(color: darkTextPrimary),
    bodyMedium: TextStyle(color: darkTextSecondary),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: darkAccent,
    circularTrackColor: darkTertiary.withAlpha(77), // 0.3 * 255 = 76.5 ≈ 77
  ),
);

// ────────────────────────────────────────────────
// Tema seçimi yardımcı fonksiyonu (isteğe bağlı)
// ────────────────────────────────────────────────

ThemeData getAppTheme({required bool isDark}) {
  return isDark ? darkTheme : lightTheme;
}