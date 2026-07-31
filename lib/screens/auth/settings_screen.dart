import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  late Map<String, dynamic> _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPreferences();
  }

  void _loadPreferences() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      setState(() {
        _preferences = Map<String, dynamic>.from(authProvider.user!.preferences);
      });
    }
  }

  String get _currentLanguage {
    return _preferences['language'] as String? ?? 'fr';
  }

  bool get _notificationsEnabled {
    return _preferences['notifications'] as bool? ?? true;
  }

  Future<void> _updatePreferences() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token non disponible');
      }

      // Mettre à jour les préférences via le provider
      await authProvider.updateProfile(
        preferences: _preferences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences mises à jour avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeLanguage(String language) {
    setState(() {
      _preferences['language'] = language;
    });
    _updatePreferences();
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _preferences['notifications'] = value;
    });
    _updatePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.darkBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section Langue
                  _buildSectionTitle('Langue', isDark),
                  const SizedBox(height: 12),
                  _buildLanguageSelector(isDark),
                  const SizedBox(height: 32),

                  // Section Notifications
                  _buildSectionTitle('Notifications', isDark),
                  const SizedBox(height: 12),
                  _buildNotificationToggle(isDark),
                  const SizedBox(height: 32),

                  // Informations sur les préférences
                  _buildInfoCard(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    return Container(
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
          _buildLanguageOption(
            'Français',
            'fr',
            '🇫🇷',
            isDark,
          ),
          const Divider(height: 1),
          _buildLanguageOption(
            'English',
            'en',
            '🇬🇧',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, String value, String flag, bool isDark) {
    final isSelected = _currentLanguage == value;

    return InkWell(
      onTap: () => _changeLanguage(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                FontAwesomeIcons.check,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkTextMuted.withOpacity(0.1)
              : AppTheme.lightTextMuted.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.bell,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications push',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _notificationsEnabled ? 'Activées' : 'Désactivées',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeColor: Colors.white,
            activeTrackColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            FontAwesomeIcons.circleInfo,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À propos des préférences',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos préférences sont automatiquement sauvegardées et synchronisées sur tous vos appareils.',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}