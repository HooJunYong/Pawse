import 'dart:convert';

class BreathStep {
  BreathStep({required this.label, required this.seconds});

  final String label;
  final int seconds;

  factory BreathStep.fromJson(Map<String, dynamic> json) {
    return BreathStep(
      label: json['label']?.toString() ?? '',
      seconds: (json['seconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'seconds': seconds,
      };
}

class BreathPattern {
  BreathPattern({required this.steps, required this.cycles});

  final List<BreathStep> steps;
  final int cycles;

  factory BreathPattern.fromJson(Map<String, dynamic> json) {
    final List<dynamic> stepList = json['steps'] as List<dynamic>? ?? const [];
    return BreathPattern(
      steps: stepList
          .map((dynamic step) => BreathStep.fromJson(
                step is Map<String, dynamic>
                    ? step
                    : jsonDecode(jsonEncode(step)) as Map<String, dynamic>,
              ))
          .where((step) => step.seconds > 0 && step.label.isNotEmpty)
          .toList(growable: false),
      cycles: (json['cycles'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'steps': steps.map((step) => step.toJson()).toList(growable: false),
        'cycles': cycles,
      };

  int get totalSeconds =>
      steps.fold<int>(0, (sum, step) => sum + step.seconds) * cycles;
}

class BreathingExercise {
  BreathingExercise({
    required this.exerciseId,
    required this.name,
    required this.description,
    required this.pattern,
    this.focusArea,
    this.durationSeconds,
    this.durationLabel,
    this.tags,
    this.metadata,
  });

  final String exerciseId;
  final String name;
  final String description;
  final BreathPattern pattern;
  final String? focusArea;
  final int? durationSeconds;
  final String? durationLabel;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  factory BreathingExercise.fromJson(Map<String, dynamic> json) {
    return BreathingExercise(
      exerciseId: json['exercise_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      focusArea: json['focus_area']?.toString(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      durationLabel: json['duration_label']?.toString(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((dynamic tag) => tag.toString())
          .toList(growable: false),
      pattern: BreathPattern.fromJson(
        json['pattern'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }
}

enum BreathingSessionStatus { completed, incomplete }

class BreathingSession {
  BreathingSession({
    required this.sessionId,
    required this.userId,
    required this.exerciseId,
    required this.cyclesCompleted,
    required this.startedAt,
    required this.completedAt,
    required this.createdAt,
    this.durationSeconds,
    this.moodBefore,
    this.moodAfter,
    this.notes,
  });

  final String sessionId;
  final String userId;
  final String exerciseId;
  final int cyclesCompleted;
  final DateTime startedAt;
  final DateTime completedAt;
  final DateTime createdAt;
  final int? durationSeconds;
  final int? moodBefore;
  final int? moodAfter;
  final String? notes;

  factory BreathingSession.fromJson(Map<String, dynamic> json) {
    return BreathingSession(
      sessionId: json['session_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      exerciseId: json['exercise_id']?.toString() ?? '',
      cyclesCompleted: (json['cycles_completed'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      moodBefore: (json['mood_before'] as num?)?.toInt(),
      moodAfter: (json['mood_after'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  BreathingSessionStatus statusForPattern(BreathPattern pattern) {
    if (cyclesCompleted >= pattern.cycles) {
      return BreathingSessionStatus.completed;
    }
    return BreathingSessionStatus.incomplete;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
