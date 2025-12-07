import 'package:flutter/material.dart';

/// Example integration for Therapist Application Notifications
/// 
/// This shows how to handle notification taps and navigate users appropriately

class TherapistApplicationNotificationIntegration {
  
  /// Handle notification tap and navigate to appropriate screen
  /// 
  /// Call this from your notification tap handler or deep link handler
  static Future<void> handleNotificationTap({
    required BuildContext context,
    required String payload,
    required String userId,
  }) async {
    try {
      // Parse payload: "approved:userId" or "rejected:userId:reason"
      final parts = payload.split(':');
      
      if (parts.isEmpty) return;
      
      final status = parts[0]; // "approved" or "rejected"
      
      if (status == 'approved') {
        // Navigate to therapist profile setup page
        // TODO: Replace with your actual therapist setup screen
        Navigator.pushNamed(
          context,
          '/therapist/setup', // Your route name
          arguments: {'userId': userId},
        );
        
        // Or use Navigator.push if not using named routes:
        /*
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TherapistProfileSetupScreen(userId: userId),
          ),
        );
        */
        
      } else if (status == 'rejected') {
        // Extract rejection reason from payload
        final rejectionReason = parts.length > 2 ? parts.sublist(2).join(':') : '';
        
        // Navigate to rejection details screen
        // TODO: Replace with your actual rejection screen
        Navigator.pushNamed(
          context,
          '/therapist/rejection', // Your route name
          arguments: {
            'userId': userId,
            'reason': rejectionReason,
          },
        );
        
        // Or use Navigator.push:
        /*
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TherapistRejectionScreen(
              userId: userId,
              rejectionReason: rejectionReason,
            ),
          ),
        );
        */
      }
    } catch (e) {
      print('Error handling application notification tap: $e');
    }
  }
}

/// ============================================================================
/// INTEGRATION STEPS
/// ============================================================================
/// 
/// 1. ADMIN APPROVAL/REJECTION (Already integrated in admin_therapist_management.dart):
/// ```dart
/// // When admin approves
/// await TherapistApplicationNotificationService.showApprovedNotification(
///   userId: userId,
///   firstName: firstName,
///   lastName: lastName,
/// );
/// 
/// // When admin rejects
/// await TherapistApplicationNotificationService.showRejectedNotification(
///   userId: userId,
///   firstName: firstName,
///   lastName: lastName,
///   rejectionReason: reason,
/// );
/// ```
/// 
/// 2. HANDLE NOTIFICATION TAP (Update the service's _onNotificationTapped):
/// 
/// In therapist_application_notification_service.dart, update:
/// ```dart
/// static void _onNotificationTapped(NotificationResponse response) {
///   // Get navigation key from your app
///   final context = MyApp.navigatorKey.currentContext;
///   if (context != null && response.payload != null) {
///     TherapistApplicationNotificationIntegration.handleNotificationTap(
///       context: context,
///       payload: response.payload!,
///       userId: extractUserIdFromPayload(response.payload!),
///     );
///   }
/// }
/// ```
/// 
/// 3. ADD GLOBAL NAVIGATOR KEY to your MyApp widget:
/// ```dart
/// class MyApp extends StatelessWidget {
///   static final navigatorKey = GlobalKey<NavigatorState>();
///   
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       navigatorKey: navigatorKey,
///       // ... rest of your app
///     );
///   }
/// }
/// ```
/// 
/// 4. CREATE THERAPIST SETUP SCREEN (if not exists):
/// - Screen where approved therapists can set up their profile
/// - Add availability, specializations, pricing, etc.
/// - Save therapist-specific data
/// 
/// 5. CREATE REJECTION DETAILS SCREEN (if not exists):
/// - Screen showing rejection reason
/// - Option to edit and resubmit application
/// - Contact support button
/// 
/// ============================================================================
/// NOTIFICATION MESSAGES
/// ============================================================================
/// 
/// APPROVED:
/// Title: "🎉 Application Approved!"
/// Body: "Congratulations [Name]! Tap to set up your therapist profile."
/// Action: Navigate to therapist profile setup
/// 
/// REJECTED:
/// Title: "Application Update"
/// Body: "Your application has been reviewed. Tap to see details."
/// Action: Navigate to rejection reason screen
/// 
/// ============================================================================
/// EXAMPLE SCREENS TO CREATE
/// ============================================================================

/// Example: Therapist Profile Setup Screen (create this if you don't have it)
class TherapistProfileSetupScreen extends StatefulWidget {
  final String userId;
  
  const TherapistProfileSetupScreen({super.key, required this.userId});
  
  @override
  State<TherapistProfileSetupScreen> createState() => _TherapistProfileSetupScreenState();
}

class _TherapistProfileSetupScreenState extends State<TherapistProfileSetupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Therapist Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Congratulations message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.celebration, size: 48, color: Colors.green),
                  SizedBox(height: 8),
                  Text(
                    '🎉 Congratulations!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your therapist application has been approved! '
                    'Complete your profile setup to start helping clients.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Setup form fields
            const Text(
              'Complete Your Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Add your form fields here:
            // - Specializations
            // - Years of experience
            // - Session pricing
            // - Available time slots
            // - Bio/Description
            // - Certifications
            
            const Placeholder(fallbackHeight: 300),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Save therapist profile
                  // Navigate to therapist dashboard
                },
                child: const Text('Complete Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Rejection Details Screen (create this if you don't have it)
class TherapistRejectionScreen extends StatelessWidget {
  final String userId;
  final String rejectionReason;
  
  const TherapistRejectionScreen({
    super.key,
    required this.userId,
    required this.rejectionReason,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.orange),
                  SizedBox(height: 8),
                  Text(
                    'Application Not Approved',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thank you for your interest. Unfortunately, your application '
                    'did not meet all requirements at this time.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Rejection reason
            const Text(
              'Reason for Rejection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                rejectionReason,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            const Text(
              'What\'s Next?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to edit/resubmit application
                  Navigator.pushNamed(context, '/therapist/reapply');
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit & Resubmit Application'),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Contact support
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Contact Support'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
