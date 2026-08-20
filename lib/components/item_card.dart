import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../providers/auth_provider.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final bool isDark;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final VoidCallback? onFavoriteToggle;
  /// Hauteur du conteneur d'image. Plus petit en mode grille.
  final double imageHeight;
  /// Si true, le contenu remplit toute la hauteur de la carte (mode grille).
  /// Si false, le contenu s'adapte à son contenu (mode liste).
  final bool fillHeight;

  const ItemCard({
    super.key,
    required this.item,
    required this.isDark,
    this.onTap,
    this.showFavoriteButton = true,
    this.onFavoriteToggle,
    this.imageHeight = 300,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final isFav = authProvider.isFavorite(item.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3d4752).withOpacity(0.5)
                : const Color(0xFF000000).withOpacity(0.07),
            width: 1,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Image container
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        item.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightSurface,
                            child: FaIcon(
                              FontAwesomeIcons.image,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.lightTextMuted,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Favorite button (only shown if user is authenticated)
                  if (showFavoriteButton && isAuthenticated)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          final wasFavorite = isFav;
                          if (onFavoriteToggle != null) {
                            onFavoriteToggle!();
                          } else {
                            await authProvider.toggleFavorite(item.id);
                          }
                          
                          // Show snackbar
                          if (context.mounted) {
                            final newState = !wasFavorite;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  newState
                                      ? 'Ajouté aux favoris'
                                      : 'Retiré des favoris',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF12161a).withOpacity(0.8)
                                : const Color(0xFFffffff).withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FaIcon(
                              isFav ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                              color: isFav
                                  ? Colors.red
                                  : (isDark
                                      ? AppTheme.darkTextMuted
                                      : AppTheme.lightTextMuted),
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            if (fillHeight)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prix (en premier)
                      Text(
                        item.price,
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: Responsive.fontSize(context, 16),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Localisation complète (non tronquée)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: FaIcon(
                              FontAwesomeIcons.locationDot,
                              size: 12,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.lightTextMuted,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.location,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.lightTextMuted,
                                fontSize: Responsive.fontSize(context, 12),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 4),
                      // Nom du produit
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          fontSize: Responsive.fontSize(context, 14),
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      const SizedBox(height: 6),
                      // Nom du vendeur (au-dessus) + Durée (en dessous) - alignés à droite
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Nom du vendeur (complet, non tronqué)
                          if (item.sellerName.isNotEmpty) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.user,
                                  size: 10,
                                  color: isDark
                                      ? AppTheme.darkTextMuted
                                      : AppTheme.lightTextMuted,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    item.sellerName,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextMuted
                                          : AppTheme.lightTextMuted,
                                      fontSize: Responsive.fontSize(context, 12),
                                      height: 1.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                          ],
                          // Durée de publication (en dessous)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.clock,
                                size: 10,
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.lightTextMuted,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item.time,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextMuted
                                      : AppTheme.lightTextMuted,
                                  fontSize: Responsive.fontSize(context, 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prix (à gauche) + Localisation (à l'extrémité droite)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            item.price,
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: Responsive.fontSize(context, 16),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Localisation (collée au bord droit)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: FaIcon(
                                FontAwesomeIcons.locationDot,
                                size: 12,
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.lightTextMuted,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                item.location,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextMuted
                                      : AppTheme.lightTextMuted,
                                  fontSize: Responsive.fontSize(context, 12),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Nom du produit
                    Text(
                      item.title,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                        fontSize: Responsive.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Nom du vendeur (à gauche, non tronqué) + Durée (à droite)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom du vendeur (complet, non tronqué)
                        if (item.sellerName.isNotEmpty) ...[
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: FaIcon(
                                    FontAwesomeIcons.user,
                                    size: 10,
                                    color: isDark
                                        ? AppTheme.darkTextMuted
                                        : AppTheme.lightTextMuted,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    item.sellerName,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextMuted
                                          : AppTheme.lightTextMuted,
                                      fontSize: Responsive.fontSize(context, 12),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Durée de publication (à droite)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.clock,
                              size: 10,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.lightTextMuted,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.time,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.lightTextMuted,
                                fontSize: Responsive.fontSize(context, 12),
                              ),
                            ),
                          ],
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