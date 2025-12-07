import 'dart:convert';
import 'api_service.dart';

/// Service for handling reward operations
class RewardService {
  /// Get all available rewards for a user
  static Future<Map<String, dynamic>?> getAvailableRewards(String userId) async {
    try {
      final response = await ApiService.get('/api/rewards/available/$userId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get available rewards: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting available rewards: $e');
    }
  }

  /// Get user's inventory (redeemed rewards)
  static Future<Map<String, dynamic>?> getUserInventory(String userId) async {
    try {
      final response = await ApiService.get('/api/rewards/inventory/$userId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user inventory: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user inventory: $e');
    }
  }

  /// Get user's current points from profile
  static Future<int> getUserPoints(String userId) async {
    try {
      final response = await ApiService.get('/profile/details/$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['current_points'] ?? 0;
      } else {
        throw Exception('Failed to get user points: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting user points: $e');
    }
  }

  /// Redeem a reward
  static Future<Map<String, dynamic>?> redeemReward({
    required String userId,
    required String rewardId,
  }) async {
    try {
      final response = await ApiService.post('/api/rewards/redeem', {
        'user_id': userId,
        'reward_id': rewardId,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to redeem reward');
      }
    } catch (e) {
      throw Exception('Error redeeming reward: $e');
    }
  }

  /// Get all active rewards (admin view)
  static Future<Map<String, dynamic>?> getAllRewards() async {
    try {
      final response = await ApiService.get('/api/rewards/all');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get all rewards: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting all rewards: $e');
    }
  }

  /// Get available companion skins user owns
  static Future<Map<String, dynamic>?> getAvailableSkins(String userId) async {
    try {
      final response = await ApiService.get('/api/rewards/skins/$userId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get available skins: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting available skins: $e');
    }
  }
}
