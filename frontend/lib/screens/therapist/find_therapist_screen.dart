import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_conversation.dart';
import '../../models/therapist_model.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../../services/therapist_service.dart';
import '../../widgets/crisis_banner.dart';
import '../../widgets/therapist_card.dart';
import '../chat/chat_contacts_screen.dart';

class FindTherapistScreen extends StatefulWidget {
  final String userId;

  const FindTherapistScreen({super.key, required this.userId});

  @override
  State<FindTherapistScreen> createState() => _FindTherapistScreenState();
}

class _FindTherapistScreenState extends State<FindTherapistScreen> {
  final TherapistService _apiService = TherapistService();
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  late Future<List<Therapist>> _therapistsFuture;
  final TextEditingController _searchController = TextEditingController();
  PendingRatingSession? _pendingRating;
  int _selectedRating = 0;
  bool _isSubmittingRating = false;
  final DateFormat _sessionFormatter = DateFormat('MMM d, h:mm a');
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _therapistsFuture = _apiService.getTherapists();
    _loadPendingRating();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchTherapists(String query) {
    setState(() {
      _therapistsFuture = _apiService.getTherapists(searchQuery: query);
    });
  }

  void _handleSessionBooked() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking confirmed successfully!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  Future<void> _loadPendingRating() async {
    try {
      final pending = await _bookingService.getPendingRating(widget.userId);
      if (!mounted) return;
      setState(() {
        _pendingRating = pending;
        _selectedRating = 0;
      });
    } catch (_) {
      // Ignore rating fetch errors
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final List<ChatConversation> conversations = await _chatService.getConversations(
        userId: widget.userId,
        isTherapist: false,
      );
      if (!mounted) return;
      final int total = conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
      setState(() {
        _unreadMessageCount = total;
      });
    } catch (_) {
      // Ignore unread count fetch errors silently for now.
    }
  }

  Future<void> _submitRating() async {
    final pending = _pendingRating;
    if (pending == null) return;
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a rating before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      await _bookingService.submitSessionRating(
        sessionId: pending.sessionId,
        clientUserId: widget.userId,
        rating: _selectedRating,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanks for rating ${pending.therapistName}!')),
      );

      setState(() {
        _pendingRating = null;
        _selectedRating = 0;
        final query = _searchController.text.trim();
        _therapistsFuture = _apiService.getTherapists(
          searchQuery: query.isEmpty ? null : query,
        );
      });

      await _loadPendingRating();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
        });
      }
    }
  }

  Widget _buildRatingPrompt() {
    final pending = _pendingRating;
    if (pending == null) {
      return const SizedBox.shrink();
    }

    final String scheduledLabel = _sessionFormatter.format(
      pending.scheduledAt.toLocal(),
    );

    final nameParts = pending.therapistName.trim().split(' ');
    final firstName =
        nameParts.isNotEmpty ? nameParts.first : pending.therapistName;
    final displayName = "Dr. $firstName";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your session with $displayName?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Session on $scheduledLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _pendingRating = null;
                    _selectedRating = 0;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final isFilled = index < _selectedRating;
                  return GestureDetector(
                    onTap: _isSubmittingRating
                        ? null
                        : () {
                            setState(() {
                              _selectedRating = index + 1;
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2.0),
                      child: Icon(
                        isFilled
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              if (_isSubmittingRating)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                ElevatedButton(
                  onPressed: _isSubmittingRating ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB923C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4E342E)),
        title: const Text(
          'Find a Therapist',
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          // CHANGED: Replaced Filter button with Chat button
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => ChatContactsScreen(
                          currentUserId: widget.userId,
                          isTherapist: false,
                        ),
                      ),
                    )
                        .then((_) => _loadUnreadCount());
                  },
                ),
                if (_unreadMessageCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _unreadMessageCount > 99
                            ? '99+'
                            : _unreadMessageCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pendingRating != null) _buildRatingPrompt(),
                const CrisisBanner(),
                const SizedBox(height: 24),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onSubmitted: _searchTherapists,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search by name or expertise...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    // CHANGED: Added Row to hold Clear (conditional) and Filter (always)
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min, // Keeps the row tight
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              _searchTherapists('');
                            },
                          ),
                        // Filter Button (Always Visible)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.tune, color: Color(0xFF4E342E)),
                            onPressed: () {
                              // Open Filter Bottom Sheet
                            },
                          ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Therapist List
                FutureBuilder<List<Therapist>>(
                  future: _therapistsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No therapists found.'));
                    }

                    final therapists = snapshot.data!;
                    return ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: therapists.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return TherapistCard(
                          therapist: therapists[index],
                          clientUserId: widget.userId,
                          onSessionBooked: _handleSessionBooked,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}