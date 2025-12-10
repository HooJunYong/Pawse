import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_model.dart';
import 'api_service.dart';

/// Singleton service to manage notifications with polling and local notifications
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  static NotificationManager get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final StreamController<List<NotificationModel>> _notificationsController =
      StreamController<List<NotificationModel>>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  Timer? _pollingTimer;
  String? _currentUserId;
  List<NotificationModel> _notifications = [];
  Set<String> _seenNotificationIds = {};
  bool _isInitialized = false;

  /// Stream of notifications
  Stream<List<NotificationModel>> get notificationsStream => _notificationsController.stream;

  /// Stream of unread count
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Get current notifications list
  List<NotificationModel> get notifications => _notifications;

  /// Get current unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize notification manager
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      return; // Already initialized for this user
    }

    _currentUserId = userId;
    _isInitialized = true;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Load initial notifications
    await fetchNotifications();

    // Start polling every 30 seconds
    startPolling();
  }

  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - you can navigate to specific screens here
    final String? payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        // Navigate based on notification data
        debugPrint('Notification tapped: $data');
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Start polling for new notifications
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications(showLocalNotification: true);
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
  }

  /// Fetch notifications from server
  Future<void> fetchNotifications({bool showLocalNotification = false}) async {
    if (_currentUserId == null) return;

    try {
      final response = await ApiService.get('/notifications/$_currentUserId?limit=50');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        final newNotifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // Check for new notifications
        if (showLocalNotification) {
          for (final notification in newNotifications) {
            if (!_seenNotificationIds.contains(notification.notificationId)) {
              // Only show local notification if it's not read
              if (!notification.isRead) {
                _showLocalNotification(notification);
              }
              _seenNotificationIds.add(notification.notificationId);
            }
          }
        } else {
          // Initial load - mark all as seen so we don't spam local notifications
          _seenNotificationIds.addAll(
            newNotifications.map((n) => n.notificationId),
          );
        }

        _notifications = newNotifications;
        _notificationsController.add(_notifications);
        _unreadCountController.add(unreadCount);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pawse_notifications',
      'Pawse Notifications',
      channelDescription: 'Notifications from Pawse app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        notification.body,
        htmlFormatBigText: true,
        contentTitle: notification.title,
        htmlFormatContentTitle: true,
        summaryText: 'Pawse',
        htmlFormatSummaryText: true,
      ),
      enableLights: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: null,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.notificationId.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: jsonEncode(notification.data),
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.post('/notifications/$notificationId/read', {});

      if (response.statusCode == 200) {
        // Update local state
        _notifications = _notifications.map((n) {
          if (n.notificationId == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        _notificationsController.add(_notifications);
        _unreadCountController.add(unreadCount);
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    
    for (final notification in unreadNotifications) {
      await markAsRead(notification.notificationId);
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    if (_currentUserId == null) return;

    try {
      final response = await ApiService.post('/notifications/test/$_currentUserId', {});

      if (response.statusCode == 200) {
        // Refresh notifications
        await Future.delayed(const Duration(seconds: 1));
        await fetchNotifications(showLocalNotification: true);
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  /// Clear all notifications
  void clear() {
    _notifications.clear();
    _seenNotificationIds.clear();
    _notificationsController.add(_notifications);
    _unreadCountController.add(0);
  }

  /// Dispose
  void dispose() {
    _pollingTimer?.cancel();
    _notificationsController.close();
    _unreadCountController.close();
  }
}
