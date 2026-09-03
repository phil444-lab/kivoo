import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../models/item_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/picked_image.dart';
import '../../utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../services/conversation_service.dart';
import '../../components/shared_item_card.dart';
import '../../components/fullscreen_image_viewer.dart';
import '../../constants.dart';
import 'home_screen.dart';
import 'item_detail_screen.dart';

class ConversationDetailScreen extends StatefulWidget {

  const ConversationDetailScreen({
    super.key,
    required this.conversation,
    required this.otherUserId,
  });
  final Conversation conversation;
  final String otherUserId;

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  List<Message> _messages = [];
  bool _loading = true;
  final ConversationService _conversationService = ConversationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      _markAsRead();
    });
  }

  Future<void> _loadMessages() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    try {
      final result = await _conversationService.getMessages(
        token: token,
        conversationId: widget.conversation.id,
      );

      if (mounted && result != null) {
        final messagesList = (result['messages'] as List)
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _messages = messagesList;
          _loading = false;
        });
        
        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAsRead() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    try {
      await _conversationService.markAsRead(
        token: token,
        conversationId: widget.conversation.id,
      );
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _sending) return;

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final message = await _conversationService.sendMessage(
        token: token,
        conversationId: widget.conversation.id,
        content: content,
      );

      if (mounted && message != null) {
        setState(() {
          _messages.add(message);
          _sending = false;
        });
        _scrollToBottom();
        
        // Rafraîchir le compteur de messages non lus dans le HomeScreen
        homeScreenKey.currentState?.refreshUnreadCount();
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi du message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id;

    // Get the other participant
    final otherParticipant = widget.conversation.participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => widget.conversation.participants.first,
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherParticipant.user.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(isDark, currentUserId),
          ),
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark, String? currentUserId) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (_messages.isEmpty) {
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
              'Aucun message',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Envoyez votre premier message pour commencer la conversation',
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

    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: AppTheme.primaryBlue,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + _countDateSeparators(),
        itemBuilder: (context, index) => _buildMessageOrDateSeparator(index, isDark, currentUserId),
      ),
    );
  }

  int _countDateSeparators() {
    if (_messages.isEmpty) return 0;
    var count = 0;
    for (var i = 0; i < _messages.length; i++) {
      if (i == 0 || !_isSameDay(_messages[i].createdAt, _messages[i - 1].createdAt)) {
        count++;
      }
    }
    return count;
  }

  Widget _buildMessageOrDateSeparator(int index, bool isDark, String? currentUserId) {
    var messageIndex = 0;
    var separatorCount = 0;
    
    for (var i = 0; i < _messages.length; i++) {
      final showSeparator = i == 0 || !_isSameDay(_messages[i].createdAt, _messages[i - 1].createdAt);
      if (showSeparator) {
        if (index == messageIndex + separatorCount) {
          return _buildDateSeparator(_messages[i].createdAt, isDark);
        }
        separatorCount++;
      }
      
      if (index == messageIndex + separatorCount) {
        final message = _messages[i];
        final isMe = message.senderId == currentUserId;
        return _buildMessageBubble(message, isMe, isDark);
      }
      messageIndex++;
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildDateSeparator(DateTime date, bool isDark) => Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3d4752) : const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDateSeparator(date),
          style: TextStyle(
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            fontSize: Responsive.fontSize(context, 12),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );

  bool _isSameDay(DateTime date1, DateTime date2) => date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return "Aujourd'hui";
    } else if (messageDay == yesterday) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool isDark) {
    // Si c'est un partage d'item, afficher la card d'item
    if (message.type == 'item_share' && message.attachments != null) {
      return _buildSharedItemCard(message, isMe, isDark);
    }

    // Si c'est une image, afficher l'image
    if (message.type == 'image' && message.attachments != null) {
      return _buildImageMessage(message, isMe, isDark);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe 
              ? AppTheme.primaryBlue 
              : (isDark ? AppTheme.darkCard : const Color(0xFFE8E8E8)),
          borderRadius: BorderRadius.circular(16),
          border: isMe 
              ? null 
              : Border.all(
                  color: isDark ? AppTheme.darkTextMuted.withValues(alpha: 0.2) : Colors.grey.shade400,
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : (isDark ? AppTheme.darkText : AppTheme.lightText),
                fontSize: Responsive.fontSize(context, 14),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                    fontSize: Responsive.fontSize(context, 11),
                  ),
                ),
                if (isMe && message.read) ...[
                  const SizedBox(width: 4),
                  FaIcon(
                    FontAwesomeIcons.checkDouble,
                    size: 10,
                    color: Colors.blue[200],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedItemCard(Message message, bool isMe, bool isDark) {
    final itemData = message.attachments!['item'] as Map<String, dynamic>;
    final imagesList = (itemData['imageUrls'] as List?)?.map((e) => e as String).toList() ?? [];
    
    // Les images sont déjà des URLs complètes ou des chemins relatifs
    // S'assurer que les URLs d'images sont complètes
    final completeImageUrls = imagesList.map((img) {
      if (img.isEmpty) return '';
      if (img.startsWith('http://') || img.startsWith('https://')) {
        return img;
      }
      return '${AppConstants.uploadsBaseUrl}/$img';
    }).where((url) => url.isNotEmpty).toList();
    
    final photo = itemData['photo'] as String? ?? '';
    final finalPhoto = photo.isNotEmpty 
        ? (photo.startsWith('http://') || photo.startsWith('https://') 
            ? photo 
            : '${AppConstants.uploadsBaseUrl}/$photo')
        : (completeImageUrls.isNotEmpty ? completeImageUrls.first : '');
    
    final item = ItemModel(
      id: itemData['id'] as String,
      title: itemData['title'] as String,
      description: '',
      price: itemData['price'] as String,
      priceType: itemData['priceType'] as String? ?? 'Prix fixe',
      priceTypeValue: 'fixed',
      location: itemData['location'] as String,
      condition: 'Bon état',
      time: '',
      photo: finalPhoto,
      images: completeImageUrls,
      verified: false,
      sellerId: itemData['sellerId'] as String,
      sellerName: itemData['sellerName'] as String,
      sellerPhone: '',
      sellerPhoto: itemData['sellerPhoto'] as String? ?? '',
      sellerRating: 0,
      sellerLocation: '',
      categoryName: '',
      subcategoryName: '',
      brand: '',
      model: '',
      color: '',
      year: 0,
      views: 0,
      likes: 0,
      featureTitle: '',
      featureIcon: '',
      featured: false,
      categoryId: '',
      subcategoryId: '',
      departmentId: '',
      cityId: '',
      districtId: '',
      featureId: '',
      status: 'active',
      createdAt: DateTime.now(),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Indicateur d'expéditeur (avatar + nom)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: message.sender.photoUrl != null
                        ? NetworkImage(message.sender.photoUrl!)
                        : null,
                    backgroundColor: AppTheme.primaryBlue,
                    child: message.sender.photoUrl == null
                        ? Text(
                            message.sender.name.isNotEmpty
                                ? message.sender.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.sender.name,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      fontSize: Responsive.fontSize(context, 11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SharedItemCard(
              item: item,
              onTap: () => _openItemDetail(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(Message message, bool isMe, bool isDark) {
    final imageName = message.attachments!['image'] as String? ?? '';
    final imageUrl = imageName.startsWith('http://') || imageName.startsWith('https://')
        ? imageName
        : '${AppConstants.uploadsBaseUrl}/$imageName';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isMe 
              ? AppTheme.primaryBlue 
              : (isDark ? AppTheme.darkCard : const Color(0xFFE8E8E8)),
          borderRadius: BorderRadius.circular(16),
          border: isMe 
              ? null 
              : Border.all(
                  color: isDark ? AppTheme.darkTextMuted.withValues(alpha: 0.2) : Colors.grey.shade400,
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullscreenImageViewer(images: [imageUrl]),
                    ),
                  );
                },
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        size: 40,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                      fontSize: Responsive.fontSize(context, 11),
                    ),
                  ),
                  if (isMe && message.read) ...[
                    const SizedBox(width: 4),
                    FaIcon(
                      FontAwesomeIcons.checkDouble,
                      size: 10,
                      color: Colors.blue[200],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
    if (picked == null) return;

    final image = await PickedImage.fromXFile(picked);
    setState(() => _sending = true);

    try {
      final message = await _conversationService.sendImage(
        token: token,
        conversationId: widget.conversation.id,
        image: image,
      );

      if (mounted && message != null) {
        setState(() {
          _messages.add(message);
          _sending = false;
        });
        _scrollToBottom();
        homeScreenKey.currentState?.refreshUnreadCount();
      } else if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sending image: $e');
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openItemDetail(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(item: item),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Écrivez votre message...',
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: Responsive.fontSize(context, 14),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF232b34) : const Color(0xFFf0f2f5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                fontSize: Responsive.fontSize(context, 14),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton envoi d'image
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232b34) : const Color(0xFFf0f2f5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sending ? null : _pickAndSendImage,
              icon: FaIcon(
                FontAwesomeIcons.image,
                size: Responsive.iconSize(context, 18),
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _sending ? Colors.grey : AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : FaIcon(
                      FontAwesomeIcons.paperPlane,
                      size: Responsive.iconSize(context, 18),
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} j';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
