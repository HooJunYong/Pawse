class ChatConversation {
  final String conversationId;
  final String clientUserId;
  final String therapistUserId;
  final String clientName;
  final String therapistName;
  final String? clientAvatarUrl;
  final String? therapistAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatConversation({
    required this.conversationId,
    required this.clientUserId,
    required this.therapistUserId,
    required this.clientName,
    required this.therapistName,
    this.clientAvatarUrl,
    this.therapistAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    DateTime? lastMessageAt;
    final rawLast = json['last_message_at'];
    if (rawLast is String && rawLast.isNotEmpty) {
      lastMessageAt = DateTime.tryParse(rawLast);
    } else if (rawLast is DateTime) {
      lastMessageAt = rawLast;
    }

    return ChatConversation(
      conversationId: json['conversation_id']?.toString() ?? '',
      clientUserId: json['client_user_id']?.toString() ?? '',
      therapistUserId: json['therapist_user_id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? 'Client',
      therapistName: json['therapist_name']?.toString() ?? 'Therapist',
      clientAvatarUrl: json['client_avatar_url']?.toString(),
      therapistAvatarUrl: json['therapist_avatar_url']?.toString(),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: lastMessageAt,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
    );
  }

  String displayCounterpartName({required bool isTherapist}) {
    return isTherapist ? clientName : therapistName;
  }

  String? displayAvatar({required bool isTherapist}) {
    return isTherapist ? clientAvatarUrl : therapistAvatarUrl;
  }
}
