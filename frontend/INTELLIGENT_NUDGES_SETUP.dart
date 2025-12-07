/// INTELLIGENT NUDGES SETUP GUIDE
/// 
/// Follow these steps to integrate the Intelligent Nudges feature into your app:

/// ==========================================
/// STEP 1: Add Dependencies to pubspec.yaml
/// ==========================================

/*
dependencies:
  flutter_local_notifications: ^17.0.0
  timezone: ^0.9.2
  
Then run: flutter pub get
*/

/// ==========================================
/// STEP 2: Update main.dart
/// ==========================================

/*
import 'package:flutter/material.dart';
import 'services/intelligent_nudge_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Intelligent Nudge Service
  await IntelligentNudgeService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawse',
      // ... rest of your app configuration
    );
  }
}
*/

/// ==========================================
/// STEP 3: Android Configuration
/// ==========================================

/*
File: android/app/src/main/AndroidManifest.xml

Add these permissions INSIDE the <manifest> tag (before <application>):

<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

Add this INSIDE the <application> tag (after your MainActivity):

<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
*/

/// ==========================================
/// STEP 4: iOS Configuration
/// ==========================================

/*
No additional configuration needed for iOS!
The service automatically requests permissions at runtime.
*/

/// ==========================================
/// STEP 5: Usage in Your Mood Service
/// ==========================================

/*
Example integration in your existing mood save function:

import '../services/intelligent_nudge_service.dart';

Future<void> saveMood(String userId, String moodType, String? notes) async {
  try {
    // 1. Save mood to backend
    final response = await http.post(
      Uri.parse('$apiUrl/mood'),
      body: jsonEncode({
        'user_id': userId,
        'mood_type': moodType,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final updatedAt = DateTime.parse(data['updated_at']);

      // 2. Generate affirmation
      final affirmation = _generateAffirmation(moodType);

      // 3. Schedule intelligent nudge
      await IntelligentNudgeService.scheduleMoodNudge(
        userId: userId,
        updatedAt: updatedAt,
        affirmationText: affirmation,
      );
    }
  } catch (e) {
    print('Error saving mood: $e');
  }
}

String _generateAffirmation(String moodType) {
  final affirmations = {
    'happy': 'Your joy is contagious! Keep spreading those positive vibes. 🌟',
    'sad': 'It\'s okay to feel sad. Remember, you\'re stronger than you think. 💙',
    'anxious': 'Take a deep breath. You\'ve overcome challenges before, and you will again. 🌿',
    'angry': 'Your feelings are valid. Channel this energy into something positive. 🔥',
    'calm': 'You\'re finding your center. This peace is your superpower. 🕊️',
  };
  
  return affirmations[moodType] ?? 'You matter. Your feelings matter. Keep going. 💜';
}
*/

/// ==========================================
/// STEP 6: Handle Settings Toggle
/// ==========================================

/*
When user disables "Intelligent Nudges" in settings:

import '../services/intelligent_nudge_service.dart';

Future<void> onIntelligentNudgesToggle(bool enabled) async {
  if (!enabled) {
    // Cancel any pending mood nudges
    await IntelligentNudgeService.cancelMoodNudge();
  }
  
  // Update settings in backend
  await NotificationService.updateSettings(userId, {
    'intelligent_nudges': enabled,
  });
}
*/

/// ==========================================
/// STEP 7: Testing
/// ==========================================

/*
To test the feature:

1. Enable "Intelligent Nudges" in notification settings
2. Save a mood entry
3. Wait 10 minutes (or change device time to test)
4. You should receive a notification with the affirmation

Debug commands:
- Check pending notifications: await IntelligentNudgeService.getPendingNotifications()
- Check if mood nudge is pending: await IntelligentNudgeService.hasPendingMoodNudge()
- Cancel mood nudge: await IntelligentNudgeService.cancelMoodNudge()
*/

/// ==========================================
/// KEY FEATURES
/// ==========================================

/*
✅ Automatic cancellation when mood is edited (debouncing)
✅ Uses consistent notification ID (1001) for easy management
✅ Checks user preferences before scheduling
✅ Respects both global and intelligent nudges toggles
✅ Works with timezone (Malaysia/Asia/Kuala_Lumpur)
✅ Android exact alarm scheduling (works even if app is closed)
✅ iOS notification support with proper permissions
✅ Error handling and logging
*/

/// ==========================================
/// TROUBLESHOOTING
/// ==========================================

/*
If notifications don't appear:

1. Check permissions are granted (Settings > App > Notifications)
2. Verify intelligent_nudges is true in notification settings
3. Check device time is correct
4. For Android 12+, ensure exact alarm permission is granted
5. Test with a shorter delay (e.g., 1 minute) for debugging
6. Check logs for any error messages

Common issues:
- Background restrictions: Disable battery optimization for your app
- Do Not Disturb: Check if DND is blocking notifications
- Channel settings: User may have disabled the "Mood Nudges" channel
*/
