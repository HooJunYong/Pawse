import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Authentication service for login and signup operations
class AuthService {
  /// Login with email and password
  /// Returns the response from the API
  static Future<http.Response> login(String email, String password) async {
    return await ApiService.post('/login', {
      'email': email,
      'password': password,
    });
  }

  /// Sign up a new user
  /// Returns the response from the API
  static Future<http.Response> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await ApiService.post('/signup', {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
  }

  /// Get login history for a user
  static Future<http.Response> getLoginHistory(String userId) async {
    return await ApiService.get('/login/history/$userId');
  }
}
