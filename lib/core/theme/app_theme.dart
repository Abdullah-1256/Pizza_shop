import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const primaryColor = Color(0xFFC67C4E);
  static const secondaryColor = Color(0xFFFFF5EE);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF9F9F9);
  static const errorColor = Color(0xFFED5151);

  // Text Colors
  static const textPrimary = Color(0xFF2F2D2C);
  static const textSecondary = Color(0xFF9B9B9B);
  static const textDisabled = Color(0xFFB0B0B0);

  // Other Colors
  static const dividerColor = Color(0xFFEAEAEA);
  static const shadowColor = Color(0x1A000000);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      background: backgroundColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: GoogleFonts.soraTextTheme().copyWith(
      displayLarge: const TextStyle(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: const TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: textDisabled, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
  );

  // Dark Theme (to be implemented)
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF0C0F14),
    // Add other dark theme configurations
  );
}
