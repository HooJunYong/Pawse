import 'package:flutter/material.dart';

import 'breathing_player_screen.dart';

// --- Theme Constants ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _textDark = Color(0xFF3E2723);
const Color _textGrey = Color(0xFF8D6E63);
const Color _surfaceWhite = Colors.white;

// Exercise specific colors
const Color _orangeAccent = Color(0xFFFB923C);
const Color _blueAccent = Color(0xFF60A5FA);
const Color _greenAccent = Color(0xFF34D399);

const _breathingExercises = [
  (
    icon: Icons.crop_square_rounded,
    color: _orangeAccent,
    title: 'Box Breathing',
    subtitle:
        'A simple technique to calm your nervous system and enhance focus.',
    durationLabel: '4 min',
    pattern: BreathPattern(
      steps: [
        BreathStep(label: 'Inhale', seconds: 4),
        BreathStep(label: 'Hold', seconds: 4),
        BreathStep(label: 'Exhale', seconds: 4),
        BreathStep(label: 'Hold', seconds: 4),
      ],
      cycles: 4,
    ),
  ),
  (
    icon: Icons.nightlight_round,
    color: _blueAccent,
    title: '4-7-8 Breathing',
    subtitle: 'Helps reduce anxiety and can aid in falling asleep.',
    durationLabel: '5 min',
    pattern: BreathPattern(
      steps: [
        BreathStep(label: 'Inhale', seconds: 4),
        BreathStep(label: 'Hold', seconds: 7),
        BreathStep(label: 'Exhale', seconds: 8),
      ],
      cycles: 4,
    ),
  ),
  (
    icon: Icons.air,
    color: _greenAccent,
    title: 'Diaphragmatic',
    subtitle: 'Strengthens your diaphragm and increases lung efficiency.',
    durationLabel: '3 min',
    pattern: BreathPattern(
      steps: [
        BreathStep(label: 'Inhale', seconds: 4),
        BreathStep(label: 'Exhale', seconds: 6),
      ],
      cycles: 6,
    ),
  ),
];

class BreathingListScreen extends StatelessWidget {
  const BreathingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Breathing',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _textDark,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              for (final exercise in _breathingExercises) ...[
                BreathingExerciseTile(
                  icon: exercise.icon,
                  color: exercise.color,
                  title: exercise.title,
                  subtitle: exercise.subtitle,
                  duration: exercise.durationLabel,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BreathingPlayerScreen(
                          title: exercise.title,
                          pattern: exercise.pattern,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BreathingExerciseTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String duration;
  final VoidCallback onTap;

  const BreathingExerciseTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.duration = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                              fontSize: 16,
                            ),
                          ),
                          if (duration.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _bgCream,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                duration,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _textGrey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: _textGrey,
                          fontSize: 13,
                          height: 1.4,
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
}