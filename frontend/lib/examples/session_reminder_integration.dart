import 'package:flutter/material.dart';

import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../services/session_reminder_service.dart';

/// Example of how to integrate Session Reminders into your booking flow
/// 
/// IMPORTANT: Add this to your booking screens where sessions are created/cancelled
class SessionReminderIntegration {
  
  /// Call this after successfully creating a booking
  /// 
  /// When to use:
  /// 1. After client books a new session
  /// 2. After therapist accepts a booking
  /// 3. After session is confirmed
  static Future<void> onSessionCreated({
    required TherapySession session,
    required String currentUserId,
    BuildContext? context,
  }) async {
    try {
      // 1. Check if therapy session notifications are enabled
      final settings = await NotificationService.getSettings(currentUserId);
      
      if (!settings.allNotificationsEnabled || !settings.therapySessions) {
        print('Therapy session notifications are disabled. Skipping reminder.');
        return;
      }

      // 2. Schedule the session reminder (1 hour before)
      await SessionReminderService.scheduleSessionReminder(
        session,
        currentUserId,
      );

      // 3. Show confirmation to user (optional)
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session reminder set! You\'ll be notified 1 hour before.'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
      }

      print('Session reminder scheduled successfully for session: ${session.sessionId}');
    } catch (e) {
      print('Error scheduling session reminder: $e');
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not set reminder: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Call this when a booking is cancelled
  static Future<void> onSessionCancelled({
    required String sessionId,
    BuildContext? context,
  }) async {
    try {
      await SessionReminderService.cancelSessionReminder(sessionId);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session reminder cancelled'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('Session reminder cancelled successfully');
    } catch (e) {
      print('Error cancelling session reminder: $e');
    }
  }

  /// Call this when a booking time is updated/rescheduled
  static Future<void> onSessionRescheduled({
    required TherapySession updatedSession,
    required String currentUserId,
    BuildContext? context,
  }) async {
    try {
      // Check if notifications are enabled
      final settings = await NotificationService.getSettings(currentUserId);
      
      if (!settings.allNotificationsEnabled || !settings.therapySessions) {
        print('Therapy session notifications are disabled. Skipping reminder.');
        return;
      }

      // Reschedule the reminder with new time
      await SessionReminderService.rescheduleSessionReminder(
        updatedSession,
        currentUserId,
      );

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session reminder updated!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('Session reminder rescheduled successfully');
    } catch (e) {
      print('Error rescheduling session reminder: $e');
    }
  }

  /// Call this when user toggles therapy session notifications in settings
  static Future<void> onTherapySessionToggle({
    required bool enabled,
    required String userId,
  }) async {
    if (!enabled) {
      // Cancel all pending session reminders
      await SessionReminderService.cancelAllSessionReminders();
      print('All session reminders cancelled due to settings change');
    } else {
      print('Therapy session notifications enabled. Future bookings will have reminders.');
    }
  }
}

/// ============================================================================
/// INTEGRATION GUIDE
/// ============================================================================
/// 
/// 1. In your booking success screen (after session is booked):
/// ```dart
/// // After successful booking
/// await SessionReminderIntegration.onSessionCreated(
///   session: createdSession,  // TherapySession object from API response
///   currentUserId: userId,
///   context: context,
/// );
/// ```
/// 
/// 2. In your cancel session handler:
/// ```dart
/// await SessionReminderIntegration.onSessionCancelled(
///   sessionId: session.sessionId,
///   context: context,
/// );
/// ```
/// 
/// 3. In your reschedule handler:
/// ```dart
/// await SessionReminderIntegration.onSessionRescheduled(
///   updatedSession: rescheduledSession,
///   currentUserId: userId,
///   context: context,
/// );
/// ```
/// 
/// 4. In notification_screen.dart settings toggle:
/// ```dart
/// onChanged: (value) async {
///   if (settingType == 'therapy_sessions' && !value) {
///     await SessionReminderIntegration.onTherapySessionToggle(
///       enabled: value,
///       userId: widget.userId,
///     );
///   }
///   // ... rest of your toggle logic
/// }
/// ```
/// 
/// 5. Don't forget to initialize in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize session reminders
///   await SessionReminderService.initialize();
///   
///   runApp(MyApp());
/// }
/// ```
