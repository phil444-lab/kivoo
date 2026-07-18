import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFe42226);
  static const Color darkRed = Color(0xFFbc171a);
  static const Color lightRed = Color(0xFFef7d7f);

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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        primaryContainer: darkRed,
        secondary: darkSurface,
        surface: darkCard,
        background: darkBackground,
        error: primaryRed,
        onPrimary: Colors.white,
        onSecondary: darkText,
        onSurface: darkText,
        onBackground: darkText,
        onError: Colors.white,
        outline: Color(0xFF3d4752),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkRed,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: const BorderSide(color: Color(0xFF3d4752), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
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
          borderSide: const BorderSide(color: primaryRed, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        primaryContainer: darkRed,
        secondary: lightSurface,
        surface: lightCard,
        background: lightBackground,
        error: primaryRed,
        onPrimary: Colors.white,
        onSecondary: lightText,
        onSurface: lightText,
        onBackground: lightText,
        onError: Colors.white,
        outline: Color(0xFFe5e7eb),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkRed,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: const BorderSide(color: Color(0xFFf0f2f5), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
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
        fillColor: lightSurface,
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
          borderSide: const BorderSide(color: primaryRed, width: 1.5),
        ),
      ),
    );
  }
}