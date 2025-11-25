import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/chat_session_service.dart';
import '../../services/api_service.dart';
import '../../models/companion_model.dart';

class ChatInterfaceScreen extends StatefulWidget {
  final String userId;
  final Companion companion;

  const ChatInterfaceScreen({
    Key? key,
    required this.userId,
    required this.companion,
  }) : super(key: key);

  @override
  State<ChatInterfaceScreen> createState() => _ChatInterfaceScreenState();
}

class _ChatInterfaceScreenState extends State<ChatInterfaceScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isLoading = true;
  bool _isSending = false;
  String? _sessionId;
  String? _errorMessage;

  // Colors from the Figma design
  final Color _bgColor = const Color(0xFFF7F7F7);
  final Color _aiMessageBg = const Color(0xFFF5E6D3);
  final Color _userMessageBg = const Color(0xFFFFB89D);
  final Color _textBlack = const Color(0xFF1A1A1A);
  final Color _btnBrown = const Color(0xFF5D3A1A);

  @override
  void initState() {
    super.initState();
    _startNewSession();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Start a new chat session
  Future<void> _startNewSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Start new session
      final response = await ChatSessionService.startNewSession(
        userId: widget.userId,
        companionId: widget.companion.companionId,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'];

        // Load initial messages (greeting)
        await _loadMessages();
      } else {
        throw Exception('Failed to start session: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start chat session: $e';
        _isLoading = false;
      });
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

        setState(() {
          _messages.clear();
          _messages.addAll(
            messagesJson.map((msg) => ChatMessage.fromJson(msg)).toList(),
          );
          _isLoading = false;
        });

        // Scroll to bottom after loading messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  /// Send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _sessionId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final response = await ApiService.post('/api/chat/message/send', {
        'session_id': _sessionId,
        'message_text': messageText,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Add user message and AI response
        setState(() {
          _messages.add(ChatMessage.fromJson(data['user_message']));
          _messages.add(ChatMessage.fromJson(data['ai_response']));
          _isSending = false;
        });

        // Scroll to bottom
        _scrollToBottom();
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// End session and navigate back
  Future<void> _endSessionAndGoBack() async {
    if (_sessionId != null) {
      try {
        await ChatSessionService.endSession(_sessionId!);
      } catch (e) {
        // Log error but still navigate back
        debugPrint('Error ending session: $e');
      }
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// Scroll to bottom of chat
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textBlack),
          onPressed: _endSessionAndGoBack,
        ),
        title: Row(
          children: [
            // Companion image in circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _btnBrown, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/${widget.companion.image}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.pets, size: 20),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Companion name
            Text(
              widget.companion.companionName,
              style: TextStyle(
                color: _textBlack,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _startNewSession,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isAI = message.role.toLowerCase() == 'ai';

                          return Align(
                            alignment: isAI
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isAI ? _aiMessageBg : _userMessageBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                message.messageText,
                                style: TextStyle(
                                  color: _textBlack,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isSending,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send button
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _btnBrown,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model for chat messages
class ChatMessage {
  final String role;
  final String messageText;
  final DateTime timestamp;
  final String? emotion;

  ChatMessage({
    required this.role,
    required this.messageText,
    required this.timestamp,
    this.emotion,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? '',
      messageText: json['message_text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      emotion: json['emotion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'message_text': messageText,
      'timestamp': timestamp.toIso8601String(),
      'emotion': emotion,
    };
  }
}
