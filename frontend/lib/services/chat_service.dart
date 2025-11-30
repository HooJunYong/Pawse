import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

class ChatService {
  ChatService();

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  Future<ChatConversation> createConversation({
    required String clientUserId,
    required String therapistUserId,
    required bool isTherapistRequester,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_user_id': clientUserId,
        'therapist_user_id': therapistUserId,
        'requester_role': isTherapistRequester ? 'therapist' : 'client',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to create conversation: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatConversation.fromJson(data);
  }

  Future<List<ChatConversation>> getConversations({
    required String userId,
    required bool isTherapist,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/conversations?user_id=$userId&role=${isTherapist ? 'therapist' : 'client'}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to load conversations');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final conversations = decoded['conversations'] as List? ?? [];
      return conversations
          .whereType<Map<String, dynamic>>()
          .map(ChatConversation.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async {
    final buffer = StringBuffer('$_baseUrl/chat/conversations/$conversationId/messages?limit=$limit');
    if (before != null) {
      buffer.write('&before=${before.toIso8601String()}');
    }

    final response = await http.get(Uri.parse(buffer.toString()));
    if (response.statusCode != 200) {
      throw Exception('Unable to load messages');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    }
    return [];
  }

  Future<ChatMessage> sendMessage({
    required String senderId,
    required bool isTherapist,
    required String content,
    String? conversationId,
    String? clientUserId,
    String? therapistUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': senderId,
        'sender_role': isTherapist ? 'therapist' : 'client',
        'content': content,
        if (conversationId != null) 'conversation_id': conversationId,
        if (clientUserId != null) 'client_user_id': clientUserId,
        if (therapistUserId != null) 'therapist_user_id': therapistUserId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to send message: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessage.fromJson(decoded);
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
    required bool isTherapist,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/read'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'user_role': isTherapist ? 'therapist' : 'client',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to mark conversation as read');
    }
  }
}
