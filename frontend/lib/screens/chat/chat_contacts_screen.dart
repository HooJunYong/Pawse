import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

// --- Theme Constants ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _surfaceWhite = Colors.white;
const Color _textDark = Color(0xFF3E2723); // Dark Brown
const Color _textGrey = Color(0xFF8D6E63); // Warm Grey
const Color _primaryBrown = Color(0xFF5D4037);
const Color _accentOrange = Color(0xFFFB923C);
const Color _onlineGreen = Color(0xFF22C55E);

final List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: const Color(0xFF5D4037).withOpacity(0.05),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];

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
  final DateFormat _dateFormat = DateFormat('h:mm a'); // Simplified time format
  final DateFormat _dayFormat = DateFormat('MMM d');
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  final Map<String, Uint8List?> _avatarCache = {};

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

  // Format time logic: "10:30 AM" for today, "Oct 24" for older
  String _getFormattedTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(time.year, time.month, time.day);

    if (dateToCheck == today) {
      return _dateFormat.format(time);
    } else {
      return _dayFormat.format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: _surfaceWhite,
            shape: BoxShape.circle,
            boxShadow: _cardShadow,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: _primaryBrown, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: _textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryBrown),
            )
          : RefreshIndicator(
              color: _primaryBrown,
              backgroundColor: _surfaceWhite,
              onRefresh: _handleRefresh,
              child: _conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      itemCount: _conversations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildConversationTile(_conversations[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceWhite,
              shape: BoxShape.circle,
              boxShadow: _cardShadow,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: _textGrey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a chat to stay connected.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: _textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final name = conversation.displayCounterpartName(
      isTherapist: widget.isTherapist,
    );
    final lastMessage = conversation.lastMessage ?? 'Start a conversation';
    final timestamp = _getFormattedTime(conversation.lastMessageAt);
    final unread = conversation.unreadCount;
    final avatarUrl = conversation.displayAvatar(
      isTherapist: widget.isTherapist,
    );
    
    // Mock Online Status (You can replace this with real logic if available)
    final bool isOnline = true; // Changed to true to demonstrate the online indicator

    return GestureDetector(
      onTap: () => _openChat(conversation),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _cardShadow,
          border: Border.all(color: _primaryBrown.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _bgCream, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFFFF3E0),
                    backgroundImage: _buildAvatarImage(avatarUrl),
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _primaryBrown,
                            ),
                          )
                        : null,
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _onlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: _surfaceWhite, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                            color: unread > 0 ? _accentOrange : _textGrey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: unread > 0 ? _textDark : _textGrey,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _accentOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread > 9 ? '9+' : unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _buildAvatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return null;
    }

    if (_isDataUri(avatar)) {
      final bytes = _getCachedDataUri(avatar);
      if (bytes != null && bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }
      return null;
    }

    return NetworkImage(avatar);
  }

  Uint8List? _getCachedDataUri(String dataUri) {
    if (_avatarCache.containsKey(dataUri)) {
      return _avatarCache[dataUri];
    }
    final decoded = _decodeDataUri(dataUri);
    _avatarCache[dataUri] = decoded;
    return decoded;
  }

  bool _isDataUri(String? value) {
    if (value == null) {
      return false;
    }
    final lower = value.toLowerCase();
    return lower.startsWith('data:image/');
  }

  Uint8List? _decodeDataUri(String dataUri) {
    final splitIndex = dataUri.indexOf(',');
    if (splitIndex == -1 || splitIndex == dataUri.length - 1) {
      return null;
    }
    final dataPart = dataUri.substring(splitIndex + 1).trim();
    try {
      return base64Decode(dataPart);
    } catch (_) {
      return null;
    }
  }
}