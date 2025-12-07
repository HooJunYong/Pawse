import 'package:shared_preferences/shared_preferences.dart';

class MeditationProgressService {
  static const String _keyPrefix = 'meditation_progress';

  static Future<void> markCompleted({
    required String userId,
    DateTime? timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime recordedTime = (timestamp ?? DateTime.now()).toLocal();
    final String key = _buildKey(userId, recordedTime);
    await prefs.setString(key, recordedTime.toIso8601String());
  }

  static Future<DateTime?> getCompletionForDay({
    required String userId,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime targetDate = (date ?? DateTime.now()).toLocal();
    final String key = _buildKey(userId, targetDate);
    final String? stored = prefs.getString(key);
    if (stored == null || stored.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(stored).toLocal();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCompletionForDay({
    required String userId,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime targetDate = (date ?? DateTime.now()).toLocal();
    final String key = _buildKey(userId, targetDate);
    await prefs.remove(key);
  }

  static String _buildKey(String userId, DateTime date) {
    final DateTime localDate = date.toLocal();
    final String day = localDate.day.toString().padLeft(2, '0');
    final String month = localDate.month.toString().padLeft(2, '0');
    return '$_keyPrefix:$userId:${localDate.year}-$month-$day';
  }
}
