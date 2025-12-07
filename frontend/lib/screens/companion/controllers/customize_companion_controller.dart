import 'package:flutter/material.dart';
import '../../../models/companion_model.dart';
import '../../../models/personality_model.dart';
import '../../../services/companion_service.dart';
import '../../../services/reward_service.dart';

/// Controller for customize companion screen business logic
class CustomizeCompanionController extends ChangeNotifier {
  final String? userId;

  // --- State Variables ---
  List<Personality> _personalities = [];
  Personality? _selectedPersonality;
  bool _isCustomPersonality = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Companion? _createdCompanion;

  // --- Cat Images (loaded from backend) ---
  List<String> catImages = [
    'assets/images/americonsh1.png', // Default fallback
  ];
  int _currentCatIndex = 0;

  // --- Text Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController customPersonalityNameController = TextEditingController();
  final TextEditingController customDescriptionController = TextEditingController();

  // --- Voice Tone ---
  final List<String> voiceTones = ['Gentle', 'Energetic', 'Serious'];
  String? _selectedVoiceTone;

  // --- Getters ---
  List<Personality> get personalities => _personalities;
  Personality? get selectedPersonality => _selectedPersonality;
  bool get isCustomPersonality => _isCustomPersonality;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Companion? get createdCompanion => _createdCompanion;
  int get currentCatIndex => _currentCatIndex;
  String? get selectedVoiceTone => _selectedVoiceTone;

  /// Get current selected image (only filename, not full path)
  String get currentImageName {
    final fullPath = catImages[_currentCatIndex];
    return fullPath.split('/').last; // Extract only filename like "whitecat1.png"
  }

  CustomizeCompanionController({this.userId}) {
    _loadPersonalities();
    _loadAvailableSkins();
  }

  /// Load personalities from database
  Future<void> _loadPersonalities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (userId != null) {
        // Get system + user personalities
        _personalities = await CompanionService.getAvailablePersonalities(userId!);
      } else {
        // Get only system personalities
        _personalities = await CompanionService.getSystemPersonalities();
      }

      // Set default selected personality (first one if available)
      if (_personalities.isNotEmpty) {
        _selectedPersonality = _personalities.first;
      }
    } catch (e) {
      _errorMessage = 'Failed to load personalities: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load available companion skins from backend
  Future<void> _loadAvailableSkins() async {
    try {
      if (userId != null) {
        final response = await RewardService.getAvailableSkins(userId!);
        
        // Always start with the default American Shorthair skin
        catImages = ['assets/images/americonsh1.png'];
        
        if (response != null && response['skins'] != null) {
          final skins = response['skins'] as List;
          
          if (skins.isNotEmpty) {
            // Add redeemed skins (skip if it's the default American Shorthair)
            for (var skin in skins) {
              final imagePath = 'assets/images/${skin['image_path']}';
              if (imagePath != 'assets/images/americonsh1.png') {
                catImages.add(imagePath);
              }
            }
          }
        }

        // Ensure at least 3 images (fill with default if needed)
        while (catImages.length < 3) {
          catImages.add('assets/images/americonsh1.png');
        }
        
        notifyListeners();
      }
    } catch (e) {
      // If error, use default skins
      catImages = [
        'assets/images/americonsh1.png',
        'assets/images/americonsh1.png',
        'assets/images/americonsh1.png',
      ];
      notifyListeners();
    }
  }

  /// Reload personalities
  Future<void> reloadPersonalities() async {
    await _loadPersonalities();
  }

  /// Update current cat index
  void updateCatIndex(int index) {
    _currentCatIndex = index;
    notifyListeners();
  }

  /// Select a personality
  void selectPersonality(Personality? personality) {
    _selectedPersonality = personality;
    _isCustomPersonality = false;
    notifyListeners();
  }

  /// Select custom personality option
  void selectCustomPersonality() {
    _selectedPersonality = null;
    _isCustomPersonality = true;
    notifyListeners();
  }

  /// Update selected voice tone
  void updateVoiceTone(String? voiceTone) {
    _selectedVoiceTone = voiceTone;
    notifyListeners();
  }

  /// Validate form inputs
  String? validateInputs() {
    if (nameController.text.trim().isEmpty) {
      return 'Please enter a companion name';
    }

    if (!_isCustomPersonality && _selectedPersonality == null) {
      return 'Please select a personality';
    }

    if (_isCustomPersonality) {
      if (customPersonalityNameController.text.trim().isEmpty) {
        return 'Please enter a personality name';
      }
      if (customDescriptionController.text.trim().isEmpty) {
        return 'Please enter a personality description';
      }
    }

    return null; // No validation errors
  }

  /// Save companion (create new companion)
  Future<bool> saveCompanion() async {
    // Validate inputs
    final validationError = validateInputs();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String personalityId;

      // If custom personality, create it first
      if (_isCustomPersonality) {
        final personalityData = PersonalityCreate(
          personalityName: customPersonalityNameController.text.trim(),
          userId: userId,
          description: null, // Set as null as per requirement
          promptModifier: customDescriptionController.text.trim(),
          isActive: true,
        );

        final newPersonality = await CompanionService.createPersonality(personalityData);
        personalityId = newPersonality.personalityId;
      } else {
        personalityId = _selectedPersonality!.personalityId;
      }

      // Create companion
      final companionData = CompanionCreate(
        personalityId: personalityId,
        userId: userId,
        companionName: nameController.text.trim(),
        description: 'Custom companion created by user',
        image: currentImageName,
        isDefault: false,
        isActive: true,
        voiceTone: _selectedVoiceTone,
      );

      _createdCompanion = await CompanionService.createCompanion(companionData);

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save companion: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset form
  void resetForm() {
    nameController.clear();
    customPersonalityNameController.clear();
    customDescriptionController.clear();
    _currentCatIndex = 1;
    _selectedVoiceTone = null;
    _isCustomPersonality = false;
    if (_personalities.isNotEmpty) {
      _selectedPersonality = _personalities.first;
    }
    _createdCompanion = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    customPersonalityNameController.dispose();
    customDescriptionController.dispose();
    super.dispose();
  }
}
