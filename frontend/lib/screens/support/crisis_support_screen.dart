import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CrisisSupportScreen extends StatelessWidget {
  const CrisisSupportScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

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
          'Crisis Support',
          style: TextStyle(
            color: Color(0xFF422006),
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You Are Not Alone',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontFamily: 'Nunito',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you are in immediate distress, please reach out. Help is available.',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontFamily: 'Nunito',
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Emergency Hotlines Section
                const Text(
                  'Emergency Hotlines',
                  style: TextStyle(
                    color: Color(0xFF422006),
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Befrienders KL
                _buildHotlineCard(
                  context: context,
                  icon: Icons.phone_in_talk,
                  name: 'Befrienders KL',
                  description: '24-hour emotional support',
                  phoneNumber: '0376272929',
                  displayNumber: '03-7627 2929',
                ),

                const SizedBox(height: 12),

                // Talian Kasih
                _buildHotlineCard(
                  context: context,
                  icon: Icons.phone_in_talk,
                  name: 'Talian Kasih',
                  description: 'National crisis hotline',
                  phoneNumber: '15999',
                  displayNumber: '15999',
                ),

                const SizedBox(height: 12),

                // MIASA
                _buildHotlineCard(
                  context: context,
                  icon: Icons.phone_in_talk,
                  name: 'MIASA',
                  description: 'Mental health support',
                  phoneNumber: '1800180066',
                  displayNumber: '1800 180 066',
                ),

                const SizedBox(height: 32),

                // Additional Resources
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFFF97316),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Remember',
                            style: TextStyle(
                              color: Color(0xFF422006),
                              fontFamily: 'Nunito',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• These services are confidential and free\n'
                        '• Trained counselors are available to listen\n'
                        '• You can call anonymously\n'
                        '• There is no problem too small or too big',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Emergency Services
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF5350), width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'In case of medical emergency',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _makePhoneCall('999'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF5350),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.local_hospital, size: 24),
                        label: const Text(
                          'Call 999',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineCard({
    required BuildContext context,
    required IconData icon,
    required String name,
    required String description,
    required String phoneNumber,
    required String displayNumber,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makePhoneCall(phoneNumber),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFEF5350),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF422006),
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Nunito',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayNumber,
                        style: const TextStyle(
                          color: Color(0xFFF97316),
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.phone,
                  color: Color(0xFFF97316),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
