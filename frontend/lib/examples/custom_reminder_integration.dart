import 'package:flutter/material.dart';

import '../services/custom_reminder_service.dart';
import '../services/notification_service.dart';

/// Example integration for Custom Reminders (Journaling, Hydration, Breathing)
class CustomReminderIntegration {
  
  /// Setup journaling reminder when user enables it
  /// 
  /// Call this when:
  /// - User toggles journaling reminder ON
  /// - User changes journaling time
  static Future<void> setupJournalingReminder({
    required String userId,
    required bool enabled,
    required String time, // Format: "HH:mm" (24-hour)
    BuildContext? context,
  }) async {
    try {
      if (enabled) {
        // Schedule the reminder
        await CustomReminderService.scheduleJournalingReminder(time);
        
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Journaling reminder set for $time daily'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        print('Journaling reminder enabled at $time');
      } else {
        // Cancel the reminder
        await CustomReminderService.cancelJournalingReminder();
        
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journaling reminder cancelled'),
            ),
          );
        }
        
        print('Journaling reminder disabled');
      }
    } catch (e) {
      print('Error setting up journaling reminder: $e');
    }
  }

  /// Setup hydration reminders when user enables it
  /// 
  /// Call this when:
  /// - User toggles hydration reminder ON
  /// - User changes hydration frequency
  static Future<void> setupHydrationReminders({
    required String userId,
    required bool enabled,
    required int intervalMinutes, // e.g., 120 for every 2 hours
    BuildContext? context,
  }) async {
    try {
      if (enabled) {
        // Schedule the reminders (8am - 10pm)
        await CustomReminderService.scheduleHydrationReminders(intervalMinutes);
        
        final hours = intervalMinutes / 60;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hydration reminders set every ${hours}h (8 AM - 10 PM)'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        print('Hydration reminders enabled every $intervalMinutes minutes');
      } else {
        // Cancel the reminders
        await CustomReminderService.cancelHydrationReminders();
        
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hydration reminders cancelled'),
            ),
          );
        }
        
        print('Hydration reminders disabled');
      }
    } catch (e) {
      print('Error setting up hydration reminders: $e');
    }
  }

  /// Setup breathing practice reminder when user enables it
  /// 
  /// Call this when:
  /// - User toggles breathing reminder ON
  /// - User changes breathing time
  static Future<void> setupBreathingReminder({
    required String userId,
    required bool enabled,
    required String time, // Format: "HH:mm" (24-hour)
    BuildContext? context,
  }) async {
    try {
      if (enabled) {
        // Schedule the reminder
        await CustomReminderService.scheduleBreathingReminder(time);
        
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Breathing reminder set for $time daily'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        print('Breathing reminder enabled at $time');
      } else {
        // Cancel the reminder
        await CustomReminderService.cancelBreathingReminder();
        
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Breathing reminder cancelled'),
            ),
          );
        }
        
        print('Breathing reminder disabled');
      }
    } catch (e) {
      print('Error setting up breathing reminder: $e');
    }
  }

  /// Load existing reminder settings on app start or screen load
  static Future<void> loadAndApplyReminders(String userId) async {
    try {
      // Get current settings from backend
      final settings = await NotificationService.getSettings(userId);

      // Apply journaling reminder if enabled
      if (settings.journalingRoutineEnabled) {
        await CustomReminderService.scheduleJournalingReminder(
          settings.journalingTime,
        );
      }

      // Apply hydration reminders if enabled
      if (settings.hydrationRemindersEnabled) {
        await CustomReminderService.scheduleHydrationReminders(
          settings.hydrationIntervalMinutes,
        );
      }

      // Apply breathing reminder if enabled
      if (settings.breathingPracticesEnabled) {
        await CustomReminderService.scheduleBreathingReminder(
          settings.breathingTime,
        );
      }

      print('Custom reminders loaded and applied');
    } catch (e) {
      print('Error loading custom reminders: $e');
    }
  }
}

