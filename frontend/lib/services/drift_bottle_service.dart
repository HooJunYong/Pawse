import 'dart:convert';
import 'api_service.dart';

/// Service for handling drift bottle operations
class DriftBottleService {
  /// Throw a new bottle into the ocean
  /// Returns the created bottle data or null on failure
  static Future<Map<String, dynamic>?> throwBottle({
    required String userId,
    required String message,
  }) async {
    try {
      final response = await ApiService.post('/api/drift-bottles/throw', {
        'user_id': userId,
        'message': message,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to throw bottle: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error throwing bottle: $e');
    }
  }

  /// Pick up a random bottle from the ocean
  /// Returns the bottle data or null if no bottles available
  static Future<Map<String, dynamic>?> pickupBottle({
    required String userId,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/drift-bottles/pickup?user_id=$userId',
        {},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // No bottles available
        return null;
      } else {
        throw Exception('Failed to pickup bottle: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        return null;
      }
      throw Exception('Error picking up bottle: $e');
    }
  }

  /// Pass a bottle back into the ocean without replying
  /// Returns true on success
  static Future<bool> passBottle({
    required String userId,
    required String bottleId,
  }) async {
    try {
      final response = await ApiService.post('/api/drift-bottles/pass', {
        'user_id': userId,
        'bottle_id': bottleId,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to pass bottle: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error passing bottle: $e');
    }
  }

  /// Reply to a bottle
  /// Returns the reply data or null on failure
  static Future<Map<String, dynamic>?> replyToBottle({
    required String userId,
    required String bottleId,
    required String replyContent,
  }) async {
    try {
      final response = await ApiService.post('/api/drift-bottles/reply', {
        'user_id': userId,
        'bottle_id': bottleId,
        'reply_content': replyContent,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to reply to bottle: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error replying to bottle: $e');
    }
  }

  /// Get thrown bottle history for a user
  static Future<List<Map<String, dynamic>>> getThrownHistory({
    required String userId,
  }) async {
    try {
      final response = await ApiService.get('/api/drift-bottles/thrown/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get thrown history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting thrown history: $e');
    }
  }

  /// Get pickup history for a user
  static Future<List<Map<String, dynamic>>> getPickupHistory({
    required String userId,
  }) async {
    try {
      final response = await ApiService.get('/api/drift-bottles/pickup-history/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get pickup history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting pickup history: $e');
    }
  }

  /// Get bottle details by ID
  static Future<Map<String, dynamic>?> getBottleDetail({
    required String bottleId,
  }) async {
    try {
      final response = await ApiService.get('/api/drift-bottles/detail/$bottleId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get bottle detail: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting bottle detail: $e');
    }
  }

  /// End a bottle conversation
  static Future<bool> endBottle({
    required String userId,
    required String bottleId,
  }) async {
    try {
      final response = await ApiService.post('/api/drift-bottles/end', {
        'user_id': userId,
        'bottle_id': bottleId,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to end bottle: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error ending bottle: $e');
    }
  }
}
