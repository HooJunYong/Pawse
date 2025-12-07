import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling therapist application status notifications
/// Shows notifications when:
/// - Application is approved by admin
/// - Application is rejected by admin
class TherapistApplicationNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel ID for therapist applications
  static const String _channelId = 'therapist_applications';
  static const String _channelName = 'Therapist Applications';
  static const String _channelDescription =
      'Notifications for therapist application status updates';

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
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('TherapistApplicationNotificationService initialized');
  }

  /// Handle notification tap - navigate to appropriate screen
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate based on payload
    // 'approved' -> Navigate to therapist setup page
    // 'rejected' -> Navigate to rejection reason screen
    print('Application notification tapped: ${response.payload}');
  }

  /// Show notification when application is approved
  /// 
  /// Parameters:
  /// - userId: The user ID of the applicant
  /// - firstName: First name of the therapist
  /// - lastName: Last name of the therapist
  static Future<void> showApprovedNotification({
    required String userId,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final fullName = '$firstName $lastName';
      
      // Generate unique notification ID from user ID
      final notificationId = _generateNotificationId(userId);

      // Create notification with congratulations message
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          'Congratulations! Your therapist application has been approved. '
          'Tap here to set up your therapist profile and start offering your services.',
          contentTitle: '🎉 Application Approved!',
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
        '🎉 Application Approved!',
        'Congratulations $fullName! Tap to set up your therapist profile.',
        notificationDetails,
        payload: 'approved:$userId',
      );

      print('Approval notification sent to: $fullName');
    } catch (e) {
      print('Error showing approval notification: $e');
    }
  }

  /// Show notification when application is rejected
  /// 
  /// Parameters:
  /// - userId: The user ID of the applicant
  /// - firstName: First name of the applicant
  /// - lastName: Last name of the applicant
  /// - rejectionReason: The reason provided by admin for rejection
  static Future<void> showRejectedNotification({
    required String userId,
    required String firstName,
    required String lastName,
    required String rejectionReason,
  }) async {
    try {
      final fullName = '$firstName $lastName';
      
      // Generate unique notification ID from user ID
      final notificationId = _generateNotificationId(userId);

      // Truncate reason if too long
      final reasonPreview = rejectionReason.length > 100
          ? '${rejectionReason.substring(0, 97)}...'
          : rejectionReason;

      // Create notification with rejection message
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          'We regret to inform you that your therapist application has been rejected. '
          'Tap here to view the reason and learn how to improve your application.',
          contentTitle: 'Application Update',
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
        'Application been rejected.',
        'Your application has been reviewed. Tap to see details.',
        notificationDetails,
        payload: 'rejected:$userId:$rejectionReason',
      );

      print('Rejection notification sent to: $fullName');
    } catch (e) {
      print('Error showing rejection notification: $e');
    }
  }

  /// Cancel notification for a specific user
  static Future<void> cancelApplicationNotification(String userId) async {
    try {
      final notificationId = _generateNotificationId(userId);
      await _notifications.cancel(notificationId);
      print('Cancelled application notification for user: $userId');
    } catch (e) {
      print('Error cancelling application notification: $e');
    }
  }

  /// Cancel all application notifications
  static Future<void> cancelAllApplicationNotifications() async {
    try {
      await _notifications.cancelAll();
      print('All application notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }

  /// Check if notification permissions are granted
  static Future<bool> areNotificationsEnabled() async {
    final plugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (plugin != null) {
      final granted = await plugin.areNotificationsEnabled();
      return granted ?? false;
    }
    
    return true; // Assume enabled for iOS
  }

  /// Request notification permissions (mainly for iOS)
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

  /// Generate a unique notification ID from user ID
  static int _generateNotificationId(String userId) {
    // Use hash code and ensure it's positive
    // Add offset to avoid conflicts with other notification types
    return (userId.hashCode.abs() % 2147483647) + 5000;
  }
}
