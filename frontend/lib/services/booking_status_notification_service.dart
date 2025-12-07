import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling booking status change notifications
/// Shows notifications when:
/// - Client cancels booking (notify therapist)
/// - Therapist cancels booking (notify client)
/// - Booking is rescheduled
/// - Session status changes
class BookingStatusNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel ID for booking status
  static const String _channelId = 'booking_status_changes';
  static const String _channelName = 'Booking Status Changes';
  static const String _channelDescription =
      'Notifications for booking cancellations and status updates';

  /// Initialize the notification service
  /// Call this in main.dart during app startup
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

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('BookingStatusNotificationService initialized');
  }

  /// Handle notification tap - navigate to appropriate screen
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate based on payload
    // 'client_cancelled:sessionId' -> Navigate to therapist's schedule
    // 'therapist_cancelled:sessionId' -> Navigate to client's bookings
    print('Booking status notification tapped: ${response.payload}');
  }

  /// Show notification when client cancels a booking
  /// 
  /// Parameters:
  /// - therapistUserId: The therapist's user ID
  /// - clientName: Name of the client who cancelled
  /// - sessionDate: Date of the cancelled session
  /// - sessionTime: Time of the cancelled session
  /// - reason: Optional cancellation reason
  static Future<void> notifyTherapistOfCancellation({
    required String therapistUserId,
    required String clientName,
    required String sessionDate,
    required String sessionTime,
    String? reason,
  }) async {
    try {
      final notificationId = _generateNotificationId(therapistUserId);

      // Create notification message
      final String body = reason != null && reason.isNotEmpty
          ? 'Client: $clientName cancelled session on $sessionDate at $sessionTime. Reason: $reason'
          : 'Client: $clientName cancelled session on $sessionDate at $sessionTime.';

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: '❌ Session Cancelled',
          summaryText: 'Pawse',
        ),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _notifications.show(
        notificationId,
        '❌ Session Cancelled',
        '$clientName cancelled the session on $sessionDate at $sessionTime.',
        notificationDetails,
        payload: 'client_cancelled:$therapistUserId:$sessionDate:$sessionTime',
      );

      print('Cancellation notification sent to therapist: $therapistUserId');
    } catch (e) {
      print('Error showing therapist cancellation notification: $e');
    }
  }

  /// Show notification when therapist cancels a booking
  /// 
  /// Parameters:
  /// - clientUserId: The client's user ID
  /// - therapistName: Name of the therapist who cancelled
  /// - sessionDate: Date of the cancelled session
  /// - sessionTime: Time of the cancelled session
  /// - reason: Optional cancellation reason
  static Future<void> notifyClientOfCancellation({
    required String clientUserId,
    required String therapistName,
    required String sessionDate,
    required String sessionTime,
    String? reason,
  }) async {
    try {
      final notificationId = _generateNotificationId(clientUserId);

      // Create notification message
      final String expandedBody = reason != null && reason.isNotEmpty
          ? 'Dr. $therapistName has cancelled your session scheduled for $sessionDate at $sessionTime. '
              'Reason: $reason. Please reschedule or contact support if needed.'
          : 'Dr. $therapistName has cancelled your session scheduled for $sessionDate at $sessionTime. '
              'Please reschedule or contact support if needed.';

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          expandedBody,
          contentTitle: '❌ Session Cancelled by Therapist',
          summaryText: 'Pawse',
        ),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show the notification
      await _notifications.show(
        notificationId,
        '❌ Session Cancelled by Therapist',
        'Dr. $therapistName cancelled your session on $sessionDate at $sessionTime.',
        notificationDetails,
        payload: 'therapist_cancelled:$clientUserId:$sessionDate:$sessionTime',
      );

      print('Cancellation notification sent to client: $clientUserId');
    } catch (e) {
      print('Error showing client cancellation notification: $e');
    }
  }

  /// Show notification when session is rescheduled
  /// 
  /// Parameters:
  /// - userId: User ID to notify (therapist or client)
  /// - otherPartyName: Name of the other party
  /// - oldDate: Original session date
  /// - oldTime: Original session time
  /// - newDate: New session date
  /// - newTime: New session time
  /// - isTherapist: True if notifying therapist, false if notifying client
  static Future<void> notifyOfReschedule({
    required String userId,
    required String otherPartyName,
    required String oldDate,
    required String oldTime,
    required String newDate,
    required String newTime,
    required bool isTherapist,
  }) async {
    try {
      final notificationId = _generateNotificationId(userId);

      final String title = '📅 Session Rescheduled';
      final String body = isTherapist
          ? '$otherPartyName has rescheduled the session from $oldDate at $oldTime to $newDate at $newTime.'
          : 'Dr. $otherPartyName has rescheduled your session from $oldDate at $oldTime to $newDate at $newTime.';

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Pawse',
        ),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'rescheduled:$userId:$newDate:$newTime',
      );

      print('Reschedule notification sent to user: $userId');
    } catch (e) {
      print('Error showing reschedule notification: $e');
    }
  }

  /// Show notification when session status changes (completed, no-show, etc.)
  /// 
  /// Parameters:
  /// - userId: User ID to notify
  /// - sessionDate: Date of the session
  /// - sessionTime: Time of the session
  /// - status: New status (completed, no_show, etc.)
  /// - isTherapist: True if notifying therapist, false if notifying client
  static Future<void> notifyOfStatusChange({
    required String userId,
    required String sessionDate,
    required String sessionTime,
    required String status,
    required bool isTherapist,
  }) async {
    try {
      final notificationId = _generateNotificationId(userId);

      String title = '';
      String body = '';

      switch (status.toLowerCase()) {
        case 'completed':
          title = '✅ Session Completed';
          body = isTherapist
              ? 'Your session on $sessionDate at $sessionTime has been marked as completed.'
              : 'Your therapy session on $sessionDate at $sessionTime is complete. Please take a moment to rate your experience.';
          break;
        case 'no_show':
          title = '⚠️ Session No-Show';
          body = 'The session scheduled for $sessionDate at $sessionTime was marked as no-show.';
          break;
        case 'in_progress':
          title = '🔵 Session In Progress';
          body = 'Your session on $sessionDate at $sessionTime is now in progress.';
          break;
        default:
          title = 'Session Status Update';
          body = 'Your session on $sessionDate at $sessionTime status: $status';
      }

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'status_change:$userId:$status',
      );

      print('Status change notification sent to user: $userId');
    } catch (e) {
      print('Error showing status change notification: $e');
    }
  }

  /// Cancel notification for a specific user
  static Future<void> cancelBookingNotification(String userId) async {
    try {
      final notificationId = _generateNotificationId(userId);
      await _notifications.cancel(notificationId);
      print('Cancelled booking notification for user: $userId');
    } catch (e) {
      print('Error cancelling booking notification: $e');
    }
  }

  /// Cancel all booking notifications
  static Future<void> cancelAllBookingNotifications() async {
    try {
      await _notifications.cancelAll();
      print('Cancelled all booking notifications');
    } catch (e) {
      print('Error cancelling all booking notifications: $e');
    }
  }

  /// Check if notification permissions are granted
  static Future<bool> areNotificationsEnabled() async {
    if (_notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>() !=
        null) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()!
              .areNotificationsEnabled() ??
          false;
    }
    return true; // iOS permissions checked at runtime
  }

  /// Request notification permissions (mainly for iOS)
  static Future<bool> requestPermissions() async {
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  /// Generate a unique notification ID from user ID
  static int _generateNotificationId(String userId) {
    // Use hashCode to generate consistent ID for same user
    // Add offset to avoid collision with other notification services
    return (userId.hashCode.abs() % 100000) + 6000;
  }
}
