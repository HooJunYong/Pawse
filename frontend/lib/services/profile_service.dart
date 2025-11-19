import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Profile service for managing user profiles
class ProfileService {
  /// Get profile by user ID
  static Future<http.Response> getProfile(String userId) async {
    return await ApiService.get('/profile/$userId');
  }

  /// Get profile by email
  static Future<http.Response> getProfileByEmail(String email) async {
    return await ApiService.get('/profile/by-email?email=$email');
  }

  /// Get profile details by user ID
  static Future<http.Response> getProfileDetails(String userId) async {
    return await ApiService.get('/profile/details/$userId');
  }

  /// Update user profile
  static Future<http.Response> updateProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    Uint8List? profilePicture,
  }) async {
    return await ApiService.put('/profile/$userId', {
      'full_name': fullName,
      'phone_number': phoneNumber,
      if (profilePicture != null)
        'profile_picture': profilePicture.toString(),
    });
  }
}
