import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            icon: Icons.chat_bubble_outline,
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          _buildNavItem(
            icon: Icons.calendar_today,
            index: 2,
            isSelected: selectedIndex == 2,
          ),
          _buildNavItem(
            icon: Icons.close,
            index: 3,
            isSelected: selectedIndex == 3,
          ),
          _buildNavItem(
            icon: Icons.spa_outlined,
            index: 4,
            isSelected: selectedIndex == 4,
          ),
          _buildNavItem(
            icon: Icons.person,
            index: 5,
            isSelected: selectedIndex == 5,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE67E22) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black87,
          size: 26,
        ),
      ),
    );
  }
}