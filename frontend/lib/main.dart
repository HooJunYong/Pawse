import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/homepage_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/mood/mood_check_in_screen.dart';
import 'screens/mood/mood_entry_confirmation_screen.dart';
import 'screens/companion/customize_comp_screen.dart';
import 'screens/driftbottle/drift_bottle_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this
  try {
    // Attempt to load the .env file
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If it fails, print the error but continue running the app
    debugPrint("Error loading .env file: $e");
    // You typically don't want to stop the app here, 
    // unless the .env file is absolutely critical for the UI to render.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mental Health Companion',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
