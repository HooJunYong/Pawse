import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/notification_manager.dart';
import '../../theme/shadows.dart';
import '../../widgets/bottom_nav.dart';
import '../auth/login_screen.dart';
import '../companion/customize_comp_screen.dart';
import '../companion/manage_companion_screen.dart';
import 'change_password_screen.dart';
import 'contact_us_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'join_therapist_screen.dart';
import 'notification_screen.dart';
import 'privacy_policy_screen.dart';

class Profile extends StatefulWidget {
  final String userId;
  const Profile({super.key, required this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<Map<String, dynamic>> _profileFuture;

  Widget _initialsCircle(String initials) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFED7AA),
        border: Border.all(color: const Color(0xFFF97316), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 40,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final resp = await http.get(Uri.parse('$apiUrl/profile/${widget.userId}'));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load profile (${resp.statusCode})');
  }

  Future<List<Map<String, dynamic>>> _fetchSessionHistory() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/booking/client/${widget.userId}'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = List<Map<String, dynamic>>.from(data['bookings'] ?? []);
        
        // Filter only completed and cancelled sessions
        final history = sessions.where((session) {
          final status = (session['status'] ?? '').toString().toLowerCase();
          return status == 'completed' || status.contains('cancel');
        }).toList();
        
        return history;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  DateTime? _parseMalaysiaDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      final parsed = DateTime.parse(isoString);
      if (parsed.isUtc) {
        return parsed.add(const Duration(hours: 8));
      }
      final utcEquivalent = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
      return utcEquivalent.add(const Duration(hours: 8));
    } catch (e) {
      print('Failed to parse session datetime: $e');
      return null;
    }
  }

  void _showSessionHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        return Container(
          height: maxHeight,
          decoration: const BoxDecoration(
            color: Color.fromRGBO(247, 244, 242, 1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        color: Color.fromRGBO(66, 32, 6, 1),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Session History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                        color: Color.fromRGBO(66, 32, 6, 1),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSessionHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromRGBO(66, 32, 6, 1),
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to load session history',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(66, 32, 6, 1),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final sessions = snapshot.data ?? [];
                      
                      if (sessions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 64,
                                color: Color.fromRGBO(66, 32, 6, 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No session history yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(66, 32, 6, 0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          return _buildSessionHistoryCard(sessions[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionHistoryCard(Map<String, dynamic> session) {
    final status = (session['status'] ?? '').toString().toLowerCase();
    final therapistName = 'Dr. ${session['therapist_name'] ?? 'Therapist'}';
    final scheduledAt = session['scheduled_at'] as String? ?? '';
    final rating = session['user_rating'];
    final feedback = session['user_feedback'];
    
    final dateTime = _parseMalaysiaDateTime(scheduledAt);
    final startTimeLabel = (session['start_time'] as String?)?.trim() ?? '';
    
    final dateStr = dateTime != null
        ? DateFormat('MMM dd, yyyy').format(dateTime)
        : 'N/A';
    final timeStr = startTimeLabel.isNotEmpty
        ? startTimeLabel
        : dateTime != null
            ? DateFormat('h:mm a').format(dateTime)
            : 'N/A';
    
    // Status styling
    Color statusColor;
    String statusLabel;
    if (status == 'completed') {
      statusColor = const Color(0xFF22C55E);
      statusLabel = 'Completed';
    } else if (status.contains('cancel')) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Cancelled';
    } else {
      statusColor = Colors.grey;
      statusLabel = status;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSessionDetailDialog(session),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Therapist name and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        therapistName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Nunito',
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date and time
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color.fromRGBO(107, 114, 128, 1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Nunito',
                        color: Color.fromRGBO(107, 114, 128, 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color.fromRGBO(107, 114, 128, 1),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Nunito',
                        color: Color.fromRGBO(107, 114, 128, 1),
                      ),
                    ),
                  ],
                ),
                // Rating section (only for completed sessions)
                if (status == 'completed') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (rating != null && rating > 0)
                    Row(
                      children: [
                        const Text(
                          'Your rating: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(107, 114, 128, 1),
                          ),
                        ),
                        ...List.generate(5, (index) {
                          final ratingValue = rating is int ? rating.toDouble() : (rating as double);
                          return Icon(
                            index < ratingValue.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 18,
                            color: const Color(0xFFFB923C),
                          );
                        }),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.star_border,
                          size: 16,
                          color: Color.fromRGBO(107, 114, 128, 1),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Not rated yet',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(107, 114, 128, 1),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionDetailDialog(Map<String, dynamic> session) {
    final status = (session['status'] ?? '').toString().toLowerCase();
    final therapistName = 'Dr. ${session['therapist_name'] ?? 'Therapist'}';
    final scheduledAt = session['scheduled_at'] as String? ?? '';
    final duration = session['duration_minutes'] ?? 50;
    final rating = session['user_rating'];
    final feedback = session['user_feedback'];
    final centerName = session['center_name'];
    final sessionType = session['session_type'] ?? 'in_person';
    
    final dateTime = _parseMalaysiaDateTime(scheduledAt);
    final startTimeLabel = (session['start_time'] as String?)?.trim() ?? '';
    
    final dateStr = dateTime != null
        ? DateFormat('MMMM dd, yyyy').format(dateTime)
        : 'N/A';
    final timeStr = startTimeLabel.isNotEmpty
        ? startTimeLabel
        : dateTime != null
            ? DateFormat('h:mm a').format(dateTime)
            : 'N/A';
    
    // Status styling
    Color statusColor;
    String statusLabel;
    if (status == 'completed') {
      statusColor = const Color(0xFF22C55E);
      statusLabel = 'Completed';
    } else if (status.contains('cancel')) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Cancelled';
    } else {
      statusColor = Colors.grey;
      statusLabel = status;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Session Details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(66, 32, 6, 1),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Nunito',
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Details
                  _buildDetailRow(Icons.person, 'Therapist', therapistName),
                  _buildDetailRow(Icons.calendar_today, 'Date', dateStr),
                  _buildDetailRow(Icons.access_time, 'Time', timeStr),
                  _buildDetailRow(Icons.timer, 'Duration', '$duration minutes'),
                  if (centerName != null && centerName.isNotEmpty)
                    _buildDetailRow(Icons.location_on, 'Center', centerName),
                  // Rating section
                  if (status == 'completed') ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                        color: Color.fromRGBO(66, 32, 6, 1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (rating != null && rating > 0) ...[
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final ratingValue = rating is int
                                ? rating.toDouble()
                                : (rating as double);
                            return Icon(
                              index < ratingValue.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 28,
                              color: const Color(0xFFFB923C),
                            );
                          }),
                        ],
                      ),
                      if (feedback != null && feedback.toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Feedback',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(107, 114, 128, 1),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                feedback.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(66, 32, 6, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_border,
                              size: 24,
                              color: Color.fromRGBO(107, 114, 128, 1),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'You haven\'t rated this session yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(107, 114, 128, 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(107, 114, 128, 1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kPillShadow,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color.fromRGBO(66, 32, 6, 1),
          size: 20,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color.fromRGBO(107, 114, 128, 1),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(40)),
                color: Color.fromRGBO(247, 244, 242, 1),
              ),
              padding: const EdgeInsets.all(32),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load profile',
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(66, 32, 6, 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _profileFuture = _fetchProfile());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }
                  final data = snapshot.data!;
                  final fullName = (data['full_name'] as String?) ?? 'User';
                  final initials = (data['initials'] as String?) ?? 'U';
                  final avatarUrl = data['avatar_url'] as String?;
                  final avatarBase64 = data['avatar_base64'] as String?;

                  Widget avatarWidget;
                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
                    avatarWidget = Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF97316),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFFED7AA),
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    );
                  } else if (avatarBase64 != null && avatarBase64.isNotEmpty) {
                    try {
                      final bytes = base64Decode(avatarBase64);
                      avatarWidget = Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF97316),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFFFED7AA),
                          backgroundImage: MemoryImage(bytes),
                        ),
                      );
                    } catch (_) {
                      avatarWidget = _initialsCircle(initials);
                    }
                  } else {
                    avatarWidget = _initialsCircle(initials);
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      avatarWidget,
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfile(userId: widget.userId),
                            ),
                          );
                          // Refresh profile data after returning from edit page
                          setState(() {
                            _profileFuture = _fetchProfile();
                          });
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationScreen(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Customize Your Companion',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomizeCompanionScreen(
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.pets,
                        title: 'Manage Your Companions',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ManageCompanionScreen(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChangePassword(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'Session History',
                        onTap: () {
                          _showSessionHistorySheet();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.email_outlined,
                        title: 'Contact Us',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactUsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.person_add_outlined,
                        title: 'Join as a Therapist',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  JoinTherapist(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: kButtonShadow,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color.fromRGBO(
                                66,
                                32,
                                6,
                                1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF422006),
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to logout?',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      color: Color(0xFF422006),
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFFF7F4F2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF422006),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Stop notification polling
                                        NotificationManager.instance.stopPolling();
                                        
                                        Navigator.pop(context);
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(builder: (context) => const LoginWidget()),
                                          (route) => false,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: const Color(0xFFF97316),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        userId: widget.userId,
        selectedIndex: 5, // Profile is at index 5
        onTap: (index) {
          // Handle navigation for other tabs if needed
        },
      ),
    );
  }
}
