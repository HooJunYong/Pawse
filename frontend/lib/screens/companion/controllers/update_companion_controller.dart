import 'package:flutter/material.dart';
import '../../../models/companion_model.dart';
import '../../../models/personality_model.dart';
import '../../../services/companion_service.dart';
import '../../../services/reward_service.dart';

class UpdateCompanionController extends ChangeNotifier {
  final String? userId;
  final Companion companion;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController customPersonalityNameController =
      TextEditingController();
  final TextEditingController customDescriptionController =
      TextEditingController();

  // Cat images
  List<String> catImages = [];

  // State
  int currentCatIndex = 0;
  List<Personality> personalities = [];
  Personality? selectedPersonality;
  bool isCustomPersonality = false;
  String? selectedVoiceTone;
  String? selectedGender;

  final List<String> voiceTones = [
    'Gentle',
    'Energetic',
    'Serious',
    'Playful',
  ];
  final List<String> genders = ['Female', 'Male'];

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  UpdateCompanionController({required this.userId, required this.companion}) {
    _initialize();
  }

  Future<void> _initialize() async {
    isLoading = true;
    notifyListeners();

    // Pre-fill form with existing companion data
    nameController.text = companion.companionName;
    
    // Handle voice tone (convert to Title Case to match list)
    if (companion.voiceTone != null && companion.voiceTone!.isNotEmpty) {
      final tone = companion.voiceTone!;
      // Try to find case-insensitive match in the list
      try {
        selectedVoiceTone = voiceTones.firstWhere(
          (t) => t.toLowerCase() == tone.toLowerCase(),
        );
      } catch (e) {
        // If not found in list, set to null to avoid crash
        selectedVoiceTone = null;
      }
    }

    // Handle gender (convert to Title Case to match list)
    if (companion.gender != null && companion.gender!.isNotEmpty) {
      final gender = companion.gender!;
      try {
        selectedGender = genders.firstWhere(
          (g) => g.toLowerCase() == gender.toLowerCase(),
        );
      } catch (e) {
        selectedGender = null;
      }
    }

    // Load skins and set currentCatIndex
    await _loadAvailableSkins();

    // Load personalities
    await _loadPersonalities();

    // Set the current personality
    if (personalities.isNotEmpty) {
      try {
        selectedPersonality = personalities.firstWhere(
          (p) => p.personalityId == companion.personalityId,
        );
      } catch (e) {
        // Personality not found, user might need to select a new one
        debugPrint('Current personality not found in list');
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAvailableSkins() async {
  try {
    // Start with default
    List<String> loadedImages = ['assets/images/americonsh1.png'];
    
    if (userId != null) {
      final response = await RewardService.getAvailableSkins(userId!);
      
      if (response != null && response['skins'] != null) {
        final skins = response['skins'] as List;
        for (var skin in skins) {
           final imagePath = 'assets/images/${skin['image_path']}';
           if (!loadedImages.contains(imagePath)) {
             loadedImages.add(imagePath);
           }
        }
      }
    }

    // Ensure current companion image is in the list
    final currentImageFullPath = 'assets/images/${companion.image}';
    if (!loadedImages.contains(currentImageFullPath)) {
      loadedImages.add(currentImageFullPath);
    }

    catImages = loadedImages;  // Move this BEFORE indexOf

    // Find index of current companion image
    currentCatIndex = catImages.indexOf(currentImageFullPath);
    
    // If not found (indexOf returns -1), default to 0
    if (currentCatIndex == -1) {
      currentCatIndex = 0;
    }
    
  } catch (e) {
     debugPrint('Error in _loadAvailableSkins: $e');
     // Fallback if loading fails
     catImages = ['assets/images/americonsh1.png'];
     
     // Try to add current image if possible
     final currentImageFullPath = 'assets/images/${companion.image}';
     if (currentImageFullPath != 'assets/images/americonsh1.png') {
       catImages.add(currentImageFullPath);
       currentCatIndex = 1;
     } else {
       currentCatIndex = 0;
     }
  }
}

  Future<void> _loadPersonalities() async {
    isLoading = true;
    notifyListeners();

    try {
      if (userId != null) {
        personalities = await CompanionService.getAvailablePersonalities(
          userId!,
        );
      } else {
        personalities = await CompanionService.getSystemPersonalities();
      }
    } catch (e) {
      errorMessage = 'Failed to load personalities: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateCatIndex(int index) {
    currentCatIndex = index;
    notifyListeners();
  }

  void selectPersonality(Personality? personality) {
    if (personality == null) return;
    selectedPersonality = personality;
    isCustomPersonality = false;
    notifyListeners();
  }

  void selectCustomPersonality() {
    isCustomPersonality = true;
    selectedPersonality = null;
    notifyListeners();
  }

  void updateVoiceTone(String? tone) {
    selectedVoiceTone = tone;
    notifyListeners();
  }

  void updateGender(String? gender) {
    selectedGender = gender;
    notifyListeners();
  }

  Future<bool> updateCompanion() async {
    // Validation
    if (nameController.text.trim().isEmpty) {
      errorMessage = 'Please enter a companion name';
      notifyListeners();
      return false;
    }

    String? personalityId;

    if (isCustomPersonality) {
      // Create custom personality
      if (customPersonalityNameController.text.trim().isEmpty ||
          customDescriptionController.text.trim().isEmpty) {
        errorMessage = 'Please fill in all custom personality fields';
        notifyListeners();
        return false;
      }

      try {
        final newPersonality = await CompanionService.createPersonality(
          PersonalityCreate(
            userId: userId,
            personalityName: customPersonalityNameController.text.trim(),
            description: customDescriptionController.text.trim(),
            promptModifier: customDescriptionController.text.trim(),
          ),
        );
        personalityId = newPersonality.personalityId;
      } catch (e) {
        errorMessage = 'Failed to create custom personality: $e';
        notifyListeners();
        return false;
      }
    } else {
      if (selectedPersonality == null) {
        errorMessage = 'Please select a personality';
        notifyListeners();
        return false;
      }
      personalityId = selectedPersonality!.personalityId;
    }

    // Update companion
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final fullImagePath = catImages[currentCatIndex];
      final imageName = fullImagePath.replaceAll('assets/images/', '');

      final updateData = {
        'companion_name': nameController.text.trim(),
        'personality_id': personalityId,
        'description': isCustomPersonality
            ? customDescriptionController.text.trim()
            : selectedPersonality?.description ?? '',
        'image': imageName,
        'voice_tone': selectedVoiceTone?.toLowerCase(),
        'gender': selectedGender?.toLowerCase(),
        'is_active': true,
      };

      await CompanionService.updateCompanion(
        companion.companionId,
        updateData,
      );

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update companion: $e';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    customPersonalityNameController.dispose();
    customDescriptionController.dispose();
    super.dispose();
  }
}
