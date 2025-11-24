/// AI Companion model representing a companion in the system
class Companion {
  final String companionId;
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
