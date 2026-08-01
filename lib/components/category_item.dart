import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 1. Import ajouté
import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final bool isDark;

  const CategoryItem({
    super.key,
    required this.category,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = Color(int.parse(category.color.replaceFirst('#', '0xFF')));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF232b34), const Color(0xFF191f26)]
                        : [const Color(0xFFffffff), const Color(0xFFf0f2f5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3d4752).withOpacity(0.3)
                        : const Color(0xFF000000).withOpacity(0.06),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                ),
                // 2. Utilisation du helper d'icône dynamique
                child: Center(
                  child: _buildIcon(category.icon, iconColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Flexible(
          child: Text(
            category.label,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: Responsive.fontSize(context, 10),
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 3. Helper pour gérer dynamiquement IconData et FaIconData
  Widget _buildIcon(dynamic icon, Color color) {
    if (icon is IconData) {
      return Icon(icon, color: color, size: 22);
    }
    return FaIcon(icon, color: color, size: 22);
  }
}