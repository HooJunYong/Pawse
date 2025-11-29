import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/companion_model.dart';
import '../models/personality_model.dart';

/// Companion service for managing AI companions and personalities
class CompanionService {
  // ==================== Companion API ====================

  /// Create a new companion
  static Future<Companion> createCompanion(CompanionCreate companionData) async {
    try {
      final response = await ApiService.post('/api/companions', companionData.toJson());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Companion.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create companion');
      }
    } catch (e) {
      throw Exception('Error creating companion: $e');
    }
  }

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

  /// Get system companions
  static Future<List<Companion>> getSystemCompanions({bool activeOnly = true}) async {
    try {
      final response = await ApiService.get('/api/companions/system?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Companion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load system companions');
      }
    } catch (e) {
      throw Exception('Error fetching system companions: $e');
    }
  }

  /// Get user's companions
  static Future<List<Companion>> getUserCompanions(String userId, {bool activeOnly = true}) async {
    try {
      final response = await ApiService.get('/api/companions/user/$userId?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Companion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user companions');
      }
    } catch (e) {
      throw Exception('Error fetching user companions: $e');
    }
  }

  /// Get available companions (system + user)
  static Future<List<Companion>> getAvailableCompanions(String userId, {bool activeOnly = true}) async {
    try {
      final response = await ApiService.get('/api/companions/available/$userId?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Companion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load available companions');
      }
    } catch (e) {
      throw Exception('Error fetching available companions: $e');
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
  static Future<Companion?> getDefaultCompanion() async {
    try {
      final response = await ApiService.get('/api/companions/default/get');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Companion.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
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

  // ==================== Personality API ====================

  /// Create a new personality
  static Future<Personality> createPersonality(PersonalityCreate personalityData) async {
    try {
      final response = await ApiService.post('/api/personalities', personalityData.toJson());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Personality.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create personality');
      }
    } catch (e) {
      throw Exception('Error creating personality: $e');
    }
  }

  /// Get all personalities
  static Future<List<Personality>> getAllPersonalities({bool activeOnly = true}) async {
    try {
      final response = await ApiService.get('/api/personalities?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Personality.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load personalities');
      }
    } catch (e) {
      throw Exception('Error fetching personalities: $e');
    }
  }

  /// Get system personalities
  static Future<List<Personality>> getSystemPersonalities({bool activeOnly = true}) async {
    try {
      final response = await ApiService.get('/api/personalities/system?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Personality.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load system personalities');
      }
    } catch (e) {
      throw Exception('Error fetching system personalities: $e');
    }
  }

  /// Get user's personalities
  static Future<List<Personality>> getUserPersonalities(String userId, {bool activeOnly = true}) async {
    try {
      final response = await ApiService.get('/api/personalities/user/$userId?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Personality.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user personalities');
      }
    } catch (e) {
      throw Exception('Error fetching user personalities: $e');
    }
  }

  /// Get available personalities (system + user)
  static Future<List<Personality>> getAvailablePersonalities(String userId, {bool activeOnly = true}) async {
    try {
      final response = await ApiService.get('/api/personalities/available/$userId?active_only=$activeOnly');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Personality.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load available personalities');
      }
    } catch (e) {
      throw Exception('Error fetching available personalities: $e');
    }
  }

  /// Get personality by ID
  static Future<Personality> getPersonalityById(String personalityId) async {
    try {
      final response = await ApiService.get('/api/personalities/$personalityId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Personality.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Personality not found');
      } else {
        throw Exception('Failed to load personality');
      }
    } catch (e) {
      throw Exception('Error fetching personality: $e');
    }
  }
}
