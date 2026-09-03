import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../models/item_model.dart';

class SharedItemCard extends StatelessWidget {

  const SharedItemCard({
    super.key,
    required this.item,
    this.onTap,
  });
  final ItemModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF3d4752) : const Color(0xFF000000).withValues(alpha: 0.08);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'item en premier (style Instagram)
            if (item.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  item.imageUrls.first,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 140,
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Container(
                      width: double.infinity,
                      height: 140,
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        size: 32,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    );
                  },
                ),
              )
            else if (item.photo.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  item.photo,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 140,
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading photo: $error');
                    return Container(
                      width: double.infinity,
                      height: 140,
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        size: 32,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    );
                  },
                ),
              ),
            // Contenu en dessous
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    item.title,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontSize: Responsive.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Prix
                  Row(
                    children: [
                      Text(
                        item.price,
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: Responsive.fontSize(context, 17),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Localisation
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.locationDot,
                        size: 11,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                            fontSize: Responsive.fontSize(context, 12),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
