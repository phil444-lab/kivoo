import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/feature_card_model.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class FeatureCard extends StatelessWidget {

  const FeatureCard({
    super.key,
    required this.card,
    required this.isDark,
    this.onTap,
  });
  final FeatureCardModel card;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(int.parse(card.borderColor.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _parseGradient(isDark ? card.darkBg : card.lightBg),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor.withValues(alpha: 0.2),
                      cardColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cardColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                // 2. Gestion dynamique de l'icône (FontAwesome / Material)
                child: Center(
                  child: _buildIcon(card.icon, cardColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                card.title,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontWeight: FontWeight.w700,
                  fontSize: Responsive.fontSize(context, 13),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: cardColor,
                  fontSize: Responsive.fontSize(context, 11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper pour basculer entre FaIcon et Icon sans erreur de type
  Widget _buildIcon(dynamic icon, Color color) {
    if (icon is IconData) {
      return Icon(icon, color: color, size: 28);
    }
    return FaIcon(icon, color: color, size: 28);
  }

  List<Color> _parseGradient(String gradient) {
    if (gradient.contains('#142035')) {
      return const [Color(0xFF142035), Color(0xFF0e1a2e)];
    } else if (gradient.contains('#0f2718')) {
      return const [Color(0xFF0f2718), Color(0xFF0a2014)];
    } else if (gradient.contains('#241a06')) {
      return const [Color(0xFF241a06), Color(0xFF1c1404)];
    } else if (gradient.contains('#1c0e34')) {
      return const [Color(0xFF1c0e34), Color(0xFF160828)];
    } else if (gradient.contains('#deeaff')) {
      return const [Color(0xFFdeeaff), Color(0xFFc8daff)];
    } else if (gradient.contains('#dcfce7')) {
      return const [Color(0xFFdcfce7), Color(0xFFc5f4d4)];
    } else if (gradient.contains('#fef3c7')) {
      return const [Color(0xFFfef3c7), Color(0xFFfde8a0)];
    } else if (gradient.contains('#f3e8ff')) {
      return const [Color(0xFFf3e8ff), Color(0xFFe9d5ff)];
    }
    return [Colors.grey, Colors.grey.shade300];
  }
}