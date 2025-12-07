import 'dart:convert';

import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';
import 'api_service.dart';

class NotificationService {
  static Future<NotificationSettings> getSettings(String userId) async {
    final response = await ApiService.get('/notifications/settings/$userId');

    if (response.statusCode == 200) {
      return NotificationSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load notification settings');
    }
  }

  static Future<NotificationSettings> updateSettings(String userId, Map<String, dynamic> updates) async {
    final response = await ApiService.put(
      '/notifications/settings/$userId',
      updates,
    );

    if (response.statusCode == 200) {
      return NotificationSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update notification settings');
    }
  }

  static Future<List<NotificationModel>> getNotifications(String userId, {int limit = 50}) async {
    final response = await ApiService.get('/notifications/$userId?limit=$limit');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> notifications = data['notifications'] ?? [];
      return notifications.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    final response = await ApiService.post('/notifications/$notificationId/read', {});

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<NotificationModel?> sendTestNotification(String userId) async {
    final response = await ApiService.post('/notifications/test/$userId', {});

    if (response.statusCode == 200) {
      return NotificationModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send test notification');
    }
  }
}
