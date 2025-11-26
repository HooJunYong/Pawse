import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Service for mood tracking operations
class MoodService {
  /// Check if user has already logged mood for today
  /// Returns response with {"has_logged_today": bool}
  static Future<http.Response> checkMoodStatus(String userId) async {
    return await ApiService.get('/mood/check-status/$userId');
  }

  /// Submit a new mood check-in entry
  /// Returns the created mood entry
  static Future<http.Response> submitMood({
    required String userId,
    required String moodLevel,
    String? note,
    DateTime? date,
  }) async {
    final moodDate = date ?? DateTime.now();
    return await ApiService.post('/mood', {
      'user_id': userId,
      'mood_level': moodLevel,
      'note': note,
      'date': moodDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
    });
  }

  /// Update an existing mood entry
  /// Returns the updated mood entry
  static Future<http.Response> updateMood({
    required String moodId,
    required String userId,
    String? moodLevel,
    String? note,
  }) async {
    // Build update body with only provided fields
    final Map<String, dynamic> updateBody = {};
    if (moodLevel != null) {
      updateBody['mood_level'] = moodLevel;
    }
    if (note != null) {
      updateBody['note'] = note;
    }

    return await ApiService.put(
      '/mood/$moodId?user_id=$userId',
      updateBody,
    );
  }

  /// Get mood entries for a specific date range
  /// Returns list of mood entries
  static Future<http.Response> getMoodByRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = startDate.toIso8601String().split('T')[0]; // YYYY-MM-DD
    final end = endDate.toIso8601String().split('T')[0]; // YYYY-MM-DD

    return await ApiService.get(
      '/mood/range/$userId?start_date=$start&end_date=$end',
    );
  }

  /// Get mood entries for the current month
  static Future<http.Response> getMoodForCurrentMonth(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return await getMoodByRange(
      userId: userId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Get mood entries for the last N days
  static Future<http.Response> getMoodForLastDays({
    required String userId,
    required int days,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return await getMoodByRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get mood entries for a specific week
  static Future<http.Response> getMoodForWeek({
    required String userId,
    required DateTime weekDate,
  }) async {
    // Get Monday of the week
    final monday = weekDate.subtract(Duration(days: weekDate.weekday - 1));
    // Get Sunday of the week
    final sunday = monday.add(const Duration(days: 6));

    return await getMoodByRange(
      userId: userId,
      startDate: monday,
      endDate: sunday,
    );
  }
}
