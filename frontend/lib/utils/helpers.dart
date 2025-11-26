import 'package:flutter/material.dart';

/// Helper functions used throughout the app
class Helpers {
  // Prevent instantiation
  Helpers._();

  /// Show a success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show an error snackbar
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Close the loading dialog
  static void closeLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show an error dialog
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Color(0xFF422006),
          ),
        ),
        backgroundColor: const Color(0xFFF7F4F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate initials from full name
  static String generateInitials(String fullName) {
    if (fullName.isEmpty) return '';
    
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Format date string (e.g., "2024-01-01T12:00:00" -> "Jan 1, 2024")
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class MoodConstants {
  // Define the asset paths
  static const String assetVeryHappy = 'assets/images/mood_very_happy.png';
  static const String assetHappy = 'assets/images/mood_happy.png';
  static const String assetNeutral = 'assets/images/mood_neutral.png';
  static const String assetSad = 'assets/images/mood_sad.png';
  static const String assetAwful = 'assets/images/mood_awful.png';

  // Define the Database values (The strings your DB expects)
  static const String dbVeryHappy = 'very happy';
  static const String dbHappy = 'happy';
  static const String dbNeutral = 'neutral';
  static const String dbSad = 'sad';
  static const String dbAwful = 'awful';

  // The Converter Map
  static const Map<String, String> assetToDbValue = {
    assetVeryHappy: dbVeryHappy,
    assetHappy: dbHappy,
    assetNeutral: dbNeutral,
    assetSad: dbSad,
    assetAwful: dbAwful,
  };
  
  // Reverse map to load history and show the emoji again
  static const Map<String, String> dbValueToAsset = {
    dbVeryHappy: assetVeryHappy,
    dbHappy: assetHappy,
    dbNeutral: assetNeutral,
    dbSad: assetSad,
    dbAwful: assetAwful,
  };
}
