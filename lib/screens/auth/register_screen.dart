import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
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
                'Créer un compte',
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontSize: Responsive.fontSize(context, 28),
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Rejoignez Kivoo dès maintenant',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: Responsive.fontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Name field
              TextField(
                controller: _nameController,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  labelStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  prefixIcon: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Email field
              TextField(
                controller: _emailController,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  prefixIcon: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FaIcon(
                      FontAwesomeIcons.envelope,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Phone field
              TextField(
                controller: _phoneController,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  labelStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  prefixIcon: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FaIcon(
                      FontAwesomeIcons.phone,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
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
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  prefixIcon: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FaIcon(
                      FontAwesomeIcons.lock,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
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
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm password field
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  labelText: 'Confirmation',
                  labelStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  prefixIcon: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FaIcon(
                      FontAwesomeIcons.lock,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      _obscureConfirmPassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      size: Responsive.iconSize(context, 20),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),

              // Register button
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
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'S\'inscrire',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Terms and conditions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'En vous inscrivant, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité.',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppTheme.darkTextMuted.withValues(alpha: 0.3)
                          : AppTheme.lightTextMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ou',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark
                          ? AppTheme.darkTextMuted.withValues(alpha: 0.3)
                          : AppTheme.lightTextMuted.withValues(alpha: 0.3),
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
                        ? AppTheme.darkTextMuted.withValues(alpha: 0.2)
                        : AppTheme.lightTextMuted.withValues(alpha: 0.2),
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
                      padding: EdgeInsets.all(3),
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
                      fontSize: 15,
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

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Déjà un compte ? ',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 14,
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
      final success = await authProvider.loginWithGoogle();

      // success == false : connexion annulée par l'utilisateur (popup fermée)
      // → ni message de succès ni message d'erreur, on ne fait rien.
      if (success && mounted) {
        // Afficher un snackbar de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        // Retourner à l'écran précédent (ProfileScreen)
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleRegister() async {
    // Masque le clavier sans déclencher de glitch de surface
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validation des champs vides (côté client pour une meilleure UX)
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Le nom est requis';
        _isLoading = false;
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'L\'email est requis';
        _isLoading = false;
      });
      return;
    }

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Le téléphone est requis';
        _isLoading = false;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Le mot de passe est requis';
        _isLoading = false;
      });
      return;
    }

    // Validation confirmation mot de passe (côté client pour une meilleure UX)
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Les mots de passe ne correspondent pas';
        _isLoading = false;
      });
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Afficher un snackbar de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! Connectez-vous maintenant.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        // Rediriger vers la page de connexion après inscription
        // (la session est créée uniquement au login)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
