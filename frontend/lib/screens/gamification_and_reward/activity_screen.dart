import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/rank_badge.dart';
import '../../services/activity_service.dart';
import '../../services/profile_service.dart';
import 'reward_screen.dart';
import 'dart:convert';

class ActivityScreen extends StatefulWidget {
  final String userId;

  const ActivityScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _currentIndex = 3; // Set to 3 for activity/medal icon

  // Define Colors from design
  final Color kBackgroundColor = const Color(0xFFF7F4F2);
  final Color kProgressBarColor = const Color(0xFFFD9658);
  final Color kRewardsButtonColor = const Color(0xFF5D2D05);
  final Color kTextColor = const Color(0xFF1A1A1A);

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = "User";
  String _userAvatar = 'assets/images/americonsh1.png';
  String _rankName = "Bronze";
  int _currentPoints = 0;
  int _nextRankPoints = 0;
  int _pointsNeeded = 0;
  double _progressPercentage = 0.0;
  List<Map<String, dynamic>> _activities = [];
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user profile
      await _loadUserProfile();

      // Load rank progress
      final rankProgress = await ActivityService.getRankProgress(widget.userId);
      if (rankProgress != null) {
        setState(() {
          _rankName = rankProgress['current_rank_name'] ?? 'Bronze';
          _currentPoints = rankProgress['lifetime_points'] ?? 0;
          _nextRankPoints = rankProgress['next_rank_min_points'] ?? 0;
          _pointsNeeded = rankProgress['points_needed'] ?? 0;
          _progressPercentage = (rankProgress['progress_percentage'] ?? 0).toDouble();
        });
      }

      // Load daily activities
      final activitiesData = await ActivityService.getDailyActivities(widget.userId);
      if (activitiesData != null) {
        setState(() {
          _activities = List<Map<String, dynamic>>.from(activitiesData['activities'] ?? []);
          _completedCount = activitiesData['completed_count'] ?? 0;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load activity data: $e';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ProfileService.getProfile(widget.userId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          final firstName = data['first_name'] ?? '';
          final lastName = data['last_name'] ?? '';
          _userName = firstName.isNotEmpty ? firstName : 'User';
          
          // Check for avatar
          final avatarUrl = data['avatar_url'] as String?;
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            _userAvatar = avatarUrl;
          }
        });
      }
    } catch (e) {
      // Keep default values on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Main Scrollable Content
          SafeArea(
            bottom: false, // Let content go behind the nav bar
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadActivityData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Bottom padding for Nav Bar
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 30),
                                  _buildProgressCard(),
                                  const SizedBox(height: 20),
                                  _buildActivitiesCard(),
                                  const SizedBox(height: 30),
                                  _buildRewardsSection(),
                                ],
                              ),
                            ),
                          );
              },
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

  // --- Header Section (Avatar + Name + Badge) ---
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
            color: Colors.white,
          ),
          child: ClipOval(
            child: _userAvatar.startsWith('http')
                ? Image.network(
                    _userAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/americonsh1.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    _userAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.pets, color: Colors.grey);
                    },
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _userName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const Spacer(),
        RankBadge(userId: widget.userId),
      ],
    );
  }

  // --- Progress Card ---
  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            _pointsNeeded > 0
                ? "Earn $_pointsNeeded points to unlock next level"
                : "You've reached the maximum rank!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 15),
          // Custom Progress Bar
          Container(
            height: 32,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Filled portion
                FractionallySizedBox(
                  widthFactor: _progressPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kProgressBarColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Text Overlay
                Center(
                  child: Text(
                    _pointsNeeded > 0
                        ? "$_currentPoints/$_nextRankPoints"
                        : "Max Rank",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Earn points by completing activities to level up your badge!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- Activities List Card ---
  Widget _buildActivitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          const Text(
            "Today activities",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationThickness: 1.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          if (_activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "No activities assigned for today",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ..._activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 15),
                  _buildActivityItem(
                    activity['activity_description'] ?? 'Activity',
                    isCompleted: activity['status'] == 'completed',
                    points: activity['status'] != 'completed' 
                        ? "+ ${activity['point_award']}pts" 
                        : null,
                    progress: activity['progress'] ?? 0,
                    target: activity['target'] ?? 1,
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String text, {
    bool isCompleted = false,
    String? points,
    int progress = 0,
    int target = 1,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (isCompleted)
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF4CAF50), // Green color
            size: 24,
          )
        else if (points != null)
          Text(
            points,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
      ],
    );
  }

  // --- Rewards Section (Bubble + Cat + Button) ---
  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Speech Bubble
        Padding(
          padding: const EdgeInsets.only(left: 60.0),
          child: CustomPaint(
            painter: BubblePainter(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.only(bottom: 5), // Space for the tail
              child: const Text(
                "Click me to get\nrewards!",
                style: TextStyle(
                  fontFamily: 'Pixelify Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        
        // Cat and Button Stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            // The Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RewardScreen(userId: widget.userId),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(top: 15), // Push down to let cat sit on top
                width: 180,
                height: 50,
                decoration: BoxDecoration(
                  color: kRewardsButtonColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Rewards",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // The Cat Image sitting on the button
            Positioned(
              right: 60,
              bottom: 45, // Align with top of button
              child: Image.asset(
                'assets/images/americansh2.png',
                height: 100, // Adjust size based on your actual image
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.pets, size: 40);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Custom Painter for Speech Bubble Tail ---
class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Path path = Path();
    
    // Bubble dimensions
    final double w = size.width;
    final double h = size.height;
    final double r = 20.0; // Radius

    // Draw the rounded rectangle
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    // The tail logic (bottom left side)
    path.lineTo(40, h);
    path.lineTo(30, h + 10); // Tail tip
    path.lineTo(25, h);
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.close();

    // Draw shadow first
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    // Draw bubble
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}