class ChatMessage {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'];
    DateTime createdAt;
    if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return ChatMessage(
      messageId: json['message_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'client',
      content: json['content']?.toString() ?? '',
      createdAt: createdAt,
      isRead: json['is_read'] == true,
    );
  }

  bool isFromCurrentUser(String currentUserId) => senderId == currentUserId;
}
