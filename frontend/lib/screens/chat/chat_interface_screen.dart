import 'package:flutter/material.dart';
import '../../models/companion_model.dart';
import '../../widgets/typing_indicator.dart';
import 'controllers/chat_interface_controller.dart';


class ChatInterfaceScreen extends StatefulWidget {
  final String userId;
  final Companion companion;
  final String? sessionId; // Optional: for resuming existing sessions

  const ChatInterfaceScreen({
    Key? key,
    required this.userId,
    required this.companion,
    this.sessionId, // null = new session, non-null = resume session
  }) : super(key: key);

  @override
  State<ChatInterfaceScreen> createState() => _ChatInterfaceScreenState();
}

class _ChatInterfaceScreenState extends State<ChatInterfaceScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatInterfaceController _controller;

  // Colors from the Figma design
  final Color _bgColor = const Color(0xFFF7F7F7);
  final Color _aiMessageBg = const Color(0xFFF5E6D3);
  final Color _userMessageBg = const Color(0xFFFFB89D);
  final Color _textBlack = const Color(0xFF1A1A1A);
  final Color _btnBrown = const Color(0xFF5D3A1A);

  @override
  void initState() {
    super.initState();
    _controller = ChatInterfaceController(
      userId: widget.userId,
      companion: widget.companion,
      sessionId: widget.sessionId,
    );
    _controller.addListener(_onControllerUpdate);
    _controller.initialize(widget.sessionId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
      // Scroll to bottom after state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  /// Send a message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _controller.sendMessage(messageText);
      _scrollToBottom();
    } catch (e) {
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
    await _controller.endSession();
    
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
        actions: [
          // TTS Toggle Button
          IconButton(
            icon: Icon(
              _controller.ttsEnabled ? Icons.volume_up : Icons.volume_off,
              color: _controller.ttsEnabled ? _btnBrown : Colors.grey,
            ),
            onPressed: () {
              _controller.toggleTTS();
              
              // Show feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _controller.ttsEnabled 
                        ? 'Text-to-speech enabled' 
                        : 'Text-to-speech disabled'
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: _controller.ttsEnabled ? 'Disable TTS' : 'Enable TTS',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _controller.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => _controller.initialize(widget.sessionId),
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
                        itemCount: _controller.messages.length,
                        itemBuilder: (context, index) {
                          final message = _controller.messages[index];
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
                              child: message.isLoading
                                  ? const SizedBox(
                                      width: 40,
                                      height: 24,
                                      child: Center(
                                        child: TypingIndicator(
                                          size: 6.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Text(
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
                        enabled: !_controller.isSending,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send button
                  GestureDetector(
                    onTap: _controller.isSending ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _btnBrown,
                        shape: BoxShape.circle,
                      ),
                      child: _controller.isSending
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
