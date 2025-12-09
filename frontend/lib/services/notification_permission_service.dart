import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationPermissionService {
  /// Request notification permissions with user-friendly dialogs
  static Future<bool> requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      // Check Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 33) { // Android 13+
        final status = await Permission.notification.status;
        
        if (status.isDenied) {
          // Show explanation dialog
          final shouldRequest = await _showPermissionDialog(context);
          if (!shouldRequest) return false;
          
          final result = await Permission.notification.request();
          
          if (result.isPermanentlyDenied) {
            await _showSettingsDialog(context);
            return false;
          }
          
          return result.isGranted;
        }
        
        return status.isGranted;
      }
    }
    
    // iOS or older Android
    return true;
  }
  
  /// Show dialog explaining why notification permission is needed
  static Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Pawse uses notifications to:\n'
          '• Send mood check-in reminders\n'
          '• Notify you about therapy sessions\n'
          '• Provide hydration and wellness reminders\n\n'
          'Would you like to enable notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Show dialog to open app settings
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Notification permission is required for reminders. '
          'Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.notification.isGranted;
      }
    }
    return true;
  }
}