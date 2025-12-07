import 'package:flutter/material.dart';

import '../screens/chat/chat_contacts_screen.dart';
import '../screens/therapist/manage_schedule_screen.dart';
import '../screens/therapist/therapist_dashboard_screen.dart';
import '../screens/therapist/therapist_profile_screen.dart';

/// Describes the available tabs in the therapist experience bottom navigation.
enum TherapistNavTab { dashboard, chat, schedule, profile }

/// Shared bottom navigation bar for therapist-facing screens.
///
/// Displays four navigation icons (home, chat, calendar, profile) with
/// consistent styling and handles navigation between the core therapist
/// screens. Provide the [currentTab] to highlight the active destination and
/// optionally supply [unreadCount] to surface unread chat messages.
class TherapistBottomNavigation extends StatelessWidget {
  const TherapistBottomNavigation({
    super.key,
    required this.userId,
    required this.currentTab,
    this.unreadCount = 0,
  });

  final String userId;
  final TherapistNavTab currentTab;
  final int unreadCount;

  static const Color _accentOrange = Color(0xFFFB923C);
  static const Color _inactiveIconColor = Color.fromRGBO(107, 114, 128, 1);
  static const double _navWidth = 375;

  void _handleTap(BuildContext context, TherapistNavTab tab) {
    if (tab == currentTab) {
      return;
    }

    Widget destination;
    switch (tab) {
      case TherapistNavTab.dashboard:
        destination = TherapistDashboardScreen(userId: userId);
        break;
      case TherapistNavTab.chat:
        destination = ChatContactsScreen(
          currentUserId: userId,
          isTherapist: true,
        );
        break;
      case TherapistNavTab.schedule:
        destination = ManageScheduleScreen(userId: userId);
        break;
      case TherapistNavTab.profile:
        destination = TherapistProfileScreen(userId: userId);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: _navWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    tab: TherapistNavTab.dashboard,
                    icon: Icons.home_outlined,
                  ),
                  _buildNavItem(
                    context,
                    tab: TherapistNavTab.chat,
                    icon: Icons.chat_bubble_outline,
                    badgeCount: unreadCount,
                  ),
                  _buildNavItem(
                    context,
                    tab: TherapistNavTab.schedule,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _buildNavItem(
                    context,
                    tab: TherapistNavTab.profile,
                    icon: Icons.person,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required TherapistNavTab tab,
    required IconData icon,
    int? badgeCount,
  }) {
    final bool isActive = currentTab == tab;

    final Widget iconButton = IconButton(
      icon: Icon(icon),
      color: isActive ? Colors.white : _inactiveIconColor,
      onPressed: () => _handleTap(context, tab),
    );

    Widget decorated = isActive
        ? Container(
            decoration: BoxDecoration(
              color: _accentOrange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: iconButton,
          )
        : iconButton;

    if (badgeCount != null && badgeCount > 0 && tab == TherapistNavTab.chat) {
      decorated = Stack(
        clipBehavior: Clip.none,
        children: [
          decorated,
          Positioned(
            right: isActive ? -2 : -6,
            top: isActive ? -6 : -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
        ],
      );
    }

    return decorated;
  }
}
