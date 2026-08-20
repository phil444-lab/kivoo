import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../components/fullscreen_image_viewer.dart';
import '../../components/phone_number_dialog.dart';
import '../../services/conversation_service.dart';
import 'seller_profile_screen.dart';
import 'conversation_detail_screen.dart';
import 'share_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark
        ? const Color(0xFF3d4752)
        : const Color(0xFF000000).withValues(alpha: 0.08);
    final item = widget.item;
    final images = item.imageUrls;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Contenu défilable
            CustomScrollView(
              slivers: [
                // AppBar + Image en haut
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  foregroundColor: textColor,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const FaIcon(FontAwesomeIcons.arrowLeft,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    // Partager
                    Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.share,
                            color: Colors.white, size: 20),
                        onPressed: () => _shareItem(),
                      ),
                    ),
                    // Favori
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final isFav = authProvider.isFavorite(item.id);
                        final isAuthenticated = authProvider.isAuthenticated;

                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: FaIcon(
                              isFav
                                  ? FontAwesomeIcons.solidHeart
                                  : FontAwesomeIcons.heart,
                              color: isFav ? Colors.redAccent : Colors.white,
                              size: 20,
                            ),
                            onPressed: () async {
                              if (!isAuthenticated) {
                                // Rediriger vers la connexion si non authentifié
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Connectez-vous pour ajouter aux favoris'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              final wasFavorite = isFav;
                              await authProvider.toggleFavorite(item.id);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      !wasFavorite
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
                          ),
                        );
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildImageCarousel(images),
                  ),
                ),

                // Contenu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Responsive.padding(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Prix + type de prix
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.price,
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: Responsive.fontSize(context, 24),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (item.priceType.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.priceType,
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: Responsive.fontSize(context, 11),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Titre
                        Text(
                          item.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: Responsive.fontSize(context, 18),
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Localisation + temps
                        Row(
                          children: [
                            FaIcon(FontAwesomeIcons.locationDot,
                                size: 13, color: mutedColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                style: TextStyle(
                                    color: mutedColor,
                                    fontSize: Responsive.fontSize(context, 13)),
                              ),
                            ),
                            FaIcon(FontAwesomeIcons.clock,
                                size: 13, color: mutedColor),
                            const SizedBox(width: 4),
                            Text(
                              item.time,
                              style: TextStyle(
                                  color: mutedColor,
                                  fontSize: Responsive.fontSize(context, 13)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Badge vedette si présent
                        if (item.featured) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.crown,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  item.featureTitle.isEmpty
                                      ? 'En vedette'
                                      : item.featureTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Description
                        _SectionCard(
                          isDark: isDark,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          title: 'Description',
                          child: Text(
                            item.description.isEmpty
                                ? 'Aucune description fournie.'
                                : item.description,
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: Responsive.fontSize(context, 13),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Caractéristiques
                        _SectionCard(
                          isDark: isDark,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          title: 'Caractéristiques',
                          child: Column(
                            children: [
                              _buildCharacteristicRow('État', item.condition),
                              if (item.brand.isNotEmpty)
                                _buildCharacteristicRow('Marque', item.brand),
                              if (item.model.isNotEmpty)
                                _buildCharacteristicRow('Modèle', item.model),
                              if (item.year > 0)
                                _buildCharacteristicRow(
                                    'Année', item.year.toString()),
                              if (item.color.isNotEmpty)
                                _buildCharacteristicRow('Couleur', item.color),
                              if (item.categoryName.isNotEmpty)
                                _buildCharacteristicRow(
                                    'Catégorie', item.categoryName),
                              if (item.subcategoryName.isNotEmpty)
                                _buildCharacteristicRow(
                                    'Sous-catégorie', item.subcategoryName),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Vendeur
                        _buildSellerCard(isDark, cardColor, borderColor,
                            textColor, mutedColor),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: isDarkFromContext ? AppTheme.darkSurface : AppTheme.lightSurface,
        child: FaIcon(
          FontAwesomeIcons.image,
          size: 48,
          color: isDarkFromContext
              ? AppTheme.darkTextMuted
              : AppTheme.lightTextMuted,
        ),
      );
    }

    return Stack(
      children: [
        // Image principale - clic pour ouvrir en plein écran
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullscreenImageViewer(
                    images: images,
                    initialIndex: _currentImageIndex,
                  ),
                ),
              );
            },
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) => Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDarkFromContext
                      ? AppTheme.darkSurface
                      : AppTheme.lightSurface,
                  child: FaIcon(
                    FontAwesomeIcons.image,
                    size: 48,
                    color: isDarkFromContext
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Compteur d'images
        if (images.length > 1)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),

        // Indicateurs
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isActive = index == _currentImageIndex;
                return Container(
                  width: isActive ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  bool get isDarkFromContext {
    return Provider.of<ThemeProvider>(context, listen: false).isDark;
  }

  Widget _buildCharacteristicRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Responsive.dimension(context, 110),
            child: Text(
              label,
              style: TextStyle(
                color: isDarkFromContext
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    isDarkFromContext ? AppTheme.darkText : AppTheme.lightText,
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    final item = widget.item;
    final authProvider = context.read<AuthProvider>();
    final isOwnItem = authProvider.user?.id == item.sellerId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendeur',
            style: TextStyle(
              color: textColor,
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Photo du vendeur
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.sellerPhoto.isNotEmpty
                    ? Image.network(
                        item.sellerPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultAvatar(isDark),
                      )
                    : _buildDefaultAvatar(isDark),
              ),
              const SizedBox(width: 12),
              // Nom + vérifié
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.sellerName.isEmpty
                                ? 'Vendeur Kivoo'
                                : item.sellerName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: Responsive.fontSize(context, 14),
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.verified) ...[
                          const SizedBox(width: 4),
                          const FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                        if (item.sellerId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SellerProfileScreen(
                                    sellerId: item.sellerId,
                                    initialName: item.sellerName,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Voir profil',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: Responsive.fontSize(context, 11),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Localisation du vendeur
                    if (item.sellerLocation.isNotEmpty)
                      Text(
                        item.sellerLocation,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: Responsive.fontSize(context, 12),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Note
                    if (item.sellerRating > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.star,
                              size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            item.sellerRating.toStringAsFixed(1),
                            style: TextStyle(
                                color: mutedColor,
                                fontSize: Responsive.fontSize(context, 12)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Boutons (masqués si c'est le vendeur lui-même)
          if (!isOwnItem) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startConversation,
                    icon: const FaIcon(FontAwesomeIcons.comment, size: 14),
                    label: const Text('Contacter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (item.sellerPhone.isNotEmpty) {
                        showPhoneNumberDialog(context,
                            phoneNumber: item.sellerPhone);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Numéro de téléphone non disponible')),
                        );
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.phone, size: 14),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: FaIcon(
        FontAwesomeIcons.user,
        size: 24,
        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
      ),
    );
  }

  Future<void> _shareItem() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour partager cet item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareItemScreen(item: widget.item),
      ),
    );
  }

  Future<void> _startConversation() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour contacter ce vendeur')),
      );
      return;
    }

    final token = authProvider.token;
    if (token == null || widget.item.sellerId.isEmpty) return;

    try {
      final response = await ConversationService().createConversation(
        token: token,
        participantId: widget.item.sellerId,
      );

      if (mounted && response != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(
              conversation: response.conversation,
              otherUserId: widget.item.sellerId,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error creating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de la conversation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
