import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart'; // Make sure this file exists in your project

class ChatSessionScreen extends StatefulWidget {
  const ChatSessionScreen({Key? key}) : super(key: key);

  @override
  State<ChatSessionScreen> createState() => _ChatSessionScreenState();
}

class _ChatSessionScreenState extends State<ChatSessionScreen> {
  int _currentIndex = 1; // Set to 1 to highlight the Chat icon

  // Sample data mimicking the design
  final List<Map<String, String>> _chatHistory = [
    {
      "date": "13/08/2025",
      "message": "my mom scold me today",
    },
    {
      "date": "12/08/2025",
      "message": "I feel a bit stress today",
    },
    {
      "date": "11/08/2025",
      "message": "my friend make me angry",
    },
    {
      "date": "10/08/2025",
      "message": "I feel so lucky today",
    },
  ];

  // Colors extracted from design
  final Color _bgWhite = const Color(0xFFF7F7F7);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  final Color _textBlack = const Color(0xFF1A1A1A);

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

                  // 3. History List
                  // We map the data list to widgets
                  ..._chatHistory.map((chat) {
                    return _buildHistoryCard(chat['message']!, chat['date']!);
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

  Widget _buildHistoryCard(String message, String date) {
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
            message,
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