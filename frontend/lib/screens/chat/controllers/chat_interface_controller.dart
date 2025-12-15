import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../models/chat_message_model.dart';
import '../../../models/companion_model.dart';
import '../../../services/chat_session_service.dart';
import '../../../services/api_service.dart';
import '../../../services/tts_service.dart';

class ChatInterfaceController extends ChangeNotifier {
  final String userId;
  final Companion companion;
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _ttsEnabled = false;
  String? _sessionId;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get ttsEnabled => _ttsEnabled;
  String? get sessionId => _sessionId;
  String? get errorMessage => _errorMessage;

  ChatInterfaceController({
    required this.userId,
    required this.companion,
    String? sessionId,
  }) : _sessionId = sessionId;

  /// Initialize the controller - either start new session or resume existing
  Future<void> initialize(String? providedSessionId) async {
    if (providedSessionId != null) {
      await _resumeExistingSession(providedSessionId);
    } else {
      await _startNewSession();
    }
  }

  /// Start a new chat session
  Future<void> _startNewSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ChatSessionService.startNewSession(
        userId: userId,
        companionId: companion.companionId,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'];
        await _loadMessages();
      } else {
        throw Exception('Failed to start session: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Failed to start chat session: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resume an existing chat session
  Future<void> _resumeExistingSession(String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ChatSessionService.resumeSession(sessionId);

      if (response.statusCode == 200) {
        _sessionId = sessionId;
        await _loadMessages();
      } else {
        throw Exception('Failed to resume session: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Failed to resume chat session: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for the current session
  Future<void> _loadMessages() async {
    if (_sessionId == null) return;

    try {
      final response = await ApiService.get('/api/chat/message/$_sessionId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'] ?? [];

        _messages.clear();
        _messages.addAll(
          messagesJson.map((msg) => ChatMessage.fromJson(msg)).toList(),
        );
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a message
  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty || _sessionId == null) return;

    // Add user message immediately
    final userMessage = ChatMessage(
      role: 'user',
      messageText: messageText,
      timestamp: DateTime.now(),
      isLoading: false,
    );
    _messages.add(userMessage);
    notifyListeners();

    // Add loading indicator for AI response
    final loadingMessage = ChatMessage(
      role: 'ai',
      messageText: '...',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    _messages.add(loadingMessage);
    notifyListeners();

    try {
      final response = await ApiService.post('/api/chat/message/send', {
        'session_id': _sessionId,
        'message_text': messageText,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = ChatMessage.fromJson(data['ai_response']);

        // Replace loading message with actual response
        final loadingIndex = _messages.indexWhere((msg) => msg.isLoading);
        if (loadingIndex != -1) {
          _messages[loadingIndex] = aiResponse;
        }
        
        // Play TTS if enabled
        if (_ttsEnabled) {
          TTSService.generateAndPlayAudio(
            text: aiResponse.messageText,
            companionId: companion.companionId,
          );
        }
        
        notifyListeners();
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      // Remove loading indicator on error
      _messages.removeWhere((msg) => msg.isLoading);
      notifyListeners();
      rethrow; // Let UI handle the error display
    }
  }

  /// Toggle TTS
  void toggleTTS() {
    _ttsEnabled = !_ttsEnabled;
    
    if (!_ttsEnabled) {
      TTSService.stopAudio();
    }
    
    notifyListeners();
  }

  /// End the current session
  Future<void> endSession() async {
    if (_sessionId != null) {
      try {
        await ChatSessionService.endSession(_sessionId!);
      } catch (e) {
        debugPrint('Error ending session: $e');
      }
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
