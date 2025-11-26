import 'package:flutter/material.dart';
import 'mood_entry_confirmation_screen.dart';

class MoodCheckInScreen extends StatelessWidget {
  final String userId;
  const MoodCheckInScreen({super.key, required this.userId});

  static const Color _backgroundColor = Color(0xFFF7F4F2);
  static const Color _textColor = Color(0xFF4F3422);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Text
              const Text(
                "How are you\nfeeling today?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 32,
                  height: 1.2,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Urbanist',
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Emoji
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20.0,
                  children: [
                    _buildMoodIcon(context, 'assets/images/mood_very_happy.png'),
                    _buildMoodIcon(context, 'assets/images/mood_happy.png'),
                    _buildMoodIcon(context, 'assets/images/mood_neutral.png'),
                    _buildMoodIcon(context, 'assets/images/mood_sad.png'),
                    _buildMoodIcon(context, 'assets/images/mood_awful.png'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodIcon(BuildContext context, String assetPath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoodEntryConfirmationScreen(
              selectedMoodAsset: assetPath,
              userId: userId,
            ),
          ),
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain, 
        ),
      ),
    );
  }
}