import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/upcoming_session_card.dart';
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
  late Future<TherapySession?> _upcomingSessionFuture;

  // Colors extracted from design
  final Color _bgWhite = Colors.white;
  final Color _textDark = const Color(0xFF2D2D2D);
  final Color _textBrown = const Color(0xFF9A3412);
  final Color _bronzeColor = const Color(0xFFCD7F32);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  final Color _lightOrange = const Color(0xFFFED7AA);

  @override
  void initState() {
    super.initState();
    _upcomingSessionFuture = _bookingService.getUpcomingSession(widget.userId);
  }

  void _refreshUpcomingSession() {
    setState(() {
      _upcomingSessionFuture = _bookingService.getUpcomingSession(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF7F4F2),
          ),
          // Main Scrollable Content (centered, max width 375)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 375),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 120), // Bottom padding for nav bar
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
                    FutureBuilder<TherapySession?>(
                      future: _upcomingSessionFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const UpcomingSessionCard(isLoading: true);
                        }
                        if (snapshot.hasError) {
                          return UpcomingSessionCard(
                            session: null,
                            isLoading: false,
                            errorMessage:
                                'Error loading upcoming session: ${snapshot.error}',
                          );
                        }
                        final session = snapshot.data;
                        return UpcomingSessionCard(
                          session: session,
                          onTap: session == null ? null : () => _showSessionDetails(session),
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

  void _showSessionDetails(TherapySession session) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isProcessing = false;
        String? errorMessage;

        final String scheduleLabel = DateFormat('d MMM yyyy, h:mm a')
            .format(session.scheduledAt.toLocal());
        final String durationLabel = '${session.durationMinutes} minutes';
        final String sessionWindow =
            session.startTime.isNotEmpty && session.endTime.isNotEmpty
                ? '${session.startTime} - ${session.endTime}'
                : scheduleLabel;
        final String feeLabel = 'RM ${session.sessionFee.toStringAsFixed(2)}';
        final String centerName =
            (session.centerName ?? '').trim().isEmpty ? 'Not provided' : session.centerName!.trim();
        final String centerAddress =
            (session.centerAddress ?? '').trim().isEmpty ? 'Not provided' : session.centerAddress!.trim();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Session Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('Therapist', session.therapistName.isNotEmpty ? session.therapistName : 'Therapist'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Center', centerName),
                    const SizedBox(height: 8),
                    _buildDetailRow('Address', centerAddress),
                    const SizedBox(height: 8),
                    _buildDetailRow('Session Time', sessionWindow),
                    const SizedBox(height: 8),
                    _buildDetailRow('Date', scheduleLabel),
                    const SizedBox(height: 8),
                    _buildDetailRow('Duration', durationLabel),
                    const SizedBox(height: 8),
                    _buildDetailRow('Session Fee', feeLabel),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setStateDialog(() {
                            isProcessing = true;
                            errorMessage = null;
                          });
                          try {
                            await _bookingService.cancelBooking(
                              sessionId: session.sessionId,
                              clientUserId: widget.userId,
                            );
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking cancelled successfully.')),
                            );
                            _refreshUpcomingSession();
                          } catch (e) {
                            setStateDialog(() {
                              isProcessing = false;
                              errorMessage = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Cancel Booking'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF5D3A1A),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
        ),
      ],
    );
  }

  // 1. Header Section
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3), // Border thickness
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black, // Border color (or use Colors.orange, _btnBrown, etc.)
              width: 1, // Border width
            ),
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
          margin: const EdgeInsets.only(top: 30), // Push down to make room for cat head
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
                  // ChatSessionScreen is in a friend's module. Uncomment and import when available.
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => ChatSessionScreen(userId: widget.userId),
                  //   ),
                  // );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _btnBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
        // The Cat Image (Positioned at top)
        Positioned(
          top: -120, // Pull up to overlap
          child: Image.asset(
            'assets/images/defaultcat.png', 
            width: 200,
            height: 200,
            fit: BoxFit.cover, // or BoxFit.fill
          ),
        ),
      ],
    );
  }

  // 3. Generic Action Card (Used for Plan and Drift)
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

  // 4. Therapy Section
  Widget _buildTherapyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Connect with certified therapists for guidance and consultation.",
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => FindTherapistScreen(userId: widget.userId),
                  ),
                )
                    .then((_) {
                  _refreshUpcomingSession();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _lightOrange, // Light orange button
                foregroundColor: _btnBrown, // Brown text
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Find a Therapist",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _textBrown,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}