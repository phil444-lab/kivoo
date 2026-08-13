import 'package:flutter/material.dart';
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
  final ItemModel item;

  const ShareItemScreen({super.key, required this.item});

  @override
  State<ShareItemScreen> createState() => _ShareItemScreenState();
}

class _ShareItemScreenState extends State<ShareItemScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;
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

  String _buildItemShareMessage(ItemModel item) {
    return '📦 ${item.title}\n💰 ${item.price}';
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

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.comment,
              size: 64,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune conversation',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez une conversation pour partager cet item',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 13),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationTile(conversation, isDark);
      },
    );
  }

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
              backgroundColor: AppTheme.primaryBlue,
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