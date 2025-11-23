/// Chat history model representing a chat session with its last message
class ChatHistoryItem {
  final String sessionId;
  final DateTime date;
  final String lastMessage;
  final bool isActive;

  ChatHistoryItem({
    required this.sessionId,
    required this.date,
    required this.lastMessage,
    required this.isActive,
  });

  /// Create a ChatHistoryItem from JSON
  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      sessionId: json['session_id'] ?? '',
      date: DateTime.parse(json['date']),
      lastMessage: json['last_message'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }

  /// Convert ChatHistoryItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'date': date.toIso8601String(),
      'last_message': lastMessage,
      'is_active': isActive,
    };
  }

  /// Format date as dd/MM/yyyy
  String getFormattedDate() {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
