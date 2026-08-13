import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/conversation_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_provider.dart';
import '../../utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../services/conversation_service.dart';
import '../../services/user_search_service.dart';
import 'conversation_detail_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ConversationsScreen({super.key, this.onBack});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;
  final ConversationService _conversationService = ConversationService();
  final UserSearchService _userSearchService = UserSearchService();
  String _searchQuery = '';
  bool _isSearchingUsers = false;
  List<User> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

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

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearchingUsers = false;
        _searchResults = [];
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isSearchingUsers = true);

    try {
      final result = await _userSearchService.searchSellers(
        token: token,
        search: query,
      );

      if (mounted && result != null) {
        final usersList = (result['users'] as List)
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _searchResults = usersList;
          _isSearchingUsers = false;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
      if (mounted) {
        setState(() => _isSearchingUsers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Discussions',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.fontSize(context, 18),
          ),
        ),
        backgroundColor: AppTheme.darkBlue,
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.pop(context),
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: Responsive.iconSize(context, 18),
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          Expanded(
            child: _buildBody(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db),
          ),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          if (value.isNotEmpty) {
            _searchUsers(value);
          } else {
            setState(() {
              _isSearchingUsers = false;
              _searchResults = [];
            });
          }
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un vendeur...',
          hintStyle: TextStyle(
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            fontSize: Responsive.fontSize(context, 14),
          ),
          prefixIcon: SizedBox(
            width: 48,
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                size: Responsive.iconSize(context, 16),
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF232b34) : const Color(0xFFf0f2f5),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
          fontSize: Responsive.fontSize(context, 14),
        ),
      ),
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
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour accéder à vos discussions',
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

    if (_isSearchingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) {
      return _buildUserSearchResults(isDark);
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
              'Aucune discussion',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recherchez un vendeur pour commencer une conversation',
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
      onRefresh: _loadConversations,
      color: AppTheme.primaryBlue,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation, isDark);
        },
      ),
    );
  }

  Widget _buildUserSearchResults(bool isDark) {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user, isDark);
      },
    );
  }

  Widget _buildUserTile(User user, bool isDark) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
        user.name,
        style: TextStyle(
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
          fontSize: Responsive.fontSize(context, 15),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.rating > 0)
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.star,
                  size: 12,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  user.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: Responsive.fontSize(context, 12),
                  ),
                ),
                if (user.ratingCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${user.ratingCount})',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      fontSize: Responsive.fontSize(context, 12),
                    ),
                  ),
                ],
              ],
            ),
          if (user.verified)
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.checkCircle,
                  size: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Vendeur vérifié',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: Responsive.fontSize(context, 12),
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        size: Responsive.iconSize(context, 16),
        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
      ),
      onTap: () async {
        final authProvider = context.read<AuthProvider>();
        final token = authProvider.token;
        if (token == null) return;

        try {
          final response = await _conversationService.createConversation(
            token: token,
            participantId: user.id,
          );

          if (mounted && response != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationDetailScreen(
                  conversation: response.conversation,
                  otherUserId: user.id,
                ),
              ),
            );
            // Refresh conversations after returning
            _loadConversations();
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
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation, bool isDark) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    
    // Get the other participant
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse: () => conversation.participants.first,
    );

    final unreadCount = conversation.getUnreadCount(currentUserId ?? '');

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF3d4752) : const Color(0xFFd1d5db),
          ),
        ),
      ),
      child: Material(
        color: isDark ? AppTheme.darkCard : Colors.white,
        child: ListTile(
          leading: CircleAvatar(
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
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conversation.lastMessageContent != null)
                Text(
                  conversation.lastMessageContent!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: Responsive.fontSize(context, 13),
                  ),
                ),
              if (conversation.item != null)
                Text(
                  conversation.item!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: Responsive.fontSize(context, 12),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (conversation.lastMessageSentAt != null)
                Text(
                  _formatDate(conversation.lastMessageSentAt!),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    fontSize: Responsive.fontSize(context, 11),
                  ),
                ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, 11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationDetailScreen(
                  conversation: conversation,
                  otherUserId: otherParticipant.userId,
                ),
              ),
            );
            // Rafraîchir la liste après le retour de l'écran de détail
            if (mounted) {
              _loadConversations();
            }
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
