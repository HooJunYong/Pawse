/// Model for mood entry data used in the mood tracking UI
class MoodEntry {
  final String moodId;
  final String moodLevel;
  final String? note;
  final DateTime date;

  const MoodEntry({
    required this.moodId,
    required this.moodLevel,
    this.note,
    required this.date,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      moodId: json['mood_id'] ?? '',
      moodLevel: json['mood_level'] ?? '',
      note: json['note'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood_id': moodId,
      'mood_level': moodLevel,
      'note': note,
      'date': date.toIso8601String().split('T')[0],
    };
  }

  /// Convert to map format used by calendar display
  Map<String, dynamic> toDisplayMap() {
    return {
      'mood_id': moodId,
      'mood_level': moodLevel,
      'note': note,
    };
  }

  MoodEntry copyWith({
    String? moodId,
    String? moodLevel,
    String? note,
    DateTime? date,
  }) {
    return MoodEntry(
      moodId: moodId ?? this.moodId,
      moodLevel: moodLevel ?? this.moodLevel,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}

/// Model for weekly chart data point
class WeeklyChartDataPoint {
  final DateTime date;
  final int day;
  final String? moodLevel;

  const WeeklyChartDataPoint({
    required this.date,
    required this.day,
    this.moodLevel,
  });

  /// Get numeric value for chart (0 = no data, 1-5 = mood levels)
  int get moodValue {
    switch (moodLevel) {
      case 'very happy':
        return 5;
      case 'happy':
        return 4;
      case 'neutral':
        return 3;
      case 'sad':
        return 2;
      case 'awful':
        return 1;
      default:
        return 0;
    }
  }
}

/// Model for monthly mood statistics
class MonthlyMoodStats {
  final Map<String, int> moodCounts;

  const MonthlyMoodStats({required this.moodCounts});

  factory MonthlyMoodStats.empty() {
    return const MonthlyMoodStats(moodCounts: {
      'very happy': 0,
      'happy': 0,
      'neutral': 0,
      'sad': 0,
      'awful': 0,
    });
  }

  factory MonthlyMoodStats.fromMoodList(List<dynamic> moods) {
    final Map<String, int> counts = {
      'very happy': 0,
      'happy': 0,
      'neutral': 0,
      'sad': 0,
      'awful': 0,
    };

    for (var mood in moods) {
      final level = mood['mood_level'] as String;
      if (counts.containsKey(level)) {
        counts[level] = counts[level]! + 1;
      }
    }

    return MonthlyMoodStats(moodCounts: counts);
  }

  int getCount(String moodLevel) => moodCounts[moodLevel] ?? 0;

  int get maxCount {
    int max = 1;
    for (var count in moodCounts.values) {
      if (count > max) max = count;
    }
    return max;
  }
}
