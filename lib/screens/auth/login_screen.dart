import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive.dart';
import '../../screens/home/home_screen.dart' as home;
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/logo-2048.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Connexion',
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontSize: Responsive.fontSize(context, 28),
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Content de vous revoir !',
                style: TextStyle(
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: Responsive.fontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Email or Phone field
              TextField(
                controller: _identifierController,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  labelText: 'Email ou téléphone',
                  labelStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                  prefixIcon: Align(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  labelStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                  prefixIcon: Align(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: FaIcon(
                      FontAwesomeIcons.lock,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      _obscurePassword
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login button
              Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppTheme.darkTextMuted.withOpacity(0.3)
                          : AppTheme.lightTextMuted.withOpacity(0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ou',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                      fontSize: Responsive.fontSize(context, 13),
                    ),
                  ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppTheme.darkTextMuted.withOpacity(0.3)
                          : AppTheme.lightTextMuted.withOpacity(0.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Google button
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkTextMuted.withOpacity(0.2)
                        : AppTheme.lightTextMuted.withOpacity(0.2),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(3.0),
                      child: FaIcon(
                        FontAwesomeIcons.google,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                  label: Text(
                    'Continuer avec Google',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontSize: Responsive.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.lightTextMuted,
                      fontSize: Responsive.fontSize(context, 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'S\'inscrire',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: Responsive.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loginWithGoogle();

      if (mounted) {
        // Afficher un snackbar de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        // Rafraîchir le compteur de messages non lus
        try {
          final homeState = home.homeScreenKey.currentState;
          await homeState?.refreshUnreadCount();
        } catch (e) {
          debugPrint('Error refreshing unread count: $e');
        }
        // Retourner à l'écran précédent (ProfileScreen)
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleLogin() async {
    // Masque le clavier sans déclencher de glitch de surface
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Afficher un snackbar de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        // Rafraîchir le compteur de messages non lus
        try {
          final homeState = home.homeScreenKey.currentState;
          await homeState?.refreshUnreadCount();
        } catch (e) {
          debugPrint('Error refreshing unread count: $e');
        }
        // Retourner à l'écran précédent (ProfileScreen) qui se reconstruira
        // avec l'état authentifié grâce à AuthProvider
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
