import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Kivoo';
  static const String appVersion = '1.0.0';

  // Colors
  static const int primaryBlue = 0xFF2563EB;
  static const int darkBlue = 0xFF1D4ED8;

  // Status Bar
  static const String statusBarTime = '9:41';

  // Mock Data Locations
  static const List<String> locations = [
    'Lagos',
    'Abuja',
    'Port Harcourt',
    'Kano',
    'Ibadan',
    'Enugu',
  ];

  // Mock Data Filters
  static const List<String> filters = [
    'All',
    'Electronics',
    'Vehicles',
    'Real Estate',
    'Fashion',
  ];

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Padding & Spacing
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double mediumPadding = 12;
  static const double largePadding = 24;

  // Border Radius
  static const double smallBorderRadius = 8;
  static const double mediumBorderRadius = 12;
  static const double largeBorderRadius = 16;
  static const double extraLargeBorderRadius = 20;

  // Font Sizes
  static const double fontSizeSmall = 10;
  static const double fontSizeMedium = 12;
  static const double fontSizeLarge = 14;
  static const double fontSizeXLarge = 15;
  static const double fontSizeXXLarge = 18;

  // Font Weights
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // Image Dimensions
  static const double featuredCardWidth = 155;
  static const double featuredCardHeight = 180;
  static const double categoryItemSize = 70;
  static const double listItemImageSize = 78;
  static const double gridItemImageSize = 160;

  // Bottom Navigation
  static const double bottomNavHeight = 80;
  static const double fabSize = 56;

  // Search Bar
  static const double searchBarHeight = 44;
  static const double searchButtonSize = 36;

  // Card Shadows
  static const double cardShadowBlurRadius = 16;
  static const double cardShadowOffset = 4;

  // Haptic Feedback
  static const Duration hapticFeedbackDuration = Duration(milliseconds: 10);

  // API
  //static const String baseUrl = 'http://192.168.100.50:5000/api';
  //static const String baseUrl = 'http://192.168.223.14:5000/api';
  static const String baseUrl = 'https://kivoo-api.vercel.app/api';
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String socialLoginEndpoint = '/auth/social-login';
  static const String uploadPhotoEndpoint = '/auth/upload-photo';
  static const String uploadsBaseUrl = 'https://kivoo-api.vercel.app/uploads';

  // Firebase Web (PWA)
  // Clé VAPID pour les notifications push FCM sur le web (Firebase Console >
  // Paramètres du projet > Cloud Messaging > Certificats push Web).
  // Laisser vide désactive le push web sans casser l'application.
  static const String fcmVapidKey = '';

  // PWA : largeur maximale (px) du contenu sur grand écran. Sur desktop, la
  // web app garde une mise en page "mobile" centrée, identique à la native.
  static const double webMaxContentWidth = 480;
}
