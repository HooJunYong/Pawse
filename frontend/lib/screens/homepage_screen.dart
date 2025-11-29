import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import '../../widgets/bottom_nav.dart';
import 'therapist/find_therapist_screen.dart';
// import '../../screens/chat/chat_session_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final BookingService _bookingService = BookingService();
  late Future<List<TherapySession>> _upcomingSessionsFuture;
  Timer? _upcomingSessionExpiryTimer;
  bool _showAllUpcomingSessions = false;

  // Colors extracted from design
  final Color _bgWhite = Colors.white;
  final Color _textDark = const Color(0xFF2D2D2D);
  final Color _bronzeColor = const Color(0xFFCD7F32);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  // final Color _lightOrange = const Color(0xFFFED7AA); // Unused in new design

  @override
  void initState() {
    super.initState();
    _loadUpcomingSessions(initialLoad: true, resetToggle: true);
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
                      imagePath: 'assets/images/Drift_bottle.png',
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
                        if (sessions.isEmpty) {
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
                            ? sessions
                            : sessions.take(3).toList();

                        return Column(
                          children: [
                            for (var session in visibleSessions)
                              _buildStyledSessionCard(session),

                            // Show More / Show Less Logic
                            if (!_showAllUpcomingSessions &&
                                sessions.length > visibleSessions.length)
                              const SizedBox(height: 8),
                            if (sessions.length > 3)
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
          child: const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage('assets/images/defaultcat.png'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            "Welcome, Jerry",
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
  Widget _buildStyledSessionCard(TherapySession session) {
    final String timeStr = DateFormat(
      'h:mm a',
    ).format(session.scheduledAt.toLocal());
    final String dateStr = DateFormat(
      'MMM d',
    ).format(session.scheduledAt.toLocal());

    // Get initials
    final nameParts = session.therapistName.trim().split(' ');
    final initials = nameParts.length > 1
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : (nameParts.isNotEmpty ? nameParts[0][0] : 'T');

    return GestureDetector(
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
              // Left Colored Strip
              Container(
                width: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFCD7F32), // Bronze/Orange accent
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
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: Center(
                          child: Text(
                            initials.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
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
                                Text(
                                  "$dateStr, $timeStr",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
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
                      // Arrow Icon
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
  }

//showSessionDetails METHOD
  void _showSessionDetails(TherapySession session) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isProcessing = false;
        String? errorMessage;

        // 1. Format Data
        final DateTime start = session.scheduledAt.toLocal();
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
                              const Text(
                                "Scheduled Time",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
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
                            onPressed: isProcessing 
                              ? null 
                              : () async {
                                  setStateDialog(() => isProcessing = true);
                                  try {
                                    await _bookingService.cancelBooking(
                                      sessionId: session.sessionId,
                                      clientUserId: widget.userId,
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
}
