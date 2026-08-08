import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Affiche une boîte de dialogue avec le numéro de téléphone du vendeur
Future<void> showPhoneNumberDialog(
  BuildContext context, {
  required String phoneNumber,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
      final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
      final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;

      return Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.phone,
                    color: AppTheme.primaryBlue,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Numéro du vendeur',
                style: TextStyle(
                  color: textColor,
                  fontSize: Responsive.fontSize(context, 18),
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Numéro de téléphone
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  phoneNumber,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Appelez ce numéro pour contacter le vendeur',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: Responsive.fontSize(context, 13),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Bouton fermer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                  label: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}