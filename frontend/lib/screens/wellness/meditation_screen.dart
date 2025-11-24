import 'package:flutter/material.dart';

import 'meditation_player_screen.dart';

// Theme and color constants (reuse from wellness page)
class AppColors {
  static const Color beige = Color(0xFFF7F4F2);
  static const Color darkBrown = Color(0xFF422006);
  static const Color orange = Color(0xFFF97316);
  static const Color lightOrange = Color(0xFFFFF3E0); // Exact match for wellness recommender card
  static const Color green = Color(0xFF34D399);
  static const Color blue = Color(0xFF818CF8);
}

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.beige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meditation',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 375,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Recommendation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(254, 215, 170, 1),
                      Color.fromRGBO(254, 237, 213, 1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Recommendation",
                      style: TextStyle(
                        fontSize: 19,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A 10-minute session on finding calm in the present moment.',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Nunito',
                        color: AppColors.darkBrown,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MeditationPlayerScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: const [
                              Text(
                                'Begin Session',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Meditation Library',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: const [
                    MeditationLibraryTile(
                      icon: Icons.eco,
                      color: AppColors.green,
                      title: 'Mindfulness',
                      subtitle: 'Focus on the now',
                    ),
                    MeditationLibraryTile(
                      icon: Icons.nightlight_round,
                      color: AppColors.blue,
                      title: 'For Sleep',
                      subtitle: 'Drift off peacefully',
                    ),
                    MeditationLibraryTile(
                      icon: Icons.favorite,
                      color: AppColors.orange,
                      title: 'Gratitude',
                      subtitle: 'Appreciate the good',
                    ),
                    MeditationLibraryTile(
                      icon: Icons.self_improvement,
                      color: AppColors.orange,
                      title: 'For Stress',
                      subtitle: 'Find your inner peace',
                    ),
                    MeditationLibraryTile(
                      icon: Icons.bolt,
                      color: AppColors.orange,
                      title: 'For Focus',
                      subtitle: 'Sharpen your mind',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeditationLibraryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const MeditationLibraryTile({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppColors.darkBrown,
            fontSize: 13,
          ),
        ),
        onTap: () {
          // TODO: Implement navigation to specific meditation session
        },
      ),
    );
  }
}
