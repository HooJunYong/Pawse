import 'package:flutter/material.dart';

import '../services/booking_status_notification_service.dart';

/// Example integration for Booking Status Notifications
/// Shows how to trigger notifications when bookings are cancelled or status changes
class BookingStatusNotificationIntegration {
  
  /// Trigger when CLIENT cancels a booking
  /// Call this in the booking cancellation flow after successful API call
  static Future<void> onClientCancelBooking({
    required String therapistUserId,
    required String clientName,
    required String sessionDate,
    required String sessionTime,
    String? cancellationReason,
    BuildContext? context,
  }) async {
    try {
      // Send notification to therapist
      await BookingStatusNotificationService.notifyTherapistOfCancellation(
        therapistUserId: therapistUserId,
        clientName: clientName,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        reason: cancellationReason,
      );
      
      print('Therapist notified of client cancellation');
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled. Therapist has been notified.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error sending cancellation notification to therapist: $e');
    }
  }

  /// Trigger when THERAPIST cancels a booking
  /// Call this in the therapist dashboard cancellation flow after successful API call
  static Future<void> onTherapistCancelBooking({
    required String clientUserId,
    required String therapistName,
    required String sessionDate,
    required String sessionTime,
    String? cancellationReason,
    BuildContext? context,
  }) async {
    try {
      // Send notification to client
      await BookingStatusNotificationService.notifyClientOfCancellation(
        clientUserId: clientUserId,
        therapistName: therapistName,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        reason: cancellationReason,
      );
      
      print('Client notified of therapist cancellation');
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled. Client has been notified.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error sending cancellation notification to client: $e');
    }
  }

  /// Trigger when a session is rescheduled
  static Future<void> onSessionRescheduled({
    required String userId,
    required String otherPartyName,
    required String oldDate,
    required String oldTime,
    required String newDate,
    required String newTime,
    required bool isTherapist,
    BuildContext? context,
  }) async {
    try {
      await BookingStatusNotificationService.notifyOfReschedule(
        userId: userId,
        otherPartyName: otherPartyName,
        oldDate: oldDate,
        oldTime: oldTime,
        newDate: newDate,
        newTime: newTime,
        isTherapist: isTherapist,
      );
      
      print('User notified of reschedule');
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Other party has been notified of reschedule.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error sending reschedule notification: $e');
    }
  }

  /// Trigger when session status changes
  static Future<void> onSessionStatusChange({
    required String userId,
    required String sessionDate,
    required String sessionTime,
    required String status,
    required bool isTherapist,
    BuildContext? context,
  }) async {
    try {
      await BookingStatusNotificationService.notifyOfStatusChange(
        userId: userId,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        status: status,
        isTherapist: isTherapist,
      );
      
      print('User notified of status change');
    } catch (e) {
      print('Error sending status change notification: $e');
    }
  }
}

