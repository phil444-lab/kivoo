import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../constants.dart';
import '../models/conversation_model.dart';

class ConversationService {
  /// Récupère toutes les conversations de l'utilisateur connecté
  Future<List<Conversation>> getConversations({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] as List<dynamic>;
        return list
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching conversations: $e');
      return [];
    }
  }

  /// Récupère les messages d'une conversation
  Future<Map<String, dynamic>?> getMessages({
    required String token,
    required String conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/conversations/$conversationId/messages').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('⚠️ Error fetching messages: $e');
      return null;
    }
  }

  /// Crée une nouvelle conversation ou retourne l'existante
  Future<CreateConversationResponse?> createConversation({
    required String token,
    required String participantId,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'participantId': participantId,
          if (message != null) 'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return CreateConversationResponse.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('⚠️ Error creating conversation: $e');
      return null;
    }
  }

  /// Envoie un message dans une conversation
  Future<Message?> sendMessage({
    required String token,
    required String conversationId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? attachments,
  }) async {
    try {
      final body = <String, dynamic>{
        'content': content,
        'type': type,
      };
      
      if (attachments != null) {
        body['attachments'] = attachments;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/conversations/$conversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('⚠️ Error sending message: $e');
      return null;
    }
  }

  /// Envoie une image dans une conversation
  Future<Message?> sendImage({
    required String token,
    required String conversationId,
    required File image,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/conversations/$conversationId/images');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data['data'] as Map<String, dynamic>);
      }
      print('⚠️ Error sending image: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('⚠️ Error sending image: $e');
      return null;
    }
  }

  /// Marque les messages d'une conversation comme lus
  Future<bool> markAsRead({
    required String token,
    required String conversationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/conversations/$conversationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Error marking as read: $e');
      return false;
    }
  }
}
