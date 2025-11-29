/// Personality model representing a personality in the system
class Personality {
  final String personalityId;
  final String? userId;
  final String personalityName;
  final String description;
  final String promptModifier;
  final DateTime createdAt;
  final bool isActive;

  Personality({
    required this.personalityId,
    this.userId,
    required this.personalityName,
    required this.description,
    required this.promptModifier,
    required this.createdAt,
    required this.isActive,
  });

  /// Create a Personality from JSON
  factory Personality.fromJson(Map<String, dynamic> json) {
    return Personality(
      personalityId: json['personality_id'] ?? '',
      userId: json['user_id'],
      personalityName: json['personality_name'] ?? '',
      description: json['description'] ?? '',
      promptModifier: json['prompt_modifier'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  /// Convert Personality to JSON
  Map<String, dynamic> toJson() {
    return {
      'personality_id': personalityId,
      'user_id': userId,
      'personality_name': personalityName,
      'description': description,
      'prompt_modifier': promptModifier,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

/// Request model for creating a personality
class PersonalityCreate {
  final String personalityName;
  final String? userId;
  final String? description;
  final String promptModifier;
  final bool isActive;

  PersonalityCreate({
    required this.personalityName,
    this.userId,
    this.description,
    required this.promptModifier,
    this.isActive = true,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'personality_name': personalityName,
      'user_id': userId,
      'description': description ?? '',
      'prompt_modifier': promptModifier,
      'is_active': isActive,
    };
  }
}
