import 'package:flutter/material.dart';

class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Retourne la largeur de l'écran
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Retourne la hauteur de l'écran
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Retourne true si c'est un mobile
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < mobileBreakpoint;
  }

  /// Retourne true si c'est une tablette
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Retourne true si c'est un desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= desktopBreakpoint;
  }

  /// Retourne un facteur d'échelle basé sur la largeur de l'écran
  /// Mobile (< 600): 1.0
  /// Tablet (600-900): 1.1
  /// Desktop (> 900): 1.2
  static double getScaleFactor(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) {
      return 1.0;
    } else if (width < tabletBreakpoint) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Adapte une taille de police selon l'écran
  static double fontSize(BuildContext context, double baseFontSize) {
    return baseFontSize * getScaleFactor(context);
  }

  /// Adapte une taille d'icône selon l'écran
  static double iconSize(BuildContext context, double baseIconSize) {
    return baseIconSize * getScaleFactor(context);
  }

  /// Adapte un padding selon l'écran
  static double padding(BuildContext context, double basePadding) {
    return basePadding * getScaleFactor(context);
  }

  /// Adapte une dimension selon l'écran
  static double dimension(BuildContext context, double baseDimension) {
    return baseDimension * getScaleFactor(context);
  }
}