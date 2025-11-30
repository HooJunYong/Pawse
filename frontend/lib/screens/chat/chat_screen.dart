import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String clientUserId;
  final String therapistUserId;
  final String currentUserId;
  final bool isTherapist;
  final String counterpartName;
  final String? counterpartAvatarUrl;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.clientUserId,
    required this.therapistUserId,
    required this.currentUserId,
    required this.isTherapist,
    required this.counterpartName,
    this.counterpartAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _initializeConversation();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    setState(() => _isLoading = true);
    try {
      if (_conversationId == null) {
        final conversation = await _chatService.createConversation(
          clientUserId: widget.clientUserId,
          therapistUserId: widget.therapistUserId,
          isTherapistRequester: widget.isTherapist,
        );
        _conversationId = conversation.conversationId;
      }
      await _loadMessages();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open chat: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshMessages();
    });
  }

  Future<void> _markConversationAsRead() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      await _chatService.markConversationRead(
        conversationId: conversationId,
        userId: widget.currentUserId,
        isTherapist: widget.isTherapist,
      );
    } catch (_) {
      // Ignore read failures silently
    }
  }

  Future<void> _loadMessages() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      final messages = await _chatService.getMessages(
        conversationId: conversationId,
        limit: 100,
      );
      if (!mounted) return;
      setState(() => _messages = messages);
      await _markConversationAsRead();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load messages: $e')),
      );
    }
  }

  Future<void> _refreshMessages() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      final messages = await _chatService.getMessages(
        conversationId: conversationId,
        limit: 100,
      );
      if (!mounted) return;
      if (messages.length != _messages.length ||
          (messages.isNotEmpty && _messages.isNotEmpty &&
              messages.last.messageId != _messages.last.messageId)) {
        setState(() => _messages = messages);
        await _markConversationAsRead();
        _scrollToBottom();
      }
    } catch (_) {
      // Ignore polling failures
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final message = await _chatService.sendMessage(
        senderId: widget.currentUserId,
        isTherapist: widget.isTherapist,
        content: text,
        conversationId: _conversationId,
        clientUserId: widget.clientUserId,
        therapistUserId: widget.therapistUserId,
      );
      _conversationId = message.conversationId;
      _messageController.clear();
      setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF7F4F2);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3E2723)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: widget.counterpartAvatarUrl != null &&
                      widget.counterpartAvatarUrl!.isNotEmpty
                  ? NetworkImage(widget.counterpartAvatarUrl!)
                  : null,
              child: (widget.counterpartAvatarUrl == null ||
                      widget.counterpartAvatarUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Color(0xFF5D4037))
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.counterpartName,
                  style: const TextStyle(
                    color: Color(0xFF3E2723),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFDF7F2),
                      Color(0xFFF8ECE4),
                    ],
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF5D4037)),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Say hello to start the conversation.',
                              style: TextStyle(
                                color: Color(0xFF8D6E63),
                                fontSize: 15,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMine = message.isFromCurrentUser(widget.currentUserId);
                              return ChatBubble(
                                message: message.content,
                                isMine: isMine,
                                timestamp: message.createdAt.toLocal(),
                              );
                            },
                          ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4F2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFDFCBC2)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type your message...'
                          ),
                          onSubmitted: (_) {
                            _handleSend();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isSending ? null : _handleSend,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5D4037),
                          shape: BoxShape.circle,
                        ),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
