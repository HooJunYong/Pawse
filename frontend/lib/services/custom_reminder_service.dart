import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for handling custom reminders:
/// - Journaling Routine (daily at specific time)
/// - Hydration Reminders (every X hours from 8am to 10pm)
/// - Breathing Practices (daily at specific time)
class CustomReminderService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _journalingChannelId = 'journaling_routine';
  static const String _hydrationChannelId = 'hydration_reminders';
  static const String _breathingChannelId = 'breathing_practices';

  // Notification IDs
  static const int _journalingNotificationId = 2001;
  static const int _breathingNotificationId = 2002;
  static const int _hydrationBaseNotificationId = 3000; // 3000-3099 for hydration slots

  /// Initialize the custom reminder service
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    print('CustomReminderService initialized');
  }

  /// Create notification channels
  static Future<void> _createNotificationChannels() async {
    const journalingChannel = AndroidNotificationChannel(
      _journalingChannelId,
      'Journaling Routine',
      description: 'Daily reminders for journaling',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const hydrationChannel = AndroidNotificationChannel(
      _hydrationChannelId,
      'Hydration Reminders',
      description: 'Reminders to drink water throughout the day',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const breathingChannel = AndroidNotificationChannel(
      _breathingChannelId,
      'Breathing Practices',
      description: 'Daily reminders for breathing exercises',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(journalingChannel);
    await androidPlugin?.createNotificationChannel(hydrationChannel);
    await androidPlugin?.createNotificationChannel(breathingChannel);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Custom reminder tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Schedule journaling reminder
  /// 
  /// Schedules a daily notification at the specified time
  /// 
  /// Parameters:
  /// - time: Time in "HH:mm" format (24-hour), e.g., "20:00" for 8:00 PM
  static Future<void> scheduleJournalingReminder(String time) async {
    try {
      // Parse time string (e.g., "20:00")
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Get current time and create scheduled time for today
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _journalingChannelId,
        'Journaling Routine',
        channelDescription: 'Daily reminders for journaling',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule daily repeating notification
      await _notifications.zonedSchedule(
        _journalingNotificationId,
        '📔 Time to Journal',
        'Take a moment to reflect on your day and track your mood.',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'journaling',
      );

      print('Journaling reminder scheduled for $time daily');
    } catch (e) {
      print('Error scheduling journaling reminder: $e');
    }
  }

  /// Cancel journaling reminder
  static Future<void> cancelJournalingReminder() async {
    try {
      await _notifications.cancel(_journalingNotificationId);
      print('Journaling reminder cancelled');
    } catch (e) {
      print('Error cancelling journaling reminder: $e');
    }
  }

  /// Schedule hydration reminders
  /// 
  /// Schedules reminders every X hours from 8:00 AM to 10:00 PM
  /// 
  /// Parameters:
  /// - intervalMinutes: Interval between reminders (e.g., 120 for 2 hours)
  static Future<void> scheduleHydrationReminders(int intervalMinutes) async {
    try {
      // Cancel existing hydration reminders first
      await cancelHydrationReminders();

      // Convert minutes to hours for easier calculation
      final intervalHours = intervalMinutes / 60;

      // Start time: 8:00 AM
      const startHour = 8;
      // End time: 10:00 PM (22:00)
      const endHour = 22;

      final now = tz.TZDateTime.now(tz.local);
      var currentHour = startHour.toDouble();
      int notificationIndex = 0;

      // Schedule reminders from 8 AM to 10 PM
      while (currentHour < endHour) {
        final hour = currentHour.floor();
        final minute = ((currentHour - hour) * 60).round();

        // Create scheduled time for today
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // If the scheduled time has passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        const androidDetails = AndroidNotificationDetails(
          _hydrationChannelId,
          'Hydration Reminders',
          channelDescription: 'Reminders to drink water throughout the day',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Schedule daily repeating notification
        await _notifications.zonedSchedule(
          _hydrationBaseNotificationId + notificationIndex,
          '💧 Hydration Reminder',
          'Time to drink water! Stay hydrated throughout the day.',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
          payload: 'hydration',
        );

        print('Hydration reminder scheduled for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');

        currentHour += intervalHours;
        notificationIndex++;

        // Safety limit: max 20 reminders per day
        if (notificationIndex >= 20) break;
      }

      print('Hydration reminders scheduled every $intervalMinutes minutes (8 AM - 10 PM)');
    } catch (e) {
      print('Error scheduling hydration reminders: $e');
    }
  }

  /// Cancel all hydration reminders
  static Future<void> cancelHydrationReminders() async {
    try {
      // Cancel all hydration notification IDs (3000-3019)
      for (int i = 0; i < 20; i++) {
        await _notifications.cancel(_hydrationBaseNotificationId + i);
      }
      print('Hydration reminders cancelled');
    } catch (e) {
      print('Error cancelling hydration reminders: $e');
    }
  }

  /// Schedule breathing practice reminder
  /// 
  /// Schedules a daily notification at the specified time
  /// 
  /// Parameters:
  /// - time: Time in "HH:mm" format (24-hour), e.g., "08:00" for 8:00 AM
  static Future<void> scheduleBreathingReminder(String time) async {
    try {
      // Parse time string (e.g., "08:00")
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Get current time and create scheduled time for today
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _breathingChannelId,
        'Breathing Practices',
        channelDescription: 'Daily reminders for breathing exercises',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule daily repeating notification
      await _notifications.zonedSchedule(
        _breathingNotificationId,
        '🌿 Breathing Practice',
        'Take a deep breath and relax. Practice mindful breathing.',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'breathing',
      );

      print('Breathing reminder scheduled for $time daily');
    } catch (e) {
      print('Error scheduling breathing reminder: $e');
    }
  }

  /// Cancel breathing reminder
  static Future<void> cancelBreathingReminder() async {
    try {
      await _notifications.cancel(_breathingNotificationId);
      print('Breathing reminder cancelled');
    } catch (e) {
      print('Error cancelling breathing reminder: $e');
    }
  }

  /// Cancel all custom reminders
  static Future<void> cancelAllReminders() async {
    await cancelJournalingReminder();
    await cancelHydrationReminders();
    await cancelBreathingReminder();
    print('All custom reminders cancelled');
  }

  /// Get list of pending reminders (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }
}
