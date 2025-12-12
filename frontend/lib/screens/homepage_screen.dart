import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/booking_service.dart';
import '../services/profile_service.dart';
import '../widgets/bottom_nav.dart';
import 'therapist/find_therapist_screen.dart';


class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _dismissedSessionsPrefsKey = 'dismissed_cancelled_session_ids';

  int _currentIndex = 0;

  final BookingService _bookingService = BookingService();
  late Future<List<TherapySession>> _upcomingSessionsFuture;
  Timer? _upcomingSessionExpiryTimer;
  bool _showAllUpcomingSessions = false;
  final Set<String> _dismissedCancelledSessionIds = <String>{};
  String _userFirstName = 'Friend';
  String _userInitials = 'U';
  ImageProvider? _userAvatarImage;

  // Colors extracted from design
  final Color _bgWhite = Colors.white;
  final Color _textDark = const Color(0xFF2D2D2D);
  final Color _bronzeColor = const Color(0xFFCD7F32);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  // final Color _lightOrange = const Color(0xFFFED7AA); // Unused in new design

  @override
  void initState() {
    super.initState();
    _initDismissedCancelledSessions();
    _loadUpcomingSessions(initialLoad: true, resetToggle: true);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _upcomingSessionExpiryTimer?.cancel();
    super.dispose();
  }

  void _loadUpcomingSessions({
    bool initialLoad = false,
    bool resetToggle = false,
  }) {
    _upcomingSessionExpiryTimer?.cancel();
    final future = _bookingService.getUpcomingSessions(widget.userId);
    if (resetToggle) {
      _showAllUpcomingSessions = false;
    }
    if (initialLoad) {
      _upcomingSessionsFuture = future;
    } else {
      setState(() {
        _upcomingSessionsFuture = future;
      });
    }

    future.then((sessions) {
      if (!mounted) return;
      final validIds = sessions.map((session) => session.sessionId).toSet();
      bool removedAny = false;
      if (_dismissedCancelledSessionIds.isNotEmpty) {
        setState(() {
          _dismissedCancelledSessionIds.removeWhere((id) {
            final shouldRemove = !validIds.contains(id);
            if (shouldRemove) removedAny = true;
            return shouldRemove;
          });
        });
      }
      if (removedAny) {
        _persistDismissedCancelledSessions();
      }
      _scheduleUpcomingSessionRefresh(sessions);
    });
  }

  void _refreshUpcomingSession() {
    _loadUpcomingSessions(resetToggle: true);
  }

  void _scheduleUpcomingSessionRefresh(List<TherapySession>? sessions) {
    _upcomingSessionExpiryTimer?.cancel();
    if (sessions == null || sessions.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    // Convert session times to local for comparison with local 'now'
    final upcoming =
        sessions
            .where((session) => session.scheduledAt.toLocal().isAfter(now))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (upcoming.isEmpty) {
      _refreshUpcomingSession();
      return;
    }

    final DateTime sessionStart = upcoming.first.scheduledAt.toLocal();
    final Duration difference = sessionStart.difference(now);

    if (difference <= Duration.zero) {
      _refreshUpcomingSession();
      return;
    }

    _upcomingSessionExpiryTimer = Timer(difference, () {
      if (!mounted) return;
      _refreshUpcomingSession();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ProfileService.getProfile(widget.userId);
      if (response.statusCode != 200) {
        return;
      }
      final dynamic decoded = jsonDecode(response.body);
      if (!mounted) {
        return;
      }
      if (decoded is Map<String, dynamic>) {
        final String firstName = _extractFirstName(decoded['full_name']);
        final String initials = _extractInitials(
          decoded['initials'],
          decoded['full_name'],
        );
        final ImageProvider? avatar = _resolveProfileAvatar(
          decoded['avatar_base64']?.toString(),
          decoded['avatar_url']?.toString(),
        );

        setState(() {
          if (firstName.isNotEmpty) {
            _userFirstName = firstName;
          }
          if (initials.isNotEmpty) {
            _userInitials = initials;
          }
          _userAvatarImage = avatar;
        });
      }
    } catch (_) {
      // Silently ignore profile load failures; keep friendly fallback.
    }
  }

  String _extractFirstName(dynamic fullNameValue) {
    if (fullNameValue is! String) {
      return '';
    }
    final String trimmed = fullNameValue.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '';
    }
    final String first = parts.first.trim();
    if (first.isEmpty) {
      return '';
    }
    if (first.length == 1) {
      return first.toUpperCase();
    }
    return first[0].toUpperCase() + first.substring(1);
  }

  String _extractInitials(dynamic initialsValue, dynamic fullNameValue) {
    if (initialsValue is String && initialsValue.trim().isNotEmpty) {
      final trimmed = initialsValue.trim();
      return trimmed.length > 2 ? trimmed.substring(0, 2).toUpperCase() : trimmed.toUpperCase();
    }
    if (fullNameValue is! String) {
      return '';
    }
    final parts = fullNameValue.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    final firstInitial = parts[0][0].toUpperCase();
    final secondInitial = parts[1][0].toUpperCase();
    return '$firstInitial$secondInitial';
  }

  ImageProvider? _resolveProfileAvatar(String? base64Value, String? urlValue) {
    final ImageProvider? fromBase64 = _decodeAvatarBase64(base64Value);
    if (fromBase64 != null) {
      return fromBase64;
    }

    final String? trimmedUrl = urlValue?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return null;
    }
    if (_isDataUri(trimmedUrl)) {
      final bytes = _decodeDataUri(trimmedUrl);
      return bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null;
    }
    return NetworkImage(trimmedUrl);
  }

  ImageProvider? _decodeAvatarBase64(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_isDataUri(trimmed)) {
      final bytes = _decodeDataUri(trimmed);
      return bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null;
    }
    try {
      final bytes = base64Decode(trimmed);
      return bytes.isNotEmpty ? MemoryImage(bytes) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFF7F4F2)),
          // Main Scrollable Content (centered, max width 375)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 375),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  60,
                  24,
                  120,
                ), // Bottom padding for nav bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildHeroCard(),
                    const SizedBox(height: 24),
                    _buildActionCard(
                      imagePath: 'assets/images/drift_bottle.png',
                      color: Colors.blueAccent,
                      title: "Drift & Heal",
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Your Upcoming Session",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<TherapySession>>(
                      future: _upcomingSessionsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Error loading upcoming sessions: ${snapshot.error}',
                            ),
                          );
                        }
                        final sessions = snapshot.data ?? [];

                        final filteredSessions = sessions.where((session) {
                          final status = session.sessionStatus.toLowerCase();
                          final isCancelled = status.contains('cancel');
                          if (isCancelled &&
                              _dismissedCancelledSessionIds.contains(session.sessionId)) {
                            return false;
                          }
                          return true;
                        }).toList();

                        if (filteredSessions.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 40,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "No upcoming sessions.",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          );
                        }

                        final List<TherapySession> visibleSessions =
                            _showAllUpcomingSessions
                                ? filteredSessions
                                : filteredSessions.take(3).toList();

                        return Column(
                          children: [
                            for (var session in visibleSessions)
                              _buildStyledSessionCard(
                                session,
                                onDismissCancelled: session.sessionStatus
                                        .toLowerCase()
                                        .contains('cancel')
                                    ? () {
                                        setState(() {
                                          _dismissedCancelledSessionIds
                                              .add(session.sessionId);
                                        });
                                        _persistDismissedCancelledSessions();
                                      }
                                    : null,
                              ),

                            // Show More / Show Less Logic
                            if (!_showAllUpcomingSessions &&
                                filteredSessions.length > visibleSessions.length)
                              const SizedBox(height: 8),
                            if (filteredSessions.length > 3)
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showAllUpcomingSessions =
                                          !_showAllUpcomingSessions;
                                    });
                                  },
                                  icon: Icon(
                                    _showAllUpcomingSessions
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: _btnBrown,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _showAllUpcomingSessions
                                        ? 'Show less'
                                        : 'Show more',
                                    style: TextStyle(
                                      color: _btnBrown,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _btnBrown,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Professional Therapy",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTherapyCard(),
                  ],
                ),
              ),
            ),
          ),
          // Floating Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              userId: widget.userId,
              selectedIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  // 1. Header Section
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: _userAvatarImage,
            child: _userAvatarImage == null
                ? Text(
                    _userInitials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A3412),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            "Welcome, ${_userFirstName.isNotEmpty ? _userFirstName : 'Friend'}",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _btnBrown,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _bronzeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Bronze",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // 2. Hero Section with overlapping Cat
  Widget _buildHeroCard() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // The Card Background
        Container(
          margin: const EdgeInsets.only(top: 30),
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
          decoration: BoxDecoration(
            color: _bgWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Hey Jerry. Heard that you are not feeling so well today. It's ok to have a bad day, want to talk with me on what is going on?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigator.of(context).push(...)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Chat now",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // The Cat Image
        Positioned(
          top: -120,
          child: Image.asset(
            'assets/images/defaultcat.png',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  // 3. Generic Action Card (Used for Drift)
  Widget _buildActionCard({
    IconData? icon,
    String? imagePath,
    required Color color,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (imagePath != null)
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: Image.asset(imagePath, height: 48, width: 48),
            )
          else if (icon != null)
            Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Improved Therapy Section
  Widget _buildTherapyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // A soft warm background instead of plain white
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9A3412).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Need professional help?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9A3412), // Text Brown
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Connect with certified therapists for guidance.",
                  style: TextStyle(
                    color: _textDark.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                FindTherapistScreen(userId: widget.userId),
                          ),
                        )
                        .then((_) {
                          _refreshUpcomingSession();
                        });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _btnBrown,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Find a Therapist",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Decorative Icon on the right
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 32,
              color: Color(0xFFCD7F32), // Bronze color
            ),
          ),
        ],
      ),
    );
  }

  // 5. New Styled Session Card (Ticket Style)
  Widget _buildStyledSessionCard(
    TherapySession session, {
    VoidCallback? onDismissCancelled,
  }) {
    final String timeStr = DateFormat('h:mm a').format(session.scheduledAt);
    final String dateStr = DateFormat('MMM d').format(session.scheduledAt);

    final nameParts = session.therapistName.trim().split(' ');
    final initials = nameParts.length > 1
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : (nameParts.isNotEmpty ? nameParts[0][0] : 'T');

    final statusChip = _buildStatusChip(session.sessionStatus);
    final avatarImage = _buildAvatarImage(session.therapistProfilePictureUrl);

    final card = GestureDetector(
      onTap: () => _showSessionDetails(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFCD7F32),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFFFFF7ED),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Text(
                                initials.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF9A3412),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dr. ${session.therapistName}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "$dateStr, $timeStr",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${session.durationMinutes} mins",
                              style: TextStyle(
                                fontSize: 12,
                                color: _bronzeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusChip,
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final isCancelled = session.sessionStatus.toLowerCase().contains('cancel');
    if (!isCancelled || onDismissCancelled == null) {
      return card;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: 6,
          right: 10,
          child: GestureDetector(
            onTap: onDismissCancelled,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: Color(0xFF9A3412),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _initDismissedCancelledSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_dismissedSessionsPrefsKey);
    if (!mounted) return;
    if (stored == null || stored.isEmpty) {
      return;
    }
    setState(() {
      _dismissedCancelledSessionIds
        ..clear()
        ..addAll(stored);
    });
  }

  Future<void> _persistDismissedCancelledSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dismissedSessionsPrefsKey,
      _dismissedCancelledSessionIds.toList(),
    );
  }