/// ============================================================================
/// INTEGRATION GUIDE
/// ============================================================================
/// 
/// 1. IN CLIENT'S BOOKING CANCELLATION FLOW (homepage_screen.dart):
/// 
/// After successful cancellation API call:
/// ```dart
/// // After BookingService.cancelBooking() succeeds
/// await BookingStatusNotificationIntegration.onClientCancelBooking(
///   therapistUserId: session.therapistUserId,
///   clientName: userFirstName + ' ' + userLastName,
///   sessionDate: formattedDate, // e.g., "Dec 15, 2025"
///   sessionTime: session.startTime, // e.g., "10:00 AM"
///   cancellationReason: reasonController.text, // Optional
///   context: context,
/// );
/// ```
/// 
/// 2. IN THERAPIST DASHBOARD CANCELLATION FLOW (therapist_dashboard_screen.dart):
/// 
/// After successful cancellation API call:
/// ```dart
/// // After BookingService.cancelBooking() succeeds
/// await BookingStatusNotificationIntegration.onTherapistCancelBooking(
///   clientUserId: schedule['client_user_id'],
///   therapistName: therapistFirstName + ' ' + therapistLastName,
///   sessionDate: schedule['date'], // e.g., "2025-12-15"
///   sessionTime: schedule['start_time'], // e.g., "10:00 AM"
///   cancellationReason: reasonController.text, // Optional
///   context: context,
/// );
/// ```
/// 
/// 3. IN BOOKING SERVICE (booking_service.dart):
/// 
/// Option A: Add to cancelBooking method directly:
/// ```dart
/// Future<void> cancelBooking({
///   required String sessionId,
///   required String clientUserId,
///   String? therapistUserId,
///   String? reason,
///   bool isCancelledByTherapist = false,
///   String? otherPartyName,
///   String? sessionDate,
///   String? sessionTime,
/// }) async {
///   // ... existing cancellation logic ...
///   
///   if (response.statusCode == 200) {
///     // Send notification
///     if (isCancelledByTherapist && therapistUserId != null) {
///       await BookingStatusNotificationIntegration.onTherapistCancelBooking(
///         clientUserId: clientUserId,
///         therapistName: otherPartyName ?? 'Your therapist',
///         sessionDate: sessionDate ?? 'your scheduled date',
///         sessionTime: sessionTime ?? 'your scheduled time',
///         cancellationReason: reason,
///       );
///     } else if (!isCancelledByTherapist && therapistUserId != null) {
///       await BookingStatusNotificationIntegration.onClientCancelBooking(
///         therapistUserId: therapistUserId,
///         clientName: otherPartyName ?? 'A client',
///         sessionDate: sessionDate ?? 'the scheduled date',
///         sessionTime: sessionTime ?? 'the scheduled time',
///         cancellationReason: reason,
///       );
///     }
///     
///     // ... rest of existing logic ...
///   }
/// }
/// ```
/// 
/// Option B: Trigger from UI layer after cancellation succeeds
/// 
/// 4. FOR SESSION STATUS UPDATES:
/// 
/// When marking session as completed:
/// ```dart
/// await BookingStatusNotificationIntegration.onSessionStatusChange(
///   userId: clientUserId,
///   sessionDate: 'Dec 15, 2025',
///   sessionTime: '10:00 AM',
///   status: 'completed',
///   isTherapist: false,
/// );
/// ```
/// 
/// ============================================================================
/// NOTIFICATION BEHAVIORS
/// ============================================================================
/// 
/// CLIENT CANCELS BOOKING:
/// - Recipient: Therapist
/// - Title: "❌ Session Cancelled"
/// - Message: "[ClientName] cancelled the session on [date] at [time]."
/// - Includes reason if provided
/// 
/// THERAPIST CANCELS BOOKING:
/// - Recipient: Client
/// - Title: "❌ Session Cancelled by Therapist"
/// - Message: "Dr. [TherapistName] cancelled your session on [date] at [time]."
/// - Includes reason if provided
/// 
/// SESSION RESCHEDULED:
/// - Title: "📅 Session Rescheduled"
/// - Message: Shows old and new date/time
/// 
/// SESSION STATUS CHANGES:
/// - Completed: "✅ Session Completed" (asks client to rate)
/// - No-Show: "⚠️ Session No-Show"
/// - In Progress: "🔵 Session In Progress"
/// 
/// ============================================================================
/// EXAMPLE: Full Client Cancellation Flow
/// ============================================================================

class ClientCancellationExample extends StatelessWidget {
  final String sessionId;
  final String clientUserId;
  final String therapistUserId;
  final String therapistName;
  final String sessionDate;
  final String sessionTime;

  const ClientCancellationExample({
    super.key,
    required this.sessionId,
    required this.clientUserId,
    required this.therapistUserId,
    required this.therapistName,
    required this.sessionDate,
    required this.sessionTime,
  });

  Future<void> _cancelBooking(BuildContext context, String? reason) async {
    try {
      // 1. Call booking service to cancel
      // await BookingService().cancelBooking(
      //   sessionId: sessionId,
      //   clientUserId: clientUserId,
      //   therapistUserId: therapistUserId,
      //   reason: reason,
      // );

      // 2. Send notification to therapist
      await BookingStatusNotificationIntegration.onClientCancelBooking(
        therapistUserId: therapistUserId,
        clientName: 'John Doe', // Get from user profile
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        cancellationReason: reason,
        context: context,
      );

      // 3. Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Show reason dialog
        final reason = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: TextField(
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation (optional)',
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, ''),
                child: const Text('Cancel Booking'),
              ),
            ],
          ),
        );

        if (reason != null) {
          await _cancelBooking(context, reason);
        }
      },
      child: const Text('Cancel Booking'),
    );
  }
}
