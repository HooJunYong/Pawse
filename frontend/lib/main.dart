import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/auth/login_screen.dart';
import 'services/chat_notification_service.dart';
import 'services/custom_reminder_service.dart';
import 'services/local_notification_service.dart';
import 'services/mood_nudge_service.dart';
import 'services/session_reminder_service.dart';
import 'services/therapist_application_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize notification services
  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();
  
  final moodNudgeService = MoodNudgeService();
  await moodNudgeService.initialize();
  
  // Initialize session reminder service
  await SessionReminderService.initialize();
  
  // Initialize chat notification service
  await ChatNotificationService.initialize();
  
  // Initialize therapist application notification service
  await TherapistApplicationNotificationService.initialize();
  
  // Initialize custom reminder service (journaling, hydration, breathing)
  await CustomReminderService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Mental Health Companion',
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const LoginWidget(),
    );
  }
}
