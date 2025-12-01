import 'package:flutter/material.dart';

import '../../widgets/bottom_nav.dart';
import 'breathing_list_screen.dart';
import 'journaling_screen.dart';
import 'meditation_screen.dart';
import 'music_screen.dart';


class WellnessScreen extends StatefulWidget {
  final String userId;
  const WellnessScreen({super.key, required this.userId});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  @override
  Widget build(BuildContext context) {
    final _DailyRecommendation recommendation = _getDailyRecommendation(context);
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
                      gradient: LinearGradient(
                        colors: recommendation.gradientColors,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                recommendation.icon,
                                size: 18,
                                color: const Color.fromRGBO(66, 32, 6, 1),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                recommendation.activityLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  color: Color.fromRGBO(66, 32, 6, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          recommendation.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(92, 64, 51, 1),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: recommendation.buttonColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 2,
                          ),
                          onPressed: recommendation.onStart,
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BreathingListScreen(),
                              ),
                            );
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MeditationScreen(),
                              ),
                            );
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MusicScreen(),
                              ),
                            );
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
      bottomNavigationBar: BottomNavBar(
        userId: widget.userId,
        selectedIndex: 4, // Wellness/Flower icon is at index 4
        onTap: (index) {
          // Handle navigation for other tabs if needed
        },
      ),
    );
  }

  _DailyRecommendation _getDailyRecommendation(BuildContext context) {
    final List<_DailyRecommendation> options = [
      _DailyRecommendation(
        activityLabel: 'Gratitude Journaling',
        description: 'Write down three moments you appreciated today to cultivate a grateful mindset.',
        gradientColors: const [Color(0xFFFED7AA), Color(0xFFFEE6D4)],
        buttonColor: const Color.fromRGBO(66, 32, 6, 1),
        icon: Icons.menu_book_rounded,
        onStart: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalingScreen(userId: widget.userId),
            ),
          );
        },
      ),
      _DailyRecommendation(
        activityLabel: 'Deep Breathing',
        description: 'Spend four minutes with box breathing—inhale, hold, exhale, and rest on a steady four-count.',
        gradientColors: const [Color(0xFFBBF7D0), Color(0xFFD1FAE5)],
        buttonColor: const Color(0xFF047857),
        icon: Icons.air,
        onStart: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BreathingListScreen(),
            ),
          );
        },
      ),
      _DailyRecommendation(
        activityLabel: 'Guided Meditation',
        description: 'Take a mindful pause with a gentle body-scan meditation to release lingering tension.',
        gradientColors: const [Color(0xFFC7D2FE), Color(0xFFE0E7FF)],
        buttonColor: const Color(0xFF4338CA),
        icon: Icons.self_improvement,
        onStart: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MeditationScreen(),
            ),
          );
        },
      ),
      _DailyRecommendation(
        activityLabel: 'Mindful Music Break',
        description: 'Choose a soothing playlist and notice one instrument at a time as you listen without distractions.',
        gradientColors: const [Color(0xFFFBCFE8), Color(0xFFFCE7F3)],
        buttonColor: const Color(0xFFBE185D),
        icon: Icons.music_note,
        onStart: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MusicScreen(),
            ),
          );
        },
      ),
    ];

    final DateTime today = DateTime.now().toUtc();
    final int daySeed =
        DateTime.utc(today.year, today.month, today.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    final int index = daySeed % options.length;
    return options[index];
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

class _DailyRecommendation {
  const _DailyRecommendation({
    required this.activityLabel,
    required this.description,
    required this.gradientColors,
    required this.buttonColor,
    required this.icon,
    required this.onStart,
  });

  final String activityLabel;
  final String description;
  final List<Color> gradientColors;
  final Color buttonColor;
  final IconData icon;
  final VoidCallback onStart;
}