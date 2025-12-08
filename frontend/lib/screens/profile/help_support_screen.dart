import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F4F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF422006)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF422006),
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF422006),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I book a therapy session?',
              'You can book a session by navigating to the "Find a Therapist" section, selecting a therapist, and choosing an available time slot.',
            ),
            _buildFAQItem(
              'Is my personal information safe?',
              'Yes, we take your privacy seriously. All your data is encrypted and stored securely. We adhere to strict data protection regulations.',
            ),
            _buildFAQItem(
              'How can I change my password?',
              'Go to your Profile page and select "Change Password". Follow the instructions to update your credentials.',
            ),
            _buildFAQItem(
              'What if I need immediate help?',
              'If you are in a crisis, please use the "Crisis Support" button on the home screen or call emergency services immediately.',
            ),
            _buildFAQItem(
              'Can I cancel a booking?',
              'Yes, you can cancel a booking from your "My Schedule" page up to 24 hours before the scheduled time.',
            ),
            _buildFAQItem(
              'How do I track my mood?',
              'Navigate to the "Journal" section from the home screen. You can log your daily mood, add notes, and track patterns over time.',
            ),
            _buildFAQItem(
              'What is the breathing exercise feature?',
              'The breathing exercise helps you relax and reduce anxiety. Access it from the home screen and follow the guided breathing patterns.',
            ),
            _buildFAQItem(
              'Can I message my therapist directly?',
              'Yes, once you have a confirmed booking with a therapist, you can message them through the chat feature in the app.',
            ),
            _buildFAQItem(
              'How does the music therapy work?',
              'Our music section offers curated playlists based on your current mood. Simply select your mood and listen to calming tracks.',
            ),
            _buildFAQItem(
              'What should I do if I forget my password?',
              'On the login screen, tap "Forgot Password" and follow the instructions to reset your password via email.',
            ),
            _buildFAQItem(
              'Are therapy sessions confidential?',
              'Absolutely. All therapy sessions and conversations are completely confidential and comply with professional standards.',
            ),
            _buildFAQItem(
              'How do I update my profile information?',
              'Go to the Profile tab, tap "Edit Profile", and you can update your name, email, phone number, and profile picture.',
            ),
            _buildFAQItem(
              'Can I become a therapist on this platform?',
              'Yes! Click "Join as a Therapist" in your profile to submit an application. Our team will review your credentials.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF422006),
            fontFamily: 'Nunito',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
