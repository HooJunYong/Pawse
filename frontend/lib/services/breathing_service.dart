import 'dart:convert';

import '../models/breathing_models.dart';
import 'api_service.dart';

class BreathingApiService {
  Future<List<BreathingExercise>> getExercises() async {
    final response = await ApiService.get('/breathing/exercises');
    if (response.statusCode != 200) {
      throw Exception('Failed to load breathing exercises');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((dynamic item) => BreathingExercise.fromJson(
              (item is Map<String, dynamic>)
                  ? item
                  : jsonDecode(jsonEncode(item)) as Map<String, dynamic>,
            ))
        .where((exercise) => exercise.exerciseId.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<BreathingSession>> getSessions(
    String userId, {
    int limit = 20,
  }) async {
    final response = await ApiService.get('/breathing/sessions/$userId?limit=$limit');
    if (response.statusCode != 200) {
      throw Exception('Failed to load breathing sessions');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    final sessions = data
        .map((dynamic item) => BreathingSession.fromJson(
              (item is Map<String, dynamic>)
                  ? item
                  : jsonDecode(jsonEncode(item)) as Map<String, dynamic>,
            ))
        .toList(growable: false);
    sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sessions;
  }

  Future<BreathingSession> logSession({
    required String userId,
    required String exerciseId,
    required int cyclesCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    int? moodBefore,
    int? moodAfter,
    String? notes,
  }) async {
    final Map<String, dynamic> payload = {
      'user_id': userId,
      'exercise_id': exerciseId,
      'cycles_completed': cyclesCompleted,
      if (durationSeconds != null && durationSeconds > 0)
        'duration_seconds': durationSeconds,
      if (startedAt != null) 'started_at': startedAt.toUtc().toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt.toUtc().toIso8601String(),
      if (moodBefore != null) 'mood_before': moodBefore,
      if (moodAfter != null) 'mood_after': moodAfter,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await ApiService.post('/breathing/sessions', payload);
    if (response.statusCode != 200) {
      throw Exception('Failed to save breathing session');
    }
    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return BreathingSession.fromJson(data);
  }
}
