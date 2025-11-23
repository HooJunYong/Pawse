import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/chat_history_model.dart';

/// Chat session service for managing chat sessions
class ChatSessionService {
  /// Get chat history for a specific user
  /// Returns a list of chat history items with last messages
  static Future<List<ChatHistoryItem>> getChatHistory(String userId) async {
    try {
      final response =
          await ApiService.get('/api/chat/session/user/$userId/history');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatHistoryItem.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // No chat history found
        return [];
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chat history: $e');
    }
  }

  /// Start a new chat session
  static Future<http.Response> startNewSession({
    required String userId,
    required String companionId,
  }) async {
    return await ApiService.post('/api/chat/session/start', {
      'user_id': userId,
      'companion_id': companionId,
    });
  }

  /// End a chat session
  static Future<http.Response> endSession(String sessionId) async {
    return await ApiService.put('/api/chat/session/$sessionId/end', {});
  }

  /// Resume an existing chat session
  static Future<http.Response> resumeSession(String sessionId) async {
    return await ApiService.post('/api/chat/session/$sessionId/resume', {});
  }

  /// Get session details by session ID
  static Future<http.Response> getSessionById(String sessionId) async {
    return await ApiService.get('/api/chat/session/$sessionId');
  }

  /// Get all sessions for a user with pagination
  static Future<http.Response> getUserSessions(
    String userId, {
    int limit = 50,
    int skip = 0,
  }) async {
    return await ApiService.get(
        '/api/chat/session/user/$userId?limit=$limit&skip=$skip');
  }
}
