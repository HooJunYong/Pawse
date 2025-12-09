import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/chat_message.dart';

/// Service for handling chat message notifications
/// Shows notifications when:
/// - Client receives message from therapist
/// - Therapist receives message from client
class ChatNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  // Notification channel ID for chat messages
  static const String _channelId = 'chat_messages';
  static const String _channelName = 'Chat Messages';
  static const String _channelDescription =
      'Notifications for new chat messages';

  /// Show notification for a new chat message
  /// 
  /// Parameters:
  /// - message: The chat message object
  /// - currentUserId: ID of the user receiving the notification
  /// - senderName: Name of the person who sent the message (e.g., "Dr. Sarah" or "John")
  /// - isTherapist: Whether the recipient is a therapist (affects title formatting)
  static Future<void> showMessageNotification({
    required ChatMessage message,
    required String currentUserId,
    required String senderName,
    required bool isTherapist,
  }) async {
    try {
      // Don't show notification if the message is from the current user
      if (message.senderId == currentUserId) {
        print('Message is from current user, skipping notification');
        return;
      }

      // Format the sender name with title if therapist
      final formattedSenderName = isTherapist 
          ? senderName // Client name as-is
          : senderName.startsWith('Dr.') 
              ? senderName 
              : 'Dr. $senderName'; // Add Dr. prefix for therapist

      // Truncate message if too long
      final messagePreview = message.content.length > 100
          ? '${message.content.substring(0, 97)}...'
          : message.content;

      // Generate unique notification ID from message ID
      final notificationId = message.messageId.hashCode.abs() % 2147483647;

      // Create notification
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          messagePreview,
          contentTitle: formattedSenderName,
          summaryText: 'New message',
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
        formattedSenderName,
        messagePreview,
        notificationDetails,
        payload: message.conversationId, // For navigation when tapped
      );

      print('Chat notification sent: $formattedSenderName -> $messagePreview');
    } catch (e) {
      print('Error showing chat notification: $e');
    }
  }

  /// Show notification with simple string message (alternative method)
  /// Use this when you only have basic message data
  static Future<void> showSimpleNotification({
    required String messageId,
    required String conversationId,
    required String senderId,
    required String messageContent,
    required String currentUserId,
    required String senderName,
    required bool isTherapist,
  }) async {
    try {
      // Don't show notification if the message is from the current user
      if (senderId == currentUserId) {
        print('Message is from current user, skipping notification');
        return;
      }

      // Format the sender name with title if therapist
      final formattedSenderName = isTherapist 
          ? senderName // Client name as-is
          : senderName.startsWith('Dr.') 
              ? senderName 
              : 'Dr. $senderName'; // Add Dr. prefix for therapist

      // Truncate message if too long
      final messagePreview = messageContent.length > 100
          ? '${messageContent.substring(0, 97)}...'
          : messageContent;

      // Generate unique notification ID from message ID
      final notificationId = messageId.hashCode.abs() % 2147483647;

      // Create notification
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          messagePreview,
          contentTitle: formattedSenderName,
          summaryText: 'New message',
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
        formattedSenderName,
        messagePreview,
        notificationDetails,
        payload: conversationId, // For navigation when tapped
      );

      print('Chat notification sent: $formattedSenderName -> $messagePreview');
    } catch (e) {
      print('Error showing chat notification: $e');
    }
  }

  /// Show notification for multiple messages (summary style)
  /// Use this when there are multiple unread messages from the same conversation
  static Future<void> showMultipleMessagesNotification({
    required String conversationId,
    required String senderName,
    required int messageCount,
    required bool isTherapist,
  }) async {
    try {
      // Format the sender name with title if therapist
      final formattedSenderName = isTherapist 
          ? senderName 
          : senderName.startsWith('Dr.') 
              ? senderName 
              : 'Dr. $senderName';

      // Generate notification ID from conversation ID
      final notificationId = conversationId.hashCode.abs() % 2147483647;

      final messageText = messageCount == 1
          ? 'You have 1 new message'
          : 'You have $messageCount new messages';

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          messageText,
          contentTitle: formattedSenderName,
          summaryText: 'Chat',
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
        formattedSenderName,
        messageText,
        notificationDetails,
        payload: conversationId,
      );

      print('Multiple messages notification sent: $formattedSenderName ($messageCount messages)');
    } catch (e) {
      print('Error showing multiple messages notification: $e');
    }
  }

  /// Cancel notification for a specific conversation
  /// Use this when user opens the chat screen
  static Future<void> cancelConversationNotification(String conversationId) async {
    try {
      final notificationId = conversationId.hashCode.abs() % 2147483647;
      await _notifications.cancel(notificationId);
      print('Cancelled notification for conversation: $conversationId');
    } catch (e) {
      print('Error cancelling conversation notification: $e');
    }
  }

  /// Cancel all chat notifications
  static Future<void> cancelAllChatNotifications() async {
    try {
      await _notifications.cancelAll();
      print('All chat notifications cancelled');
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
}
