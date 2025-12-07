import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'booking_service.dart';

class SessionReminderService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification plugin
  static Future<void> initialize() async {
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

    // Request permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    // iOS permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Android 13+ permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation when user taps the notification
    // You can parse the payload and navigate to the session details
    print('Session reminder tapped: ${response.payload}');
  }

  /// Schedule a session reminder notification
  /// 
  /// This function:
  /// 1. Calculates reminder time (1 hour before session)
  /// 2. Determines if user is therapist or client
  /// 3. Creates appropriate notification message
  /// 4. Schedules notification
  /// 
  /// Parameters:
  /// - session: The therapy session object with session details
  /// - currentUserId: The ID of the current logged-in user
  static Future<void> scheduleSessionReminder(
    TherapySession session,
    String currentUserId,
  ) async {
    try {
      // 1. Calculate reminder time (1 hour before session)
      final reminderTime = session.scheduledAt.subtract(const Duration(hours: 1));

      // 2. Check if reminder time is in the past
      if (reminderTime.isBefore(DateTime.now())) {
        print('Reminder time is in the past. Skipping notification.');
        return;
      }

      // 3. Determine if current user is therapist or client
      final isTherapist = currentUserId == session.therapistUserId;

      // 4. Format session time for display
      final formattedTime = session.startTime; // Already formatted (e.g., "10:00 AM")

      // 5. Create notification title and body based on role
      String notificationTitle = 'Session Reminder';
      String notificationBody;

      if (isTherapist) {
        // User is the therapist - we don't have client name in session, so use generic message
        notificationBody = 
            'Don\'t forget you have a therapy session scheduled '
            'at $formattedTime, don\'t forget.';
      } else {
        // User is the client
        notificationBody = 
            'You have a session with Dr. ${session.therapistName} '
            'at $formattedTime, don\'t forget.';
      }

      // 6. Generate unique notification ID from session ID
      final notificationId = _generateNotificationId(session.sessionId);

      // 7. Convert to timezone-aware datetime
      final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

      // 8. Configure notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'therapy_sessions', // Channel ID
        'Therapy Sessions', // Channel name
        channelDescription: 'Reminders for upcoming therapy sessions',
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

      // 9. Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationBody,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'session_reminder:${session.sessionId}',
      );

      print('Session reminder scheduled for: ${scheduledDate.toString()}');
      print('Notification ID: $notificationId');
      print('User role: ${isTherapist ? "Therapist" : "Client"}');
    } catch (e) {
      print('Error scheduling session reminder: $e');
    }
  }

  /// Cancel a specific session reminder
  /// Use this when a session is cancelled or rescheduled
  static Future<void> cancelSessionReminder(String sessionId) async {
    try {
      final notificationId = _generateNotificationId(sessionId);
      await _notificationsPlugin.cancel(notificationId);
      print('Session reminder cancelled for session: $sessionId');
    } catch (e) {
      print('Error cancelling session reminder: $e');
    }
  }

  /// Reschedule a session reminder
  /// Use this when a session time is updated
  static Future<void> rescheduleSessionReminder(
    TherapySession session,
    String currentUserId,
  ) async {
    // Cancel the old notification
    await cancelSessionReminder(session.sessionId);
    
    // Schedule the new notification
    await scheduleSessionReminder(session, currentUserId);
  }

  /// Cancel all session reminders
  static Future<void> cancelAllSessionReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('All session reminders cancelled');
    } catch (e) {
      print('Error cancelling all session reminders: $e');
    }
  }

  /// Get list of pending session reminders (for debugging)
  static Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Check if a session reminder exists
  static Future<bool> hasSessionReminder(String sessionId) async {
    final pending = await getPendingReminders();
    final notificationId = _generateNotificationId(sessionId);
    return pending.any((n) => n.id == notificationId);
  }

  /// Generate a unique notification ID from session ID
  /// Uses hash code to convert string to integer
  static int _generateNotificationId(String sessionId) {
    // Use hash code and ensure it's positive
    return sessionId.hashCode.abs() % 2147483647; // Max int32 value
  }

  /// Send an immediate test reminder (for testing purposes)
  static Future<void> sendTestReminder({
    required String userName,
    required bool isTherapist,
  }) async {
    final title = 'Session Reminder';
    final body = isTherapist
        ? 'Don\'t forget you will have a session with $userName at 10:00 AM, don\'t forget.'
        : 'You have a session with Dr. $userName at 10:00 AM, don\'t forget.';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'therapy_sessions',
      'Therapy Sessions',
      channelDescription: 'Reminders for upcoming therapy sessions',
      importance: Importance.high,
      priority: Priority.high,
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

    await _notificationsPlugin.show(
      999,
      title,
      body,
      notificationDetails,
      payload: 'test_session_reminder',
    );
  }
}
