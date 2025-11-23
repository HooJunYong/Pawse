class JournalPrompt {
  final String prompt;
  final String promptType;

  JournalPrompt({
    required this.prompt,
    required this.promptType,
  });

  factory JournalPrompt.fromJson(Map<String, dynamic> json) {
    return JournalPrompt(
      prompt: json['prompt'] as String,
      promptType: json['prompt_type'] as String,
    );
  }
}

class JournalEntry {
  final String entryId;
  final String userId;
  final String title;
  final String content;
  final String promptType;
  final List<String> emotionalTags;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.entryId,
    required this.userId,
    required this.title,
    required this.content,
    required this.promptType,
    required this.emotionalTags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      entryId: json['entry_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      promptType: json['prompt_type'] as String,
      emotionalTags: List<String>.from(json['emotional_tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_id': entryId,
      'user_id': userId,
      'title': title,
      'content': content,
      'prompt_type': promptType,
      'emotional_tags': emotionalTags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CreateJournalEntry {
  final String title;
  final String content;
  final String promptType;
  final List<String> emotionalTags;

  CreateJournalEntry({
    required this.title,
    required this.content,
    required this.promptType,
    this.emotionalTags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'prompt_type': promptType,
      'emotional_tags': emotionalTags,
    };
  }
}
