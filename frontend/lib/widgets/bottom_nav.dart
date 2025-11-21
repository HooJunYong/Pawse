import 'package:flutter/material.dart';
import '../screens/homepage_screen.dart';
import '../screens/chat_session_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_rounded),
          _buildNavItem(1, Icons.chat_bubble_outline_rounded),
          _buildNavItem(2, Icons.calendar_today_rounded),
          _buildNavItem(3, Icons.military_tech_outlined), // Medal/Award icon
          _buildNavItem(4, Icons.local_florist_outlined), // Plant icon
          _buildNavItem(5, Icons.person_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = selectedIndex == index;
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          if (index == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          } else {
            onTap(index);
          }
          // Navigate to ChatSessionScreen if chat bubble (index 1) is tapped
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChatSessionScreen(),
              ),
            );
          } else {
            onTap(index);
          }
          
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF8C42) : Colors.transparent, // Orange for active
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }
}