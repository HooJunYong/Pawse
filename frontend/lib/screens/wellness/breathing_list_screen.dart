import 'package:flutter/material.dart';

import 'meditation_screen.dart';

class BreathingListScreen extends StatelessWidget {
  const BreathingListScreen({Key? key}) : super(key: key);

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
          'Breathing',
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              BreathingExerciseTile(
                icon: Icons.crop_square,
                color: AppColors.orange,
                title: 'Box Breathing',
                subtitle: 'A simple technique to calm your nervous system and enhance focus.',
              ),
              const SizedBox(height: 16),
              BreathingExerciseTile(
                icon: Icons.nightlight_round,
                color: AppColors.blue,
                title: '4-7-8 Breathing',
                subtitle: 'Helps reduce anxiety and can aid in falling asleep.',
              ),
              const SizedBox(height: 16),
              BreathingExerciseTile(
                icon: Icons.air,
                color: AppColors.green,
                title: 'Diaphragmatic Breathing',
                subtitle: 'Strengthens your diaphragm and increases lung efficiency.',
              ),
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

  const BreathingExerciseTile({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // TODO: Implement navigation to breathing player
        },
      ),
    );
  }
}
