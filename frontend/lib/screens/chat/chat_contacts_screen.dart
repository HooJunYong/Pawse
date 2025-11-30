import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatContactsScreen extends StatefulWidget {
  final String currentUserId;
  final bool isTherapist;

  const ChatContactsScreen({
    super.key,
    required this.currentUserId,
    required this.isTherapist,
  });

  @override
  State<ChatContactsScreen> createState() => _ChatContactsScreenState();
}

class _ChatContactsScreenState extends State<ChatContactsScreen> {
  final ChatService _chatService = ChatService();
  final DateFormat _dateFormat = DateFormat('MMM d, h:mm a');
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _chatService.getConversations(
        userId: widget.currentUserId,
        isTherapist: widget.isTherapist,
      );
      if (!mounted) return;
      setState(() => _conversations = conversations);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load contacts: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadConversations();
  }

  void _openChat(ChatConversation conversation) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.conversationId,
          clientUserId: conversation.clientUserId,
          therapistUserId: conversation.therapistUserId,
          currentUserId: widget.currentUserId,
          isTherapist: widget.isTherapist,
          counterpartName: conversation.displayCounterpartName(
            isTherapist: widget.isTherapist,
          ),
          counterpartAvatarUrl: conversation.displayAvatar(
            isTherapist: widget.isTherapist,
          ),
        ),
      ),
    )
        .then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F4F2),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3E2723)),
        title: const Text(
          'Therapy Chat',
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5D4037)),
            )
          : RefreshIndicator(
              color: const Color(0xFF5D4037),
              onRefresh: _handleRefresh,
              child: _conversations.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No conversations yet. Start a chat to stay connected.',
                            style: TextStyle(
                              color: Color(0xFF8D6E63),
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        final name = conversation.displayCounterpartName(
                          isTherapist: widget.isTherapist,
                        );
                        final subtitle = conversation.lastMessage ?? 'Tap to continue the conversation';
                        final timestamp = conversation.lastMessageAt;
                        final unread = conversation.unreadCount;
                        final avatarUrl = conversation.displayAvatar(
                          isTherapist: widget.isTherapist,
                        );

                        return ListTile(
                          onTap: () => _openChat(conversation),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? const Icon(Icons.person, color: Color(0xFF5D4037))
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (timestamp != null)
                                Text(
                                  _dateFormat.format(timestamp.toLocal()),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8D6E63),
                                  ),
                                ),
                              if (unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFB923C),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _conversations.length,
                    ),
            ),
    );
  }
}