//showSessionDetails METHOD
  void _showSessionDetails(TherapySession session) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isProcessing = false;
        String? errorMessage;
        final statusLower = session.sessionStatus.toLowerCase();
        final DateTime start = session.scheduledAt;
        final Duration timeUntilStart = start.difference(DateTime.now());
        final bool canCancel =
            statusLower == 'scheduled' && timeUntilStart > const Duration(hours: 1);

        String? cancellationMessage;
        if (!canCancel) {
          if (statusLower == 'scheduled') {
            cancellationMessage =
                'Sessions can only be cancelled more than 1 hour before the scheduled start time.';
          } else if (statusLower != 'cancelled') {
            cancellationMessage = 'This session can no longer be cancelled.';
          }
        }

        // 1. Format Data
        final String dayStr = DateFormat('d').format(start);
        final String monthStr = DateFormat('MMM').format(start);
        
        final String timeStr = (session.startTime.isNotEmpty && session.endTime.isNotEmpty)
            ? '${session.startTime} - ${session.endTime}'
            : DateFormat('h:mm a').format(start);

        final String centerInfo = [session.centerName, session.centerAddress]
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(', ');

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              // Adjust insetPadding to allow the 350px width to fit comfortably
              insetPadding: const EdgeInsets.symmetric(horizontal: 12), 
              child: Container(
                width: 350, // CHANGED: Fixed width to 350px
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 2. Header: Date Badge + Time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFCC80)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                dayStr,
                                style: const TextStyle(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold, 
                                  color: Color(0xFF9A3412),
                                  height: 1,
                                ),
                              ),
                              Text(
                                monthStr.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: Color(0xFFCD7F32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Scheduled Time",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  _buildStatusChip(session.sessionStatus),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 24),

                    // 3. Details
                    _buildIconDetailRow(
                      Icons.person_outline, 
                      "Therapist", 
                      session.therapistName.isNotEmpty ? "Dr. ${session.therapistName}" : "Unknown"
                    ),
                    const SizedBox(height: 16),
                    _buildIconDetailRow(
                      Icons.location_on_outlined, 
                      "Location", 
                      centerInfo.isEmpty ? "Online / Not provided" : centerInfo
                    ),
                    const SizedBox(height: 16),
                    _buildIconDetailRow(
                      Icons.attach_money, 
                      "Session Fee", 
                      "RM ${session.sessionFee.toStringAsFixed(2)}"
                    ),

                    if (cancellationMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          cancellationMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // 4. Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isProcessing ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              // CHANGED: Increased vertical padding to 18
                              padding: const EdgeInsets.symmetric(vertical: 18), 
                            ),
                            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (isProcessing || !canCancel)
                              ? null
                              : () async {
                                  setStateDialog(() => isProcessing = true);
                                  try {
                                    await _bookingService.cancelBooking(
                                      sessionId: session.sessionId,
                                      clientUserId: widget.userId,
                                      therapistUserId: session.therapistUserId,
                                      cancelledBy: 'client',
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Booking cancelled successfully.')),
                                    );
                                    _refreshUpcomingSession();
                                  } catch(e) {
                                    setStateDialog(() {
                                      isProcessing = false;
                                      errorMessage = e.toString().replaceFirst('Exception: ', '');
                                    });
                                  }
                                },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFEF4444),
                              elevation: 0,
                              // CHANGED: Increased vertical padding to 18
                              padding: const EdgeInsets.symmetric(vertical: 18), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isProcessing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                              : const Text("Cancel Booking", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ------------------------------------------------
  // ADD THIS NEW HELPER METHOD TO YOUR CLASS
  // ------------------------------------------------
  Widget _buildIconDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF9A3412)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final label = _statusLabel(status);
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'no_show':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF16A34A);
    }
  }

  String _statusLabel(String status) {
    final lower = status.toLowerCase();
    if (lower.isEmpty) {
      return 'Unknown';
    }
    return lower.split('_').map((part) {
      if (part.isEmpty) {
        return part;
      }
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  ImageProvider? _buildAvatarImage(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }
    if (_isDataUri(source)) {
      final bytes = _decodeDataUri(source);
      if (bytes != null && bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }
      return null;
    }
    return NetworkImage(source);
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
    final payload = dataUri.substring(separator + 1).trim();
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}