/// ============================================================================
/// INTEGRATION GUIDE
/// ============================================================================
/// 
/// 1. IN YOUR NOTIFICATION SETTINGS SCREEN:
/// 
/// When user toggles journaling reminder:
/// ```dart
/// onChanged: (value) async {
///   await CustomReminderIntegration.setupJournalingReminder(
///     userId: userId,
///     enabled: value,
///     time: journalingTime, // from picker
///     context: context,
///   );
///   
///   // Update backend
///   await NotificationService.updateSettings(userId, {
///     'journaling_routine_enabled': value,
///     'journaling_time': journalingTime,
///   });
/// }
/// ```
/// 
/// When user changes journaling time:
/// ```dart
/// onTimeSelected: (time) async {
///   // Format time as "HH:mm"
///   final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
///   
///   await CustomReminderIntegration.setupJournalingReminder(
///     userId: userId,
///     enabled: true,
///     time: timeString,
///     context: context,
///   );
///   
///   // Update backend
///   await NotificationService.updateSettings(userId, {
///     'journaling_time': timeString,
///   });
/// }
/// ```
/// 
/// When user toggles hydration reminder:
/// ```dart
/// onChanged: (value) async {
///   await CustomReminderIntegration.setupHydrationReminders(
///     userId: userId,
///     enabled: value,
///     intervalMinutes: hydrationInterval, // 120 for 2 hours
///     context: context,
///   );
///   
///   // Update backend
///   await NotificationService.updateSettings(userId, {
///     'hydration_reminders_enabled': value,
///     'hydration_interval_minutes': hydrationInterval,
///   });
/// }
/// ```
/// 
/// When user changes hydration frequency:
/// ```dart
/// onIntervalSelected: (minutes) async {
///   await CustomReminderIntegration.setupHydrationReminders(
///     userId: userId,
///     enabled: true,
///     intervalMinutes: minutes, // 60, 120, 180, etc.
///     context: context,
///   );
///   
///   // Update backend
///   await NotificationService.updateSettings(userId, {
///     'hydration_interval_minutes': minutes,
///   });
/// }
/// ```
/// 
/// When user toggles breathing reminder:
/// ```dart
/// onChanged: (value) async {
///   await CustomReminderIntegration.setupBreathingReminder(
///     userId: userId,
///     enabled: value,
///     time: breathingTime, // from picker
///     context: context,
///   );
///   
///   // Update backend
///   await NotificationService.updateSettings(userId, {
///     'breathing_practices_enabled': value,
///     'breathing_time': breathingTime,
///   });
/// }
/// ```
/// 
/// 2. ON APP START (in main.dart or home screen):
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   // Load and apply reminders
///   CustomReminderIntegration.loadAndApplyReminders(userId);
/// }
/// ```
/// 
/// ============================================================================
/// NOTIFICATION BEHAVIORS
/// ============================================================================
/// 
/// JOURNALING ROUTINE:
/// - Frequency: Once per day
/// - Time: User-selected (default: 8:00 PM)
/// - Title: "📔 Time to Journal"
/// - Message: "Take a moment to reflect on your day and track your mood."
/// 
/// HYDRATION REMINDERS:
/// - Frequency: Every X hours (user-selected)
/// - Time Range: 8:00 AM to 10:00 PM
/// - Example: If interval = 2 hours → 8am, 10am, 12pm, 2pm, 4pm, 6pm, 8pm, 10pm
/// - Title: "💧 Hydration Reminder"
/// - Message: "Time to drink water! Stay hydrated throughout the day."
/// - Automatically repeats next day
/// 
/// BREATHING PRACTICES:
/// - Frequency: Once per day
/// - Time: User-selected (default: 8:00 AM)
/// - Title: "🌿 Breathing Practice"
/// - Message: "Take a deep breath and relax. Practice mindful breathing."
/// 
/// ============================================================================
/// EXAMPLE: Time Picker for Custom Time Selection
/// ============================================================================

class TimePickerExample extends StatelessWidget {
  final String userId;
  final String initialTime;
  final Function(String) onTimeSelected;

  const TimePickerExample({
    super.key,
    required this.userId,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Select Time'),
      trailing: Text(initialTime),
      onTap: () async {
        // Parse initial time
        final parts = initialTime.split(':');
        final initialTimeOfDay = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        // Show time picker
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTimeOfDay,
        );

        if (picked != null) {
          // Format as "HH:mm"
          final timeString =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeSelected(timeString);
        }
      },
    );
  }
}

/// ============================================================================
/// EXAMPLE: Interval Selector for Hydration
/// ============================================================================

class HydrationIntervalSelector extends StatelessWidget {
  final int currentInterval;
  final Function(int) onIntervalSelected;

  const HydrationIntervalSelector({
    super.key,
    required this.currentInterval,
    required this.onIntervalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Frequency',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<int>(
          value: currentInterval,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 60, child: Text('Every 1 hour')),
            DropdownMenuItem(value: 120, child: Text('Every 2 hours')),
            DropdownMenuItem(value: 180, child: Text('Every 3 hours')),
            DropdownMenuItem(value: 240, child: Text('Every 4 hours')),
          ],
          onChanged: (value) {
            if (value != null) {
              onIntervalSelected(value);
            }
          },
        ),
      ],
    );
  }
}
