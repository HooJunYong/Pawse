import 'package:flutter/material.dart';

// Theme and color constants (reuse from wellness page)
class AppColors {
  static const Color beige = Color(0xFFF7F4F2);
  static const Color darkBrown = Color(0xFF422006);
  static const Color orange = Color(0xFFF97316);
  static const Color lightOrange = Color(0xFFFFEDD5);
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Recommendation Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Recommendation",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A 10-minute session on finding calm in the present moment.',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Begin Session',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.play_arrow, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
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

class MeditationPlayerScreen extends StatelessWidget {
  const MeditationPlayerScreen({Key? key}) : super(key: key);

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(Icons.eco, color: AppColors.green, size: 64),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Finding Calm',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A 10-minute guided session to focus on the now.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: AppColors.darkBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('4:30', style: TextStyle(fontFamily: 'Nunito', color: AppColors.darkBrown)),
                Text('10:00', style: TextStyle(fontFamily: 'Nunito', color: AppColors.darkBrown)),
              ],
            ),
            Slider(
              value: 4.5,
              min: 0,
              max: 10,
              activeColor: AppColors.green,
              inactiveColor: AppColors.green.withOpacity(0.2),
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, color: AppColors.darkBrown, size: 32),
                  onPressed: () {},
                ),
                const SizedBox(width: 32),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.orange,
                  child: IconButton(
                    icon: const Icon(Icons.pause, color: Colors.white, size: 36),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: AppColors.darkBrown, size: 32),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
