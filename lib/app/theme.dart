import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color appBackground = Color(0xFF080B11);
const Color appSurface = Color(0xFF0F1420);
const Color appBorder = Color(0xFF1E2638);
const Color appTextPrimary = Color(0xFFF3F4F6);
const Color appTextSecondary = Color(0xFF9CA3AF);
const Color appSuccess = Color(0xFF10B981);
const Color appDanger = Color(0xFFEF4444);
const Color appAccentStart = Color(0xFF7C3AED);
const Color appAccentEnd = Color(0xFF6366F1);

ThemeData get appTheme {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: appBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: appAccentStart,
      brightness: Brightness.dark,
      primary: appAccentStart,
      secondary: appAccentEnd,
      surface: appSurface,
      onSurface: appTextPrimary,
    ),
    cardColor: appSurface,
    dividerColor: appBorder,
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
      bodyColor: appTextPrimary,
      displayColor: appTextPrimary,
    ),
  );

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: appBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: appTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: appBorder, width: 1),
      ),
      margin: const EdgeInsets.all(0),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: appSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: appBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: appBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: appAccentStart, width: 1.5),
      ),
      hintStyle: const TextStyle(color: appTextSecondary),
      labelStyle: const TextStyle(color: appTextSecondary),
    ),
    bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
      backgroundColor: appSurface,
      selectedItemColor: appTextPrimary,
      unselectedItemColor: appTextSecondary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
  );
}
