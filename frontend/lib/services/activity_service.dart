import 'dart:convert';
import 'api_service.dart';

/// Service for handling activity and gamification operations
class ActivityService {
  /// Get user's daily activities with progress
  static Future<Map<String, dynamic>?> getDailyActivities(String userId) async {
    try {
      final response = await ApiService.get('/api/activities/daily/$userId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get daily activities: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting daily activities: $e');
    }
  }

  /// Get user's current rank details
  static Future<Map<String, dynamic>?> getUserRank(String userId) async {
    try {
      final response = await ApiService.get('/api/activities/rank/$userId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user rank: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user rank: $e');
    }
  }

  /// Get user's progress towards next rank
  static Future<Map<String, dynamic>?> getRankProgress(String userId) async {
    try {
      final response = await ApiService.get('/api/activities/rank/progress/$userId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get rank progress: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting rank progress: $e');
    }
  }

  /// Track an activity action
  static Future<Map<String, dynamic>?> trackActivity({
    required String userId,
    required String actionKey,
  }) async {
    try {
      final response = await ApiService.post('/api/activities/track', {
        'user_id': userId,
        'action_key': actionKey,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to track activity: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error tracking activity: $e');
    }
  }

  /// Check and assign daily activities (called on login)
  static Future<Map<String, dynamic>?> checkAndAssignActivities(String userId) async {
    try {
      final response = await ApiService.post('/api/activities/check-and-assign/$userId', {});

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check/assign activities: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking/assigning activities: $e');
    }
  }
}
