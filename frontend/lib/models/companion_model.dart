/// AI Companion model representing a companion in the system
class Companion {
  final String companionId;
  final String? userId;
  final String personalityId;
  final String companionName;
  final String description;
  final String image;
  final DateTime createdAt;
  final bool isDefault;
  final bool isActive;
  final String? voiceTone;

  Companion({
    required this.companionId,
    this.userId,
    required this.personalityId,
    required this.companionName,
    required this.description,
    required this.image,
    required this.createdAt,
    required this.isDefault,
    required this.isActive,
    this.voiceTone,
  });

  /// Create a Companion from JSON
  factory Companion.fromJson(Map<String, dynamic> json) {
    return Companion(
      companionId: json['companion_id'] ?? '',
      userId: json['user_id'],
      personalityId: json['personality_id'] ?? '',
      companionName: json['companion_name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
      voiceTone: json['voice_tone'],
    );
  }

  /// Convert Companion to JSON
  Map<String, dynamic> toJson() {
    return {
      'companion_id': companionId,
      'user_id': userId,
      'personality_id': personalityId,
      'companion_name': companionName,
      'description': description,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'is_default': isDefault,
      'is_active': isActive,
      'voice_tone': voiceTone,
    };
  }
}

/// Request model for creating a companion
class CompanionCreate {
  final String personalityId;
  final String? userId;
  final String companionName;
  final String description;
  final String image;
  final bool isDefault;
  final bool isActive;
  final String? voiceTone;

  CompanionCreate({
    required this.personalityId,
    this.userId,
    required this.companionName,
    required this.description,
    required this.image,
    this.isDefault = false,
    this.isActive = true,
    this.voiceTone,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'personality_id': personalityId,
      'user_id': userId,
      'companion_name': companionName,
      'description': description,
      'image': image,
      'is_default': isDefault,
      'is_active': isActive,
      'voice_tone': voiceTone,
    };
  }
}
