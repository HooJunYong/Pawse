class NotificationSettings {
  final String userId;
  final bool allNotificationsEnabled;
  final bool intelligentNudges;
  final bool therapySessions;
  final bool journalingRoutineEnabled;
  final String journalingTime;
  final bool hydrationRemindersEnabled;
  final int hydrationIntervalMinutes;
  final bool breathingPracticesEnabled;
  final String breathingTime;

  NotificationSettings({
    required this.userId,
    required this.allNotificationsEnabled,
    required this.intelligentNudges,
    required this.therapySessions,
    required this.journalingRoutineEnabled,
    required this.journalingTime,
    required this.hydrationRemindersEnabled,
    required this.hydrationIntervalMinutes,
    required this.breathingPracticesEnabled,
    required this.breathingTime,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['user_id'],
      allNotificationsEnabled: json['all_notifications_enabled'] ?? true,
      intelligentNudges: json['intelligent_nudges'] ?? true,
      therapySessions: json['therapy_sessions'] ?? true,
      journalingRoutineEnabled: json['journaling_routine_enabled'] ?? false,
      journalingTime: json['journaling_time'] ?? "20:00",
      hydrationRemindersEnabled: json['hydration_reminders_enabled'] ?? false,
      hydrationIntervalMinutes: json['hydration_interval_minutes'] ?? 120,
      breathingPracticesEnabled: json['breathing_practices_enabled'] ?? false,
      breathingTime: json['breathing_time'] ?? "08:00",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'all_notifications_enabled': allNotificationsEnabled,
      'intelligent_nudges': intelligentNudges,
      'therapy_sessions': therapySessions,
      'journaling_routine_enabled': journalingRoutineEnabled,
      'journaling_time': journalingTime,
      'hydration_reminders_enabled': hydrationRemindersEnabled,
      'hydration_interval_minutes': hydrationIntervalMinutes,
      'breathing_practices_enabled': breathingPracticesEnabled,
      'breathing_time': breathingTime,
    };
  }
}
