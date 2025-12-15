import 'package:flutter/foundation.dart';
import '../../../services/reward_service.dart';

class RewardController extends ChangeNotifier {
  final String userId;

  bool _isLoading = true;
  String? _errorMessage;
  int _currentPoints = 0;
  List<Map<String, dynamic>> _availableRewards = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPoints => _currentPoints;
  List<Map<String, dynamic>> get availableRewards => _availableRewards;

  RewardController({required this.userId});

  Future<void> loadRewardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load user points
      final points = await RewardService.getUserPoints(userId);
      
      // Load available rewards
      final rewardsData = await RewardService.getAvailableRewards(userId);

      _currentPoints = points;
      _availableRewards = List<Map<String, dynamic>>.from(
        rewardsData?['available_rewards'] ?? []
      );
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load rewards: $e';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> redeemReward(String rewardId) async {
    try {
      final result = await RewardService.redeemReward(
        userId: userId,
        rewardId: rewardId,
      );
      
      if (result != null && result['success'] == true) {
        // Reload data after successful redemption
        await loadRewardData();
      }
      
      return result;
    } catch (e) {
      rethrow; // Let UI handle the error display
    }
  }

  String parseErrorMessage(String errorMsg) {
    String displayMessage = "Looks like you don't have enough points to redeem this reward.";
    
    // Check for specific error types
    if (errorMsg.contains('Insufficient points')) {
      displayMessage = "Looks like you don't have enough points to redeem this reward.";
    } else if (errorMsg.contains('already been redeemed')) {
      displayMessage = "You have already redeemed this reward.";
    } else if (errorMsg.contains('not found') || errorMsg.contains('inactive')) {
      displayMessage = "This reward is no longer available.";
    } else {
      displayMessage = "Something went wrong. Please try again later.";
    }
    
    return displayMessage;
  }
}
