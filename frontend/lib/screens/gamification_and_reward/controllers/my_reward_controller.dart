import 'package:flutter/foundation.dart';
import '../../../services/reward_service.dart';

class MyRewardController extends ChangeNotifier {
  final String userId;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _redeemedRewards = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get redeemedRewards => _redeemedRewards;

  MyRewardController({required this.userId});

  Future<void> loadInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final inventoryData = await RewardService.getUserInventory(userId);

      _redeemedRewards = List<Map<String, dynamic>>.from(
        inventoryData?['inventory'] ?? []
      );
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load inventory: $e';
      notifyListeners();
    }
  }
}
