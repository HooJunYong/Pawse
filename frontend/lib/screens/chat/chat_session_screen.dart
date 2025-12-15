import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/companion_service.dart';
import '../../models/companion_model.dart';
import 'change_companion_screen.dart';
import 'chat_interface_screen.dart';
import 'controllers/chat_session_controller.dart';

class ChatSessionScreen extends StatefulWidget {
  final String userId;
  
  const ChatSessionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends State<ChatSessionScreen> {
  int _currentIndex = 1; // Set to 1 to highlight the Chat icon
  late ChatSessionController _controller;

  // Colors extracted from design
  final Color _bgColor = const Color(0xFFF7F4F2);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  final Color _textBlack = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _controller = ChatSessionController(userId: widget.userId);
    _controller.addListener(_onControllerUpdate);
    _controller.loadChatHistoryAndCompanion();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Navigate to change companion screen and handle result
  Future<void> _navigateToChangeCompanion() async {
    if (_controller.currentCompanionId == null) return;
    
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeCompanionScreen(
          userId: widget.userId,
          currentCompanionId: _controller.currentCompanionId!,
        ),
      ),
    );
    
    // If a new companion was selected, update the current companion
    if (result != null && result != _controller.currentCompanionId) {
      try {
        await _controller.updateCompanion(result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update companion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Navigate to new chat interface
  Future<void> _navigateToNewChat() async {
    if (_controller.companionData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a companion first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatInterfaceScreen(
          userId: widget.userId,
          companion: _controller.companionData!,
          sessionId: null, // null = new session
        ),
      ),
    );

    // Reload chat history after returning from chat
    _controller.loadChatHistoryAndCompanion();
  }

  /// Resume existing chat session
  Future<void> _resumeChatSession(String sessionId, String companionId) async {
    try {
      // Load companion data for the session
      final companion = await CompanionService.getCompanionById(companionId);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatInterfaceScreen(
            userId: widget.userId,
            companion: companion,
            sessionId: sessionId, // Resume existing session
          ),
        ),
      );

      // Reload chat history after returning from chat
      _controller.loadChatHistoryAndCompanion();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Main Content Area
          SafeArea(
            bottom: false, // Let content go behind the nav bar
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 120), // Bottom padding for nav bar
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 10, // Ensure minimum height fills screen
                    ),
                    child: Column(
                      children: [
                        
                        // Cat Image - Load from companion data
                        Transform.translate(
                          offset: const Offset(0, -50),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: _controller.companionData?.image != null
                                    ? Image.asset(
                                        'assets/images/${_controller.companionData!.image}',
                                        height: 200,
                                        width: 200,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.asset('assets/images/americonsh1.png'),
                              ),
                              if (_controller.companionData != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _controller.companionData!.companionName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _textBlack,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // 2. Action Buttons (New Chat & Change A Cat)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBrownButton("New Chat", _navigateToNewChat),
                            const SizedBox(width: 16),
                            _buildBrownButton("Change A Cat", _navigateToChangeCompanion),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // 3. History List or Loading/Error/Empty State
                        if (_controller.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_controller.errorMessage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Text(
                                    _controller.errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _controller.loadChatHistoryAndCompanion,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_controller.chatHistory.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'No chat history found, start chatting with your companion by clicking the "New Chat" button!!!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _textBlack,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          // Map the chat history to widgets
                          ..._controller.chatHistory.map((chat) {
                            return _buildHistoryCard(
                              chat.lastMessage,
                              chat.getFormattedDate(),
                              chat.sessionId,
                              chat.companionId,
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              userId: widget.userId,
              selectedIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrownButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _btnBrown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 5,
        shadowColor: _btnBrown.withOpacity(0.4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(String message, String date, String sessionId, String companionId) {
    // Truncate message to first 10 words
    String displayMessage = message.isEmpty ? 'No messages yet' : _controller.truncateMessage(message, 10);
    
    return GestureDetector(
      onTap: () => _resumeChatSession(sessionId, companionId),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date aligns to the right
            Align(
              alignment: Alignment.topRight,
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Message content (truncated)
            Text(
              displayMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textBlack,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8), 
          ],
        ),
      ),
    );
  }
}