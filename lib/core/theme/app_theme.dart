import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkNavy = Color(0xFF1A1D24);
  static const Color slateGrey = Color(0xFF2A2D34);
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkNavy,
    primaryColor: accentBlue,
    cardColor: slateGrey,
    
    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: slateGrey,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: textPrimary,
      size: 24,
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: darkNavy,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}