import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/favorites_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'route_constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.home:
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: settings,
        );
      
      case RouteConstants.favorites:
        return MaterialPageRoute(
          builder: (context) => const FavoritesScreen(),
          settings: settings,
        );
      
      case RouteConstants.saved:
        return MaterialPageRoute(
          builder: (context) => const PlaceholderScreen(title: 'Saved'),
          settings: settings,
        );
      
      case RouteConstants.sell:
        return MaterialPageRoute(
          builder: (context) => const PlaceholderScreen(title: 'Sell'),
          settings: settings,
        );
      
      case RouteConstants.messages:
        return MaterialPageRoute(
          builder: (context) => const PlaceholderScreen(title: 'Messages'),
          settings: settings,
        );
      
      case RouteConstants.profile:
        return MaterialPageRoute(
          builder: (context) => const PlaceholderScreen(title: 'Profile'),
          settings: settings,
        );
      
      case RouteConstants.login:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
          settings: settings,
        );
      
      case RouteConstants.signup:
        return MaterialPageRoute(
          builder: (context) => const RegisterScreen(),
          settings: settings,
        );
      
      default:
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: settings,
        );
    }
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBlue,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Text(
          '$title Screen',
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}