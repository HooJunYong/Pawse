import 'dart:convert';

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
}
