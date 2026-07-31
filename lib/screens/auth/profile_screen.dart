import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/location_model.dart';
import 'login_screen.dart';
import 'privacy_screen.dart';
import 'register_screen.dart';
import 'terms_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    // Si non authentifié, afficher l'écran de connexion/inscription
    if (!authProvider.isAuthenticated) {
      return _buildNotAuthenticated(context, isDark);
    }

    // Si authentifié, afficher le profil
    return _buildAuthenticatedProfile(context, isDark, authProvider);
  }

  Widget _buildNotAuthenticatedBody(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final useScroll = availableHeight < 550;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 1),

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
              'Bienvenue sur KIVOO',
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Achetez et vendez en toute simplicité.',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Rejoignez la plus grande communauté d\'achats et de ventes près de chez vous. Des milliers d\'annonces de voitures, téléphones, biens immobiliers, mode et services disponibles au bout des doigts.',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Connectez-vous pour accéder à votre profil',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(flex: 1),

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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Register button
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
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text.rich(
              TextSpan(
                text: 'En cliquant sur Connexion ou Inscription, vous acceptez nos ',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: 'Conditions d\'utilisation',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsScreen(),
                          ),
                        );
                      },
                  ),
                  const TextSpan(text: ' et notre '),
                  TextSpan(
                    text: 'Politique de confidentialité',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyScreen(),
                          ),
                        );
                      },
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(flex: 1),
          ],
        );

        if (useScroll) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SizedBox(
              height: availableHeight - 48,
              child: content,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: content,
        );
      },
    );
  }

  Widget _buildNotAuthenticated(BuildContext context, bool isDark) {
    final body = _buildNotAuthenticatedBody(context, isDark);

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            FontAwesomeIcons.arrowLeft,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _buildAuthenticatedBody(BuildContext context, bool isDark, AuthProvider authProvider) {
    final user = authProvider.user!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Avatar
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  border: Border.all(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    width: 3,
                  ),
                ),
                child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? _buildAvatarImage(user.photoUrl!, user.name)
                    : Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              user.name,
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Email
            Text(
              user.email,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.phone,
                  size: 12,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  user.phone,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            // Location
            if (user.location != null && (user.location as Map<String, dynamic>).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.locationDot,
                      size: 12,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      UserLocation.fromJson(user.location as Map<String, dynamic>).formatted,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Stats
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Note',
                      user.rating.toStringAsFixed(1),
                      FontAwesomeIcons.star,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Avis',
                      user.ratingCount.toString(),
                      FontAwesomeIcons.comment,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Membre depuis',
                      '${DateTime.now().difference(user.joinedAt).inDays.abs()} j',
                      FontAwesomeIcons.calendar,
                      isDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Menu items
            _buildMenuItem(
              'Modifier le profil',
              FontAwesomeIcons.userPen,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              'Mes annonces',
              FontAwesomeIcons.store,
              isDark,
              () {},
            ),
            _buildMenuItem(
              'Favoris',
              FontAwesomeIcons.heart,
              isDark,
              () {},
            ),
            _buildMenuItem(
              'Paramètres',
              FontAwesomeIcons.gear,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Logout button
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    // Afficher un snackbar de déconnexion
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Déconnexion réussie !'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    if (showAppBar) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(
                  FontAwesomeIcons.rightFromBracket,
                  color: Colors.red,
                  size: 18,
                ),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, bool isDark, AuthProvider authProvider) {
    final body = _buildAuthenticatedBody(context, isDark, authProvider);

    if (!showAppBar) {
      return body;
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Profil Utilisateur',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.darkBlue,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.white,
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _buildAvatarImage(String photoUrl, String userName) {
    // Utiliser Image.network pour toutes les URLs (plus de base64)
    return ClipOval(
      child: Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, widget) {
          return _buildFallbackAvatar(userName);
        },
      ),
    );
  }

  Widget _buildFallbackAvatar(String userName) {
    return Center(
      child: Text(
        userName.isNotEmpty
            ? userName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextMuted.withOpacity(0.1)
              : AppTheme.lightTextMuted.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextMuted.withOpacity(0.1)
              : AppTheme.lightTextMuted.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          FontAwesomeIcons.chevronRight,
          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          size: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}