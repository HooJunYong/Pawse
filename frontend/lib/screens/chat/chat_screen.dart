import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_conversation.dart';
import '../../models/chat_message.dart';
import '../../services/api_service.dart';
import '../../services/chat_notification_service.dart';
import '../../services/chat_service.dart';
import '../../services/profile_service.dart';

// --- Theme Constants ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _surfaceWhite = Colors.white;
const Color _textDark = Color(0xFF3E2723); // Dark Brown
const Color _textGrey = Color(0xFF8D6E63); // Warm Grey
const Color _primaryBrown = Color(0xFF5D4037);
const Color _bubbleSent = Color(0xFFFFCCBC); // Lighter Orange for sent messages
const Color _bubbleReceived = Colors.white; // White for received messages
//const Color _bubbleReceived = Color(0xFFFEEDE7); // Light Cream for received messages

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String clientUserId;
  final String therapistUserId;
  final String currentUserId;
  final bool isTherapist;
  final String counterpartName;
  final String? counterpartAvatarUrl;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.clientUserId,
    required this.therapistUserId,
    required this.currentUserId,
    required this.isTherapist,
    required this.counterpartName,
    this.counterpartAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;
  String? _counterpartAvatarUrl;
  Uint8List? _counterpartAvatarBytes;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _counterpartAvatarUrl = widget.counterpartAvatarUrl;
    _counterpartAvatarBytes = _prepareAvatarBytes(_counterpartAvatarUrl);
    _initializeConversation();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.counterpartAvatarUrl != oldWidget.counterpartAvatarUrl) {
      setState(() {
        _counterpartAvatarUrl = widget.counterpartAvatarUrl;
        _counterpartAvatarBytes = _prepareAvatarBytes(_counterpartAvatarUrl);
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    setState(() => _isLoading = true);
    try {
      if (_conversationId == null) {
        final ChatConversation conversation = await _chatService.createConversation(
          clientUserId: widget.clientUserId,
          therapistUserId: widget.therapistUserId,
          isTherapistRequester: widget.isTherapist,
        );
        _conversationId = conversation.conversationId;
        final counterpartAvatar = conversation.displayAvatar(
          isTherapist: widget.isTherapist,
        );
        if (mounted) {
          setState(() {
            _counterpartAvatarUrl = counterpartAvatar ?? _counterpartAvatarUrl;
            _counterpartAvatarBytes = _prepareAvatarBytes(_counterpartAvatarUrl);
          });
        } else {
          _counterpartAvatarUrl = counterpartAvatar ?? _counterpartAvatarUrl;
          _counterpartAvatarBytes = _prepareAvatarBytes(_counterpartAvatarUrl);
        }
      }
      await _loadMessages();
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open chat: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshMessages();
    });
  }

  Future<void> _markConversationAsRead() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      await _chatService.markConversationRead(
        conversationId: conversationId,
        userId: widget.currentUserId,
        isTherapist: widget.isTherapist,
      );
    } catch (_) {
      // Ignore read failures silently
    }
  }

  Future<void> _loadMessages() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      final messages = await _chatService.getMessages(
        conversationId: conversationId,
        limit: 100,
      );
      if (!mounted) return;
      setState(() => _messages = messages);
      await _markConversationAsRead();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load messages: $e')),
      );
    }
  }

  Future<void> _refreshMessages() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    try {
      final messages = await _chatService.getMessages(
        conversationId: conversationId,
        limit: 100,
      );
      if (!mounted) return;
      if (messages.length != _messages.length ||
          (messages.isNotEmpty && _messages.isNotEmpty &&
              messages.last.messageId != _messages.last.messageId)) {
        // Check for new messages from the counterpart
        final newMessages = messages.where((msg) => 
          !_messages.any((existing) => existing.messageId == msg.messageId) &&
          msg.senderId != widget.currentUserId
        ).toList();
        
        // Show notification for each new message from counterpart
        for (final newMsg in newMessages) {
          await ChatNotificationService.showMessageNotification(
            message: newMsg,
            currentUserId: widget.currentUserId,
            senderName: widget.counterpartName,
            isTherapist: widget.isTherapist,
          );
        }
        
        setState(() => _messages = messages);
        await _markConversationAsRead();
        _scrollToBottom();
      }
    } catch (_) {
      // Ignore polling failures
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final message = await _chatService.sendMessage(
        senderId: widget.currentUserId,
        isTherapist: widget.isTherapist,
        content: text,
        conversationId: _conversationId,
        clientUserId: widget.clientUserId,
        therapistUserId: widget.therapistUserId,
      );
      _conversationId = message.conversationId;
      _messageController.clear();
      setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _showProfileInfoDialog() async {
    try {
      // Determine whose profile to fetch (the counterpart's profile)
      final String counterpartUserId = widget.isTherapist 
          ? widget.clientUserId 
          : widget.therapistUserId;
      
      String firstName = '';
      String lastName = '';
      String email = '';
      String phoneNumber = '';
      ImageProvider? avatarImage;
      String? centerName;
      String? therapistContactNumber;
      
      if (widget.isTherapist) {
        // Therapist viewing client - get client profile
        final response = await ProfileService.getProfileDetails(counterpartUserId);
        
        if (response.statusCode != 200) {
          throw Exception('Failed to load profile');
        }
        
        final profileData = jsonDecode(response.body);
        
        firstName = profileData['first_name']?.toString() ?? '';
        lastName = profileData['last_name']?.toString() ?? '';
        email = profileData['email']?.toString() ?? '';
        phoneNumber = profileData['phone_number']?.toString() ?? '';
        
        // Get client avatar from user_profile (avatar_base64)
        final String? avatarBase64 = profileData['avatar_base64']?.toString();
        final String? avatarUrl = profileData['avatar_url']?.toString();
        
        if (avatarBase64 != null && avatarBase64.isNotEmpty && avatarBase64.toLowerCase().startsWith('data:image/')) {
          final separator = avatarBase64.indexOf(',');
          if (separator != -1) {
            final dataPart = avatarBase64.substring(separator + 1).trim();
            try {
              final bytes = base64Decode(dataPart);
              avatarImage = MemoryImage(bytes);
            } catch (_) {}
          }
        } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
          avatarImage = NetworkImage(avatarUrl);
        }
      } else {
        // Client viewing therapist - fetch therapist profile directly
        final therapistResponse = await ApiService.get('/therapist/profile/$counterpartUserId');
        
        if (therapistResponse.statusCode != 200) {
          throw Exception('Failed to load therapist profile');
        }
        
        final therapistData = jsonDecode(therapistResponse.body);
        
        firstName = therapistData['first_name']?.toString() ?? '';
        lastName = therapistData['last_name']?.toString() ?? '';
        email = therapistData['email']?.toString() ?? '';
        centerName = therapistData['office_name']?.toString() ?? 'Holistic Mind Center';
        therapistContactNumber = therapistData['contact_number']?.toString();
        
        // Get therapist profile picture from profile_picture_base64
        final String? profilePictureBase64 = therapistData['profile_picture_base64']?.toString();
        final String? profilePictureUrl = therapistData['profile_picture_url']?.toString();
        
        if (profilePictureBase64 != null && profilePictureBase64.isNotEmpty && profilePictureBase64.toLowerCase().startsWith('data:image/')) {
          final separator = profilePictureBase64.indexOf(',');
          if (separator != -1) {
            final dataPart = profilePictureBase64.substring(separator + 1).trim();
            try {
              final bytes = base64Decode(dataPart);
              avatarImage = MemoryImage(bytes);
            } catch (_) {}
          }
        } else if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
          avatarImage = NetworkImage(profilePictureUrl);
        }
      }
      
      // Build full name
      final String fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
          ? '$firstName $lastName'.trim()
          : widget.counterpartName;
      
      if (!mounted) return;
      
      // Show dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surfaceWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _bgCream,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: _primaryBrown,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Name (with Dr. prefix for therapists if client is viewing)
                  Text(
                    widget.isTherapist 
                        ? fullName 
                        : (fullName.toLowerCase().startsWith('dr.') 
                            ? fullName 
                            : 'Dr. $fullName'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: _textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Email
                  if (email.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, email),
                  
                  // Phone number (show user profile phone_number if available, or therapist contact_number for therapists)
                  if (widget.isTherapist && phoneNumber.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, phoneNumber),
                  
                  if (!widget.isTherapist && therapistContactNumber != null && therapistContactNumber.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, therapistContactNumber),
                  
                  // Center name (only for therapists when client is viewing)
                  if (!widget.isTherapist && centerName != null)
                    _buildInfoRow(Icons.location_city_outlined, centerName),
                  
                  const SizedBox(height: 20),
                  
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBrown,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Nunito',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: _primaryBrown,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Nunito',
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _buildCounterpartAvatarImage();
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _surfaceWhite,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, color: _primaryBrown)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.counterpartName,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: _textGrey),
            onPressed: () => _showProfileInfoDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _ChatBackgroundPattern()),
          Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _primaryBrown),
                        )
                      : _messages.isEmpty
                          ? Center(
                              child: Text(
                                'Say hello to start the conversation.',
                                style: TextStyle(
                                  color: _textGrey.withOpacity(0.7),
                                  fontSize: 15,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                bool isMine;
                                if (widget.clientUserId == widget.therapistUserId) {
                                  final String myRole = widget.isTherapist ? 'therapist' : 'client';
                                  isMine = message.senderRole == myRole;
                                } else {
                                  isMine = message.senderId == widget.currentUserId;
                                }

                                // Show date header if needed (simplified logic)
                                final bool showDate = index == 0;

                                return Column(
                                  children: [
                                    if (showDate)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Text(
                                          'Today',
                                          style: TextStyle(
                                            color: _textGrey.withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                      ),
                                    _buildChatBubble(message, isMine),
                                  ],
                                );
                              },
                            ),
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isMine) {
    // Format time - the datetime from backend is already in Malaysia time (UTC+8)
    // Don't use toLocal() as it would convert again
    final timeStr = DateFormat('h:mm a').format(message.createdAt);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double horizontalPadding = 16;
        final double maxBubbleWidth = constraints.maxWidth * 0.75;
        final double maxTextWidth = math.max(1, maxBubbleWidth - (horizontalPadding * 2));
        final ui.TextDirection textDirection = Directionality.of(context);

        final TextStyle messageStyle = TextStyle(
          fontSize: 15,
          height: 1.4,
          fontFamily: 'Nunito',
          color: _textDark,
        );
        final TextStyle timeStyle = TextStyle(
          fontSize: 10,
          fontFamily: 'Nunito',
          color: _textGrey,
        );

        final double contentWidth = _calculateIntrinsicTextWidth(
          text: message.content,
          style: messageStyle,
          textDirection: textDirection,
          maxWidth: maxTextWidth,
        );
        final double timeWidth = _calculateIntrinsicTextWidth(
          text: timeStr,
          style: timeStyle,
          textDirection: textDirection,
          maxWidth: maxTextWidth,
        );

        final double targetWidth = math.max(contentWidth, timeWidth) + (horizontalPadding * 2);
        final double bubbleWidth = targetWidth.clamp(80.0, maxBubbleWidth);

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: SizedBox(
            width: bubbleWidth,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(horizontalPadding),
              decoration: BoxDecoration(
                color: isMine ? _bubbleSent : _bubbleReceived,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isMine ? const Radius.circular(0) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: messageStyle,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      timeStr,
                      style: timeStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), // Bottom padding for safe area
      decoration: BoxDecoration(
        color: _surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgCream,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _primaryBrown.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: _textGrey.withOpacity(0.7), fontFamily: 'Nunito'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _handleSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _primaryBrown, // Dark brown send button
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _buildCounterpartAvatarImage() {
    if (_counterpartAvatarBytes != null && _counterpartAvatarBytes!.isNotEmpty) {
      return MemoryImage(_counterpartAvatarBytes!);
    }
    final url = _counterpartAvatarUrl;
    if (url != null && url.isNotEmpty && !_isDataUri(url)) {
      return NetworkImage(url);
    }
    return null;
  }

  Uint8List? _prepareAvatarBytes(String? avatar) {
    if (!_isDataUri(avatar)) {
      return null;
    }
    final decoded = _decodeDataUri(avatar!);
    return decoded != null && decoded.isNotEmpty ? decoded : null;
  }

  bool _isDataUri(String? value) {
    if (value == null) {
      return false;
    }
    final lower = value.toLowerCase();
    return lower.startsWith('data:image/');
  }

  Uint8List? _decodeDataUri(String dataUri) {
    final separator = dataUri.indexOf(',');
    if (separator == -1 || separator == dataUri.length - 1) {
      return null;
    }
    final dataPart = dataUri.substring(separator + 1).trim();
    try {
      return base64Decode(dataPart);
    } catch (_) {
      return null;
    }
  }

  double _calculateIntrinsicTextWidth({
    required String text,
    required TextStyle style,
    required ui.TextDirection textDirection,
    required double maxWidth,
  }) {
    if (text.isEmpty) {
      return 0;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: null,
    )
      ..layout(maxWidth: maxWidth);
    return painter.size.width;
  }
}

class _ChatBackgroundPattern extends StatelessWidget {
  const _ChatBackgroundPattern();

  static const int _columns = 4;
  static const int _rows = 6;
  static const String _assetPath = 'assets/images/tile001.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgCream,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tileWidth = constraints.maxWidth / _columns;
          final double tileHeight = constraints.maxHeight / _rows;

          final List<Widget> tiles = [];
          for (int row = 0; row < _rows; row++) {
            for (int column = 0; column < _columns; column++) {
              tiles.add(
                Positioned(
                  left: column * tileWidth,
                  top: row * tileHeight,
                  width: tileWidth,
                  height: tileHeight,
                  child: Center(
                    child: Image.asset(
                      _assetPath,
                      width: tileWidth * 0.7,
                      height: tileHeight * 0.7,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            }
          }

          return Stack(children: tiles);
        },
      ),
    );
  }
}