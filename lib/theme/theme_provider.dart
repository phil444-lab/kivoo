import 'package:flutter/material.dart';

/// Three theme modes: System (follows device), Light, Dark
enum AppThemeMode {
  system,
  light,
  dark,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode appThemeMode = AppThemeMode.system;

  bool get isDark {
    if (appThemeMode == AppThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return appThemeMode == AppThemeMode.dark;
  }

  ThemeMode get themeMode {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  IconData get icon {
    switch (appThemeMode) {
      case AppThemeMode.system:
        return Icons.brightness_auto_rounded;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String get label {
    switch (appThemeMode) {
      case AppThemeMode.system:
        return 'Auto';
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.dark:
        return 'Sombre';
    }
  }

  void cycleTheme() {
    switch (appThemeMode) {
      case AppThemeMode.system:
        appThemeMode = AppThemeMode.light;
        break;
      case AppThemeMode.light:
        appThemeMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        appThemeMode = AppThemeMode.system;
        break;
    }
    notifyListeners();
  }

  void setTheme(AppThemeMode mode) {
    appThemeMode = mode;
    notifyListeners();
  }
}