import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'route/router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';

// Import pour accéder au homeScreenKey
import 'screens/home/home_screen.dart' as home;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase (requiert google-services.json / GoogleService-Info.plist)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase non initialisé: $e');
  }

  runApp(const KivooApp());
}

class KivooApp extends StatelessWidget {
  const KivooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Kivoo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _wasAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    // `watch` force le rebuild quand l'état d'authentification change
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final isAuthenticated = authProvider.isAuthenticated;

    // Initialiser/rafraîchir les notifications quand l'utilisateur est connecté
    if (isAuthenticated) {
      if (!_wasAuthenticated) {
        // L'utilisateur vient de se connecter (ou premier démarrage avec session)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!notificationProvider.isInitialized) {
            notificationProvider.initialize();
          } else {
            notificationProvider.refresh();
          }
        });
      }
    }

    _wasAuthenticated = isAuthenticated;

    // Afficher un écran de chargement pendant l'initialisation
    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Afficher l'accueil (HomeScreen) dans tous les cas
    return HomeScreen(key: home.homeScreenKey);
  }
}