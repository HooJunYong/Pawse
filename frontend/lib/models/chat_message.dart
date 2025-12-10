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
      // Parse the datetime string - backend sends Malaysia time (UTC+8)
      // If UTC (Z), add 8 hours. If offset (+08:00), strip it.
      String isoString = createdRaw;
      if (isoString.endsWith('Z')) {
        final utc = DateTime.parse(isoString);
        final myTime = utc.add(const Duration(hours: 8));
        createdAt = DateTime(myTime.year, myTime.month, myTime.day, myTime.hour, myTime.minute, myTime.second);
      } else {
        final tzMatch = RegExp(r'([+-]\d{2}:?\d{2})$').firstMatch(isoString);
        if (tzMatch != null) {
          final core = isoString.substring(0, tzMatch.start);
          final parsed = DateTime.parse(core);
          createdAt = DateTime(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second, parsed.millisecond, parsed.microsecond);
        } else {
          final parsed = DateTime.parse(isoString);
          final utc = DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second, parsed.millisecond, parsed.microsecond);
          final myTime = utc.add(const Duration(hours: 8));
          createdAt = DateTime(myTime.year, myTime.month, myTime.day, myTime.hour, myTime.minute, myTime.second, myTime.millisecond, myTime.microsecond);
        }
      }
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
