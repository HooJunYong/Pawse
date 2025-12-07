import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

class IntelligentNudgeService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Consistent notification ID for mood nudges (for easy cancellation)
  static const int moodNudgeNotificationId = 1001;

  /// Initialize the notification plugin
  static Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Set local timezone (Malaysia)
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _requestPermissions();
  }

  /// Request notification permissions (especially for iOS)
  static Future<void> _requestPermissions() async {
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Also request for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation or actions when user taps the notification
    // You can add navigation logic here if needed
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule a mood nudge notification
  /// 
  /// This function:
  /// 1. Checks if intelligent nudges are enabled in user settings
  /// 2. Cancels any previously scheduled mood nudge
  /// 3. Schedules a new notification for 10 minutes after the mood update
  /// 
  /// Parameters:
  /// - userId: The user's ID to check their notification settings
  /// - updatedAt: The timestamp when the mood was saved/updated
  /// - affirmationText: The personalized affirmation message to display
  static Future<void> scheduleMoodNudge({
    required String userId,
    required DateTime updatedAt,
    required String affirmationText,
  }) async {
    try {
      // 1. Check if intelligent nudges are enabled
      final settings = await NotificationService.getSettings(userId);
      
      if (!settings.allNotificationsEnabled || !settings.intelligentNudges) {
        print('Intelligent nudges are disabled. Skipping notification.');
        return;
      }

      // 2. Cancel any existing mood nudge notification
      await cancelMoodNudge();

      // 3. Calculate trigger time (10 minutes after updatedAt)
      final triggerTime = updatedAt.add(const Duration(minutes: 10));
      
      // Check if trigger time is in the future
      if (triggerTime.isBefore(DateTime.now())) {
        print('Trigger time is in the past. Skipping notification.');
        return;
      }

      // Convert to timezone-aware datetime
      final scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);

      // 4. Configure notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'mood_nudges', // Channel ID
        'Mood Nudges', // Channel name
        channelDescription: 'Personalized mood-based affirmations',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 5. Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        moodNudgeNotificationId,
        '🐾 Pawse',
        affirmationText,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'mood_nudge',
      );

      print('Mood nudge scheduled for: ${scheduledDate.toString()}');
    } catch (e) {
      print('Error scheduling mood nudge: $e');
    }
  }

  /// Cancel the current mood nudge notification
  /// Use this when the user edits their mood or disables nudges
  static Future<void> cancelMoodNudge() async {
    try {
      await _notificationsPlugin.cancel(moodNudgeNotificationId);
      print('Mood nudge cancelled');
    } catch (e) {
      print('Error cancelling mood nudge: $e');
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// Get list of pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Check if there's a pending mood nudge
  static Future<bool> hasPendingMoodNudge() async {
    final pending = await getPendingNotifications();
    return pending.any((n) => n.id == moodNudgeNotificationId);
  }
}
