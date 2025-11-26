/// Model for chat messages
class ChatMessage {
  final String role;
  final String messageText;
  final DateTime timestamp;
  final String? emotion;
  final bool isLoading;

  ChatMessage({
    required this.role,
    required this.messageText,
    required this.timestamp,
    this.emotion,
    this.isLoading = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? '',
      messageText: json['message_text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      emotion: json['emotion'],
      isLoading: false, // Messages from JSON are never loading
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'message_text': messageText,
      'timestamp': timestamp.toIso8601String(),
      'emotion': emotion,
    };
  }
}