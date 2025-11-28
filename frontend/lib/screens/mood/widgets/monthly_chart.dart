import 'package:flutter/material.dart';
import '../../../models/mood_entry.dart';

/// Monthly bar chart widget for mood tracking statistics
class MonthlyChart extends StatelessWidget {
  final MonthlyMoodStats moodStats;

  // Colors
  static const Color _veryHappyMood = Color(0xFF9BB168);
  static const Color _happyMood = Color(0xFFFFCE5C);
  static const Color _neutralMood = Color(0xFFC0A091);
  static const Color _sadMood = Color(0xFFED7E1C);
  static const Color _awfulMood = Color(0xFFA694F5);

  const MonthlyChart({
    Key? key,
    required this.moodStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final moodOrder = ['very happy', 'happy', 'neutral', 'sad', 'awful'];
    final moodAssets = [
      'assets/images/mood_very_happy.png',
      'assets/images/mood_happy.png',
      'assets/images/mood_neutral.png',
      'assets/images/mood_sad.png',
      'assets/images/mood_awful.png',
    ];
    final moodColors = [
      _veryHappyMood,
      _happyMood,
      _neutralMood,
      _sadMood,
      _awfulMood,
    ];

    final maxCount = moodStats.maxCount;

    return Column(
      children: List.generate(5, (index) {
        final mood = moodOrder[index];
        final count = moodStats.getCount(mood);
        final percentage = maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _buildAssetEmoji(moodAssets[index]),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Filled bar
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: moodColors[index],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 30,
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAssetEmoji(String path) {
    return SizedBox(
      height: 24,
      width: 24,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error_outline, size: 24, color: Colors.grey);
        },
      ),
    );
  }
}
