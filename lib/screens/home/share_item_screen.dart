import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/item_model.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../services/conversation_service.dart';
import 'conversation_detail_screen.dart';

class ShareItemScreen extends StatefulWidget {

  const ShareItemScreen({super.key, required this.item});
  final ItemModel item;

  @override
  State<ShareItemScreen> createState() => _ShareItemScreenState();
}

class _ShareItemScreenState extends State<ShareItemScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  /// Vrai pendant la création de la conversation avec le vendeur.
  bool _sharingWithSeller = false;
  final ConversationService _conversationService = ConversationService();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final conversations = await _conversationService.getConversations(token: token);
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _shareItem(Conversation conversation) async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

      try {
        // Créer un message avec la card de l'item
        final messageContent = _buildItemShareMessage(widget.item);
        
        // Envoyer les images (utiliser images ou photo si images est vide)
        // Les images sont stockées comme des chemins relatifs, on les envoie telles quelles
        final imagesList = widget.item.images.isNotEmpty 
            ? widget.item.images 
            : (widget.item.photo.isNotEmpty ? [widget.item.photo] : []);
        
        final message = await _conversationService.sendMessage(
          token: token,
          conversationId: conversation.id,
          content: messageContent,
          type: 'item_share',
          attachments: {
            'item': {
              'id': widget.item.id,
              'title': widget.item.title,
              'price': widget.item.price,
              'priceType': widget.item.priceType,
              'imageUrls': imagesList,
              'photo': widget.item.photo,
              'location': widget.item.location,
              'sellerId': widget.item.sellerId,
              'sellerName': widget.item.sellerName,
              'sellerPhoto': widget.item.sellerPhoto,
            }
          },
        );

      if (mounted && message != null) {
        // Retourner à l'écran de conversation
        Navigator.pop(context);
        
        // Ouvrir la conversation
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConversationDetailScreen(
                conversation: conversation,
                otherUserId: _getOtherUserId(conversation),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error sharing item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du partage de l\'item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildItemShareMessage(ItemModel item) => '📦 ${item.title}\n💰 ${item.price}';

  /// Peut-on proposer le partage avec le vendeur de l'article ?
  ///
  /// Non si l'article n'a pas de vendeur (donnée manquante) ou si l'utilisateur
  /// courant est lui-même le vendeur.
  bool get _canShareWithSeller {
    final sellerId = widget.item.sellerId;
    if (sellerId.isEmpty) return false;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    return currentUserId != sellerId;
  }

  /// Conversation déjà existante avec le vendeur de l'article, si elle existe.
  Conversation? _conversationWithSeller() {
    final sellerId = widget.item.sellerId;
    if (sellerId.isEmpty) return null;

    for (final conversation in _conversations) {
      if (conversation.participants.any((p) => p.userId == sellerId)) {
        return conversation;
      }
    }
    return null;
  }

  /// Partage l'article avec le vendeur : réutilise la conversation existante,
  /// ou la crée à la volée si l'utilisateur ne l'a jamais contacté.
  ///
  /// L'option reste ainsi toujours disponible, même sans conversation
  /// préalable (l'utilisateur peut avoir trouvé l'article depuis l'accueil).
  Future<void> _shareWithSeller() async {
    if (_sharingWithSeller) return;

    final existing = _conversationWithSeller();
    if (existing != null) {
      await _shareItem(existing);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    final sellerId = widget.item.sellerId;
    if (token == null || sellerId.isEmpty) return;

    setState(() => _sharingWithSeller = true);

    try {
      final response = await _conversationService.createConversation(
        token: token,
        participantId: sellerId,
      );

      if (response == null) {
        throw Exception('Conversation non créée');
      }

      if (!mounted) return;
      await _shareItem(response.conversation);
    } catch (e) {
      print('Error sharing with seller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir la conversation avec le vendeur"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sharingWithSeller = false);
      }
    }
  }

  String _getOtherUserId(Conversation conversation) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => conversation.participants.first,
    );
    
    return otherParticipant.userId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Partager l\'item',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 18),
          ),
        ),
        backgroundColor: AppTheme.darkBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: Responsive.iconSize(context, 18),
            color: Colors.white,
          ),
        ),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.lock,
              size: 64,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Connexion requise',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final children = <Widget>[];
    final canShareWithSeller = _canShareWithSeller;

    // Option toujours disponible : partager l'article avec son vendeur,
    // même sans conversation préalable (la conversation est créée au besoin).
    if (canShareWithSeller) {
      children.add(_buildSellerTile(isDark));
      children.add(const SizedBox(height: 20));
    }

    // Conversations existantes, en excluant celle avec le vendeur (déjà
    // proposée juste au-dessus) pour éviter un doublon.
    final sellerId = widget.item.sellerId;
    final conversations = sellerId.isEmpty
        ? _conversations
        : _conversations
            .where((c) => !c.participants.any((p) => p.userId == sellerId))
            .toList();

    // L'état « aucune conversation » n'a de sens que si l'option de partage
    // avec le vendeur n'est pas déjà proposée juste au-dessus.
    if (conversations.isEmpty && !canShareWithSeller) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              FaIcon(
                FontAwesomeIcons.comment,
                size: 64,
                color:
                    isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
              const SizedBox(height: 24),
              Text(
                'Aucune conversation',
                style: TextStyle(
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: Responsive.fontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez une conversation pour partager cet item',
                style: TextStyle(
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: Responsive.fontSize(context, 13),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      children.addAll(
        conversations.map((conversation) =>
            _buildConversationTile(conversation, isDark)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  /// Carte « Partager avec le vendeur » : toujours proposée en haut de l'écran
  /// quand l'article possède un vendeur (et que l'utilisateur n'est pas
  /// lui-même ce vendeur).
  Widget _buildSellerTile(bool isDark) {
    final sellerName = widget.item.sellerName.trim();
    final displayName = sellerName.isNotEmpty ? sellerName : 'le vendeur';

    return Material(
      color: isDark ? AppTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _sharingWithSeller ? null : _shareWithSeller,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF3d4752)
                  : const Color(0xFF000000).withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: _buildSellerAvatar(displayName),
            title: Text(
              sellerName.isNotEmpty ? sellerName : 'Vendeur',
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: Responsive.fontSize(context, 15),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "Partager avec le propriétaire de l'article",
              style: TextStyle(
                color:
                    isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 12),
              ),
            ),
            trailing: _sharingWithSeller
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : FaIcon(
                    FontAwesomeIcons.share,
                    size: Responsive.iconSize(context, 16),
                    color: AppTheme.primaryBlue,
                  ),
          ),
        ),
      ),
    );
  }

  /// Avatar du vendeur : photo de profil si disponible, sinon l'initiale du
  /// nom sur fond bleu (même convention que les autres écrans).
  Widget _buildSellerAvatar(String name) => CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.primaryBlue,
        child: widget.item.sellerPhoto.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.item.sellerPhoto,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildSellerInitial(name),
                  errorWidget: (context, url, error) =>
                      _buildSellerInitial(name),
                ),
              )
            : _buildSellerInitial(name),
      );

  /// Initiale du vendeur (affichée en l'absence de photo de profil).
  Widget _buildSellerInitial(String name) => Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.fontSize(context, 16),
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _buildConversationTile(Conversation conversation, bool isDark) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => conversation.participants.first,
    );

    return Material(
      color: isDark ? AppTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _shareItem(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF3d4752) : const Color(0xFF000000).withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: otherParticipant.user.photoUrl != null
                  ? NetworkImage(otherParticipant.user.photoUrl!)
                  : null,
              backgroundColor: AppTheme.primaryBlue,
              child: otherParticipant.user.photoUrl == null
                  ? Text(
                      otherParticipant.user.name.isNotEmpty
                          ? otherParticipant.user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              otherParticipant.user.name,
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: Responsive.fontSize(context, 15),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Partager avec ${otherParticipant.user.name}',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 12),
              ),
            ),
            trailing: FaIcon(
              FontAwesomeIcons.share,
              size: Responsive.iconSize(context, 16),
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}