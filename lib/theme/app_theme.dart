import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF1D4ED8);
  static const Color lightBlue = Color(0xFF60A5FA);

  static const Color darkBackground = Color(0xFF12161a);
  static const Color darkCard = Color(0xFF1d232a);
  static const Color darkSurface = Color(0xFF252d36);
  static const Color darkText = Color(0xFFffffff);
  static const Color darkTextMuted = Color(0xFF9ca3af);
  static const Color darkTextFaint = Color(0xFF4b5563);

  static const Color lightBackground = Color(0xFFf0f2f5);
  static const Color lightCard = Color(0xFFffffff);
  static const Color lightSurface = Color(0xFFf5f6f8);
  static const Color lightText = Color(0xFF111827);
  static const Color lightTextMuted = Color(0xFF6b7280);
  static const Color lightTextFaint = Color(0xFF9ca3af);

  static String get fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';

  static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        primaryContainer: darkBlue,
        secondary: darkSurface,
        surface: darkCard,
        background: darkBackground,
        error: primaryBlue,
        onPrimary: Colors.white,
        onSecondary: darkText,
        onSurface: darkText,
        onBackground: darkText,
        onError: Colors.white,
        outline: Color(0xFF3d4752),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBlue,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: const BorderSide(color: Color(0xFF3d4752), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );

  static ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: darkBlue,
        secondary: lightSurface,
        surface: lightCard,
        background: lightBackground,
        error: primaryBlue,
        onPrimary: Colors.white,
        onSecondary: lightText,
        onSurface: lightText,
        onBackground: lightText,
        onError: Colors.white,
        outline: Color(0xFFe5e7eb),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBlue,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: const BorderSide(color: Color(0xFFf0f2f5), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: Color(0xFFd1d5db), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: Color(0xFFd1d5db), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
}