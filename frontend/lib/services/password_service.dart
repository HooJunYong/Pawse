import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Password service for password management operations
class PasswordService {
  /// Change user password
  static Future<http.Response> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiService.put('/change-password/$userId', {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  /// Request password reset (send OTP)
  static Future<http.Response> requestPasswordReset(String email) async {
    return await ApiService.post('/forgot-password', {
      'email': email,
    });
  }

  /// Verify OTP
  static Future<http.Response> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return await ApiService.post('/verify-otp', {
      'email': email,
      'otp': otp,
    });
  }

  /// Reset password
  static Future<http.Response> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    return await ApiService.post('/reset-password', {
      'email': email,
      'new_password': newPassword,
    });
  }
}
