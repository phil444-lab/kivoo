import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget qui anime l'opacité de son enfant avec un effet de pulsation
class SkeletonPulse extends StatefulWidget {

  const SkeletonPulse({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
}

/// Carte skeleton imitant l'apparence de l'ItemCard en mode liste
class SkeletonItemCard extends StatelessWidget {

  const SkeletonItemCard({
    super.key,
    required this.isDark,
    this.imageHeight = 300,
  });
  final bool isDark;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF2a2f35)
        : const Color(0xFFE0E0E0);

    return SkeletonPulse(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3d4752).withValues(alpha: 0.5)
                : const Color(0xFF000000).withValues(alpha: 0.07),
            width: 1,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: imageHeight,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            // Contenu placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix + Localisation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBlock(baseColor, 80, 16),
                      _buildBlock(baseColor, 100, 12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Titre
                  _buildBlock(baseColor, double.infinity, 14),
                  const SizedBox(height: 6),
                  // Vendeur + Durée
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBlock(baseColor, 90, 12),
                      _buildBlock(baseColor, 60, 12),
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

  Widget _buildBlock(Color color, double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
}

/// Carte skeleton imitant l'apparence de l'ItemCard en mode grille
class SkeletonGridCard extends StatelessWidget {

  const SkeletonGridCard({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF2a2f35)
        : const Color(0xFFE0E0E0);

    return SkeletonPulse(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3d4752).withValues(alpha: 0.5)
                : const Color(0xFF000000).withValues(alpha: 0.07),
            width: 1,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            // Contenu placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix
                  _buildBlock(baseColor, 70, 16),
                  const SizedBox(height: 8),
                  // Localisation
                  _buildBlock(baseColor, double.infinity, 12),
                  const SizedBox(height: 8),
                  // Titre
                  _buildBlock(baseColor, double.infinity, 14),
                  const SizedBox(height: 6),
                  // Vendeur + Durée
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBlock(baseColor, 70, 12),
                      _buildBlock(baseColor, 50, 12),
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

  Widget _buildBlock(Color color, double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
}

/// Bloc skeleton simple pour les sections (feature cards, catégories, etc.)
class SkeletonBlock extends StatelessWidget {

  const SkeletonBlock({
    super.key,
    required this.isDark,
    this.width,
    required this.height,
    this.borderRadius = 16,
  });
  final bool isDark;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? const Color(0xFF2a2f35)
        : const Color(0xFFE0E0E0);

    return SkeletonPulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}