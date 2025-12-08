import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF422006),
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF422006),
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: December 8, 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                '1. Introduction',
                'Welcome to Pawse. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our application and tell you about your privacy rights and how the law protects you.',
              ),
              _buildSection(
                '2. Data We Collect',
                'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together follows:\n\n• Identity Data: includes first name, last name, username or similar identifier.\n• Contact Data: includes email address and telephone number.\n• Technical Data: includes internet protocol (IP) address, your login data, browser type and version, time zone setting and location.',
              ),
              _buildSection(
                '3. How We Use Your Data',
                'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:\n\n• Where we need to perform the contract we are about to enter into or have entered into with you.\n• Where it is necessary for our legitimate interests (or those of a third party) and your interests and fundamental rights do not override those interests.\n• Where we need to comply with a legal or regulatory obligation.',
              ),
              _buildSection(
                '4. Data Security',
                'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used or accessed in an unauthorized way, altered or disclosed. In addition, we limit access to your personal data to those employees, agents, contractors and other third parties who have a business need to know.',
              ),
              _buildSection(
                '5. Your Legal Rights',
                'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to request access, correction, erasure, restriction, transfer, to object to processing, to portability of data and (where the lawful ground of processing is consent) to withdraw consent.',
              ),
              _buildSection(
                '6. Contact Us',
                'If you have any questions about this privacy policy or our privacy practices, please contact us via the "Contact Us" section in the app.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF422006),
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
