import 'package:flutter/material.dart';

import 'meditation_screen.dart';

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
      body: Center(
        child: Container(
          width: 375,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
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
        ),
      ),
    );
  }
}
