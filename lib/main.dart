import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'route/router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/data_cache_provider.dart';
import 'constants.dart';

// Import pour accéder au homeScreenKey
import 'screens/home/home_screen.dart' as home;

// ====== CONFIGURATION FIREBASE WEB (PWA) ======
// Récupérez ces valeurs dans Firebase Console > Paramètres du projet >
// Vos applications > Web, puis passez [_kFirebaseWebConfigured] à true.
// Tant que cette config n'est pas renseignée, l'app web fonctionne mais les
// notifications push web restent désactivées.
const bool _kFirebaseWebConfigured = false;
const FirebaseOptions _kFirebaseWebOptions = FirebaseOptions(
  apiKey: 'VOTRE_WEB_API_KEY',
  appId: 'VOTRE_APP_ID_WEB',
  messagingSenderId: '329144921089',
  projectId: 'kivoo-d8521',
  storageBucket: 'kivoo-d8521.appspot.com',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase (requiert google-services.json / GoogleService-Info.plist)
  try {
    if (kIsWeb) {
      // PWA : configuration Firebase web (voir _kFirebaseWebOptions)
      if (_kFirebaseWebConfigured) {
        await Firebase.initializeApp(options: _kFirebaseWebOptions);
      } else {
        debugPrint('ℹ️ Web: config Firebase web non renseignée — '
            'notifications push web désactivées.');
      }
    } else {
      await Firebase.initializeApp();
    }
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
        ChangeNotifierProvider<DataCacheProvider>(
          create: (_) => DataCacheProvider()..initialize(),
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
            // Coquille "app mobile" : sur grand écran, le contenu reste
            // contraint à une largeur de téléphone et centré (PWA).
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final clampedWidth = mediaQuery.size.width.clamp(
                0.0,
                AppConstants.webMaxContentWidth,
              );
              return MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(clampedWidth, mediaQuery.size.height),
                ),
                child: MobileAppShell(child: child ?? const SizedBox.shrink()),
              );
            },
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

/// Contraint l'application à une largeur "mobile" et la centre sur les grands
/// écrans (web desktop / tablette), pour une expérience PWA identique à
/// l'app native.
class MobileAppShell extends StatelessWidget {
  final Widget child;

  const MobileAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxMobileWidth = AppConstants.webMaxContentWidth;

        // Écran "mobile" : on affiche plein cadre, sans décoration
        if (constraints.maxWidth <= maxMobileWidth) {
          return child;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          color: isDark ? const Color(0xFF090c10) : const Color(0xFFe5e7eb),
          alignment: Alignment.center,
          child: Container(
            width: maxMobileWidth,
            margin: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: child,
            ),
          ),
        );
      },
    );
  }
}