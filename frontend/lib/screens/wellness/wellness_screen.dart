import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'journaling_screen.dart';

class WellnessScreen extends StatefulWidget {
  final String userId;
  const WellnessScreen({super.key, required this.userId});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(66, 32, 6, 1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wellness Activities',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Recommendation Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(254, 215, 170, 1),
                          Color.fromRGBO(254, 237, 213, 1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Recommendation",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(66, 32, 6, 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A 5-minute gratitude journaling session to start your day.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(92, 64, 51, 1),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JournalingScreen(userId: widget.userId),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start Now',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Explore Activities Section
                  const Text(
                    'Explore Activities',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Activities Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityCard(
                          'Journaling',
                          Icons.menu_book,
                          const Color.fromRGBO(251, 146, 60, 1),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JournalingScreen(userId: widget.userId),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActivityCard(
                          'Breathing',
                          Icons.air,
                          const Color.fromRGBO(251, 146, 60, 1),
                          () {
                            // Navigate to breathing
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityCard(
                          'Meditation',
                          Icons.self_improvement,
                          const Color.fromRGBO(251, 191, 36, 1),
                          () {
                            // Navigate to meditation
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActivityCard(
                          'Music',
                          Icons.music_note,
                          const Color.fromRGBO(236, 72, 153, 1),
                          () {
                            // Navigate to music
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Your Progress Section
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Items
                  _buildProgressItem(
                    'Meditation',
                    'Yesterday, 8:15 AM',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressItem(
                    'Box Breathing',
                    'Today, 9:00 AM',
                    true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 375,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.military_tech_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(249, 115, 22, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profile(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, String time, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(107, 114, 128, 1),
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color.fromRGBO(34, 197, 94, 1),
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(34, 197, 94, 1),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}