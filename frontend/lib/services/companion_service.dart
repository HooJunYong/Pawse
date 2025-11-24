import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/companion_model.dart';

/// Companion service for managing AI companions
class CompanionService {
  /// Get all companions
  /// Returns a list of companions
  static Future<List<Companion>> getAllCompanions({bool activeOnly = true}) async {
    try {
      final response = await ApiService.get(
          '/api/companions?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Companion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load companions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching companions: $e');
    }
  }

  /// Get companion by ID
  /// Returns a single companion
  static Future<Companion> getCompanionById(String companionId) async {
    try {
      final response = await ApiService.get('/api/companions/$companionId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Companion.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Companion not found');
      } else {
        throw Exception('Failed to load companion: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching companion: $e');
    }
  }

  /// Get the default companion
  /// Returns the companion marked as default
  static Future<Companion> getDefaultCompanion() async {
    try {
      final response = await ApiService.get('/api/companions/default/get');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Companion.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('No default companion found');
      } else {
        throw Exception(
            'Failed to load default companion: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching default companion: $e');
    }
  }

  /// Get companion's personality
  static Future<http.Response> getCompanionPersonality(
      String companionId) async {
    return await ApiService.get('/api/companions/$companionId/personality');
  }
}
