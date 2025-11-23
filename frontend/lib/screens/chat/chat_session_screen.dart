import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/chat_session_service.dart';
import '../../models/chat_history_model.dart';

class ChatSessionScreen extends StatefulWidget {
  final String userId;
  
  const ChatSessionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends State<ChatSessionScreen> {
  int _currentIndex = 1; // Set to 1 to highlight the Chat icon
  List<ChatHistoryItem> _chatHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Colors extracted from design
  final Color _bgWhite = const Color(0xFFF7F7F7);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  final Color _textBlack = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  /// Load chat history from the backend
  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chatHistory = await ChatSessionService.getChatHistory(widget.userId);
      setState(() {
        _chatHistory = chatHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load chat history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      body: Stack(
        children: [
          // Main Content Area
          SafeArea(
            bottom: false, // Let content go behind the nav bar
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 120), // Bottom padding for nav bar
              child: Column(
                children: [
                  
                  // 1. Cat Image
                  Transform.translate(
                    offset: const Offset(0, -50), // Move up by 20 pixels
                    child: Center(
                      child: Image.asset(
                        'assets/images/tile000.png', 
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 2),

                  // 2. Action Buttons (New Chat & Change A Cat)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrownButton("New Chat", () {}),
                      const SizedBox(width: 16),
                      _buildBrownButton("Change A Cat", () {}),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 3. History List or Loading/Error/Empty State
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadChatHistory,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_chatHistory.isEmpty)
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
                    ..._chatHistory.map((chat) {
                      return _buildHistoryCard(
                        chat.lastMessage,
                        chat.getFormattedDate(),
                        chat.sessionId,
                      );
                    }).toList(),
                ],
              ),
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
                  // Add navigation logic here (e.g., Navigator.push...)
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

  Widget _buildHistoryCard(String message, String date, String sessionId) {
    return Container(
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
          // Message content
          Text(
            message.isEmpty ? 'No messages yet' : message,
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
    );
  }
}