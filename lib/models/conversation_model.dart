import '../../constants.dart';

class Conversation {
  final String id;
  final String? itemId;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final DateTime? lastMessageSentAt;
  final Map<String, dynamic>? unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationParticipant> participants;
  final ConversationItem? item;

  Conversation({
    required this.id,
    this.itemId,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageSentAt,
    this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.item,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participantsList = (json['participants'] as List?)
            ?.map((e) => ConversationParticipant.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    
    final itemData = json['item'];
    final item = itemData != null ? ConversationItem.fromJson(itemData as Map<String, dynamic>) : null;

    return Conversation(
      id: json['id'] as String,
      itemId: json['itemId'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageSentAt: json['lastMessageSentAt'] != null 
          ? DateTime.parse((json['lastMessageSentAt'] as String).replaceFirst(' ', 'T'))
          : null,
      unreadCount: json['unreadCount'] as Map<String, dynamic>?,
      createdAt: DateTime.parse((json['createdAt'] as String).replaceFirst(' ', 'T')),
      updatedAt: DateTime.parse((json['updatedAt'] as String).replaceFirst(' ', 'T')),
      participants: participantsList,
      item: item,
    );
  }

  int getUnreadCount(String userId) {
    if (unreadCount == null) return 0;
    return (unreadCount![userId] as int?) ?? 0;
  }
}

class ConversationParticipant {
  final String userId;
  final ConversationUser user;

  ConversationParticipant({
    required this.userId,
    required this.user,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      userId: json['userId'] as String,
      user: ConversationUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class ConversationUser {
  final String id;
  final String name;
  final String? photo;

  ConversationUser({
    required this.id,
    required this.name,
    this.photo,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['id'] as String,
      name: json['name'] as String,
      photo: json['photo'] as String?,
    );
  }

  /// Retourne l'URL complète de la photo de profil
  String? get photoUrl {
    if (photo == null || photo!.isEmpty) return null;
    // Si c'est déjà une URL complète (http/https), la retourner telle quelle
    if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
      return photo;
    }
    // Sinon, c'est un nom de fichier, construire l'URL
    return '${AppConstants.uploadsBaseUrl}/$photo';
  }
}

class ConversationItem {
  final String id;
  final String title;
  final double price;
  final List<String>? images;

  ConversationItem({
    required this.id,
    required this.title,
    required this.price,
    this.images,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List?;
    return ConversationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      images: imagesList?.map((e) => e as String).toList(),
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type;
  final Map<String, dynamic>? attachments;
  final bool read;
  final DateTime? readAt;
  final DateTime createdAt;
  final MessageSender sender;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.attachments,
    this.read = false,
    this.readAt,
    required this.createdAt,
    required this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      attachments: json['attachments'] as Map<String, dynamic>?,
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] != null 
          ? DateTime.parse((json['readAt'] as String).replaceFirst(' ', 'T'))
          : null,
      createdAt: DateTime.parse((json['createdAt'] as String).replaceFirst(' ', 'T')),
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
    );
  }
}

class MessageSender {
  final String id;
  final String name;
  final String? photo;

  MessageSender({
    required this.id,
    required this.name,
    this.photo,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as String,
      name: json['name'] as String,
      photo: json['photo'] as String?,
    );
  }

  /// Retourne l'URL complète de la photo de profil
  String? get photoUrl {
    if (photo == null || photo!.isEmpty) return null;
    // Si c'est déjà une URL complète (http/https), la retourner telle quelle
    if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
      return photo;
    }
    // Sinon, c'est un nom de fichier, construire l'URL
    return '${AppConstants.uploadsBaseUrl}/$photo';
  }
}

class CreateConversationResponse {
  final Conversation conversation;
  final Message? message;

  CreateConversationResponse({
    required this.conversation,
    this.message,
  });

  factory CreateConversationResponse.fromJson(Map<String, dynamic> json) {
    final messageData = json['message'];
    return CreateConversationResponse(
      conversation: Conversation.fromJson(json['conversation'] as Map<String, dynamic>),
      message: messageData != null ? Message.fromJson(messageData as Map<String, dynamic>) : null,
    );
  }
}
