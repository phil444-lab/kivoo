import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/item_model.dart';
import '../../services/public_profile_service.dart';
import '../../services/conversation_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../components/item_card.dart';
import '../../components/phone_number_dialog.dart';
import '../../components/skeleton_card.dart';
import '../../providers/auth_provider.dart';
import 'item_detail_screen.dart';
import 'conversation_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String? initialName;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    this.initialName,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final PublicProfileService _service = PublicProfileService();
  final ConversationService _conversationService = ConversationService();
  PublicSellerProfile? _profile;
  List<ItemModel> _items = [];
  bool _loading = true;
  bool _loadingItems = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadingItems = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _service.getSellerProfile(widget.sellerId),
        _service.getSellerItems(widget.sellerId),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = results[0] as PublicSellerProfile?;
        _items = results[1] as List<ItemModel>;
        _loading = false;
        _loadingItems = false;
        _hasError = _profile == null;
      });
    } catch (e) {
      print('Error loading seller profile: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingItems = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _startConversation() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour contacter ce vendeur')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce vendeur n\'a aucune annonce active')),
      );
      return;
    }

    final token = authProvider.token;
    if (token == null) return;

    try {
      final response = await _conversationService.createConversation(
        token: token,
        participantId: widget.sellerId,
      );

      if (mounted && response != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(
              conversation: response.conversation,
              otherUserId: widget.sellerId,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark
        ? const Color(0xFF3d4752)
        : const Color(0xFF000000).withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Profil du vendeur',
          style: TextStyle(
            color: textColor,
            fontSize: Responsive.fontSize(context, 18),
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: textColor, size: Responsive.iconSize(context, 18)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? _buildSkeleton(isDark, cardColor, borderColor)
          : _hasError
              ? _buildErrorState(isDark, textColor)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildProfileHeader(context, isDark, textColor, mutedColor, cardColor, borderColor),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverToBoxAdapter(
                          child: _buildSectionTitle(context, isDark, textColor),
                        ),
                      ),
                      if (_loadingItems)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Responsive.isTablet(context) ? 3 : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: Responsive.isTablet(context) ? 260 : 290,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => SkeletonGridCard(isDark: isDark),
                              childCount: 4,
                            ),
                          ),
                        )
                      else if (_items.isEmpty)
                        SliverToBoxAdapter(
                          child: _buildEmptyItems(isDark, mutedColor),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Responsive.isTablet(context) ? 3 : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: Responsive.isTablet(context) ? 260 : 290,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _items[index];
                                return ItemCard(
                                  item: item,
                                  isDark: isDark,
                                  imageHeight: 110,
                                  fillHeight: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ItemDetailScreen(item: item),
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount: _items.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
    );
  }

  /// Skeleton affiché pendant le chargement du profil
  Widget _buildSkeleton(bool isDark, Color cardColor, Color borderColor) {
    final baseColor = isDark
        ? const Color(0xFF2a2f35)
        : const Color(0xFFE0E0E0);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte profil skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                // Avatar circulaire
                SkeletonPulse(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Nom
                SkeletonPulse(
                  child: Container(
                    width: 160,
                    height: 22,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Localisation
                SkeletonPulse(
                  child: Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: SkeletonPulse(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SkeletonPulse(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: SkeletonPulse(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SkeletonPulse(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Titre section
          SkeletonPulse(
            child: Container(
              width: 200,
              height: 20,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Grille d'items skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.isTablet(context) ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: Responsive.isTablet(context) ? 260 : 290,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => SkeletonGridCard(isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
  ) {
    final profile = _profile!;
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                border: Border.all(color: cardColor, width: 3),
              ),
              child: profile.photo.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profile.photo,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildFallbackAvatar(profile.name),
                        errorWidget: (context, url, error) => _buildFallbackAvatar(profile.name),
                      ),
                    )
                  : _buildFallbackAvatar(profile.name),
            ),
            const SizedBox(height: 12),

            // Nom + badge vérifié
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: Responsive.fontSize(context, 22),
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (profile.verified) ...[
                  const SizedBox(width: 6),
                  const FaIcon(
                    FontAwesomeIcons.circleCheck,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ],
            ),

            // Localisation
            if (profile.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.locationDot, size: 13, color: mutedColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      profile.location,
                      style: TextStyle(color: mutedColor, fontSize: Responsive.fontSize(context, 13)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Stats : Annonces + Note
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      context,
                      profile.itemsListed.toString(),
                      'Annonces',
                      FontAwesomeIcons.store,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatColumn(
                      context,
                      profile.rating > 0 ? profile.rating.toStringAsFixed(1) : '—',
                      'Note',
                      FontAwesomeIcons.star,
                      isDark,
                    ),
                  ),
                ],
              ),
            ),

            // Boutons d'action (masqués si l'utilisateur n'est pas connecté)
            if (isAuthenticated) ...[
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
                        if (profile.phone.isNotEmpty) {
                          showPhoneNumberDialog(context, phoneNumber: profile.phone);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Numéro de téléphone non disponible')),
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
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String value,
    String label,
    FaIconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FaIcon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              fontSize: Responsive.fontSize(context, 11),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, bool isDark, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Annonces de ${_profile?.name ?? 'ce vendeur'}',
        style: TextStyle(
          color: textColor,
          fontSize: Responsive.fontSize(context, 18),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyItems(bool isDark, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.boxOpen,
            size: 48,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune annonce en cours',
            style: TextStyle(
              color: mutedColor,
              fontSize: Responsive.fontSize(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.userSlash, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          Text(
            'Profil introuvable',
            style: TextStyle(
              color: textColor,
              fontSize: Responsive.fontSize(context, 16),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
