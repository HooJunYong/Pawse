import 'package:flutter/material.dart';

import 'meditation_screen.dart';

class BreathingPlayerScreen extends StatelessWidget {
  final String title;
  const BreathingPlayerScreen({Key? key, required this.title}) : super(key: key);

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
        title: Text(
          title,
          style: const TextStyle(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'Get Ready',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '1:00',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Session Duration',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.blue,
                child: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
