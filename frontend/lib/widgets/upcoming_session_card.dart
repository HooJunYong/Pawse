import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/booking_service.dart';

class UpcomingSessionCard extends StatelessWidget {
  final TherapySession? session;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onTap;

  const UpcomingSessionCard({
    super.key,
    this.session,
    this.isLoading = false,
    this.errorMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildCard(
        const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return _buildCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (session == null) {
      return _buildCard(
        Row(
          children: [
            const Icon(Icons.event_busy, color: Color(0xFF5D4037)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No upcoming sessions scheduled',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Book a session to see it here.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final TherapySession upcoming = session!;
    // Backend returns timezone-aware datetime, convert to local for display
    final DateTime scheduledLocal = upcoming.scheduledAt.toLocal();
    final String scheduleLabel = _formatScheduleLabel(scheduledLocal);
    final String initials = _initialsFromName(upcoming.therapistName);
    final String? photoUrl = upcoming.therapistProfilePictureUrl;

    return _buildCard(
      Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF97316).withOpacity(0.6),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFFFF8E1),
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upcoming.therapistName.isNotEmpty ? upcoming.therapistName : 'Therapist',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scheduleLabel,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(upcoming.durationMinutes),
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Widget child) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    
    final hours = minutes / 60;
    if (minutes % 60 == 0) {
      return '${hours.toInt()} ${hours == 1 ? 'hour' : 'hours'}';
    }
    
    return '${hours.toStringAsFixed(1)} hours';
  }

  /// Generate a friendly schedule label based on proximity to today.
  String _formatScheduleLabel(DateTime scheduled) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime sessionDate = DateTime(scheduled.year, scheduled.month, scheduled.day);

    if (sessionDate == today) {
      return 'Today, ${DateFormat.jm().format(scheduled)}';
    }

    final DateTime tomorrow = today.add(const Duration(days: 1));
    if (sessionDate == tomorrow) {
      return 'Tomorrow, ${DateFormat.jm().format(scheduled)}';
    }

    final int adjustedWeekday = now.weekday % 7; // Sunday => 0, Monday => 1 ...
    final DateTime startOfWeek = today.subtract(Duration(days: adjustedWeekday));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    if (!sessionDate.isBefore(startOfWeek) && !sessionDate.isAfter(endOfWeek)) {
      return '${DateFormat('EEEE').format(scheduled)}, ${DateFormat.jm().format(scheduled)}';
    }

    return DateFormat('d MMM yyyy, h:mm a').format(scheduled);
  }

  String _initialsFromName(String name) {
    if (name.trim().isEmpty) {
      return 'TH';
    }

    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
