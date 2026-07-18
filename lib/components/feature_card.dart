import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feature_card_model.dart';
import '../theme/app_theme.dart';

class FeatureCard extends StatelessWidget {
  final FeatureCardModel card;
  final bool isDark;

  const FeatureCard({
    super.key,
    required this.card,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
            color: Color(int.parse(card.borderColor.replaceFirst('#', '0xFF'))),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(int.parse(card.borderColor.replaceFirst('#', '0xFF'))).withOpacity(0.15),
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
                      Color(int.parse(card.borderColor.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                      Color(int.parse(card.borderColor.replaceFirst('#', '0xFF'))).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(int.parse(card.borderColor.replaceFirst('#', '0xFF'))).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  card.icon,
                  color: Color(int.parse(card.borderColor.replaceFirst('#', '0xFF'))),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                card.title,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: Color(int.parse(card.borderColor.replaceFirst('#', '0xFF'))),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _parseGradient(String gradient) {
    // Simple gradient parser for the predefined gradients
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