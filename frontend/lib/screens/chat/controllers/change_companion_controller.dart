import 'package:flutter/foundation.dart';
import '../../../models/companion_model.dart';
import '../../../services/companion_service.dart';

class ChangeCompanionController extends ChangeNotifier {
  List<Companion> _companions = [];
  Companion? _currentCompanion;
  Companion? _selectedCompanion;
  bool _isLoading = true;
  String? _errorMessage;

  List<Companion> get companions => _companions;
  Companion? get currentCompanion => _currentCompanion;
  Companion? get selectedCompanion => _selectedCompanion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load available companions and current companion data
  Future<void> loadCompanions(String userId, String currentCompanionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load available companions
      final companions = await CompanionService.getAvailableCompanions(
        userId,
        activeOnly: true,
      );

      // Load current companion data
      final currentCompanion = await CompanionService.getCompanionById(
        currentCompanionId,
      );

      _companions = companions;
      _currentCompanion = currentCompanion;
      _selectedCompanion = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load companions: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a companion
  void selectCompanion(Companion companion) {
    _selectedCompanion = companion;
    notifyListeners();
  }

  /// Get the selected companion ID (for navigation return value)
  String? getSelectedCompanionId() {
    return _selectedCompanion?.companionId;
  }
}
