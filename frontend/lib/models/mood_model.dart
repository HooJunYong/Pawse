// Model for mood data
class Mood {
  final String moodId;
  final String userId;
  final DateTime date;
  final String moodLevel;
  final String? note;

  Mood({
    required this.moodId,
    required this.userId,
    required this.date,
    required this.moodLevel,
    this.note,
  });

  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      moodId: json['mood_id'] ?? '',
      userId: json['user_id'] ?? '',
      date: DateTime.parse(json['date']),
      moodLevel: json['mood_level'] ?? '',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood_id': moodId,
      'user_id': userId,
      'date': date.toIso8601String(),
      'mood_level': moodLevel,
      'note': note,
    };
  }
}