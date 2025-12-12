import 'package:flutter/material.dart';

class TherapistHelpSupportScreen extends StatelessWidget {
  const TherapistHelpSupportScreen({super.key});

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
              'How Can We Help?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF422006),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find answers to common questions or reach out to our support team.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 32),
            
            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF422006),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFAQCard(
              'How do I manage my availability?',
              'You can set your availability from the Dashboard screen. Navigate to "Manage Availability" to add or edit your available time slots for client bookings.',
            ),
            
            _buildFAQCard(
              'How do I update my profile information?',
              'Go to the Profile tab and tap "Edit Profile". You can update your bio, specializations, languages, hourly rate, and profile picture.',
            ),
            
            _buildFAQCard(
              'How do I view my upcoming sessions?',
              'All your scheduled sessions are displayed on the Dashboard. You can view session details, client information, and session status.',
            ),
            
            _buildFAQCard(
              'How do I communicate with clients?',
              'Use the Chat tab to message your clients. You\'ll receive notifications for new messages and can respond in real-time.',
            ),
            
            _buildFAQCard(
              'How do clients rate my services?',
              'After each completed session, clients can provide a rating and feedback. Your average rating is displayed on your profile and visible to potential clients.',
            ),
            
            _buildFAQCard(
              'What if I need to cancel a session?',
              'If you need to cancel a session, please contact the client as soon as possible through the chat feature. We recommend providing at least 24 hours notice when possible.',
            ),
            
            const SizedBox(height: 32),
            
            // Contact Support Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.headset_mic_outlined,
                    size: 48,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Still Need Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF422006),
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is here to assist you with any questions or concerns.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactButton(
                          icon: Icons.email_outlined,
                          label: 'Email Support',
                          subtitle: 'teampawse@gmail.com',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildContactButton(
                          icon: Icons.phone_outlined,
                          label: 'Call Us',
                          subtitle: '+60 3-7890 1234',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Tips Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF97316).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFF97316),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Quick Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF422006),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Keep your profile updated with accurate information'),
                  _buildTipItem('Respond to client messages promptly'),
                  _buildTipItem('Set clear availability to avoid scheduling conflicts'),
                  _buildTipItem('Maintain professional communication at all times'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF422006),
              fontFamily: 'Nunito',
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontFamily: 'Nunito',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF97316), size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF422006),
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontFamily: 'Nunito',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF422006),
              fontFamily: 'Nunito',
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF422006),
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
