import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';


class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Colors extracted from design
  final Color _bgWhite = Colors.white;
  final Color _textDark = const Color(0xFF2D2D2D);
  final Color _textBrown = const Color(0xFF9A3412);
  final Color _bronzeColor = const Color(0xFFCD7F32);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  final Color _lightOrange = const Color(0xFFFED7AA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF7F4F2),
          ),
          // Main Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 120), // Bottom padding for nav bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildHeroCard(),
                const SizedBox(height: 20),
                _buildActionCard(
                  icon: Icons.assignment_outlined,
                  color: Colors.amber,
                  title: "Today's Plan",
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  imagePath: 'assets/images/Drift_bottle.png',
                  color: Colors.blueAccent,
                  title: "Drift & Heal",
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
            backgroundImage: AssetImage('assets/images/tile000.png'),
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
                onPressed: () {},
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
            'assets/images/tile000.png', 
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
              onPressed: () {},
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