import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'manage_schedule_screen.dart';
import 'therapist_profile_screen.dart';

class TherapistDashboardScreen extends StatefulWidget {
  final String userId;

  const TherapistDashboardScreen({super.key, required this.userId});

  @override
  State<TherapistDashboardScreen> createState() => _TherapistDashboardScreenState();
}

class _TherapistDashboardScreenState extends State<TherapistDashboardScreen> {
  List<Map<String, dynamic>> _todaysAppointments = [];
  List<Map<String, dynamic>> _upcomingSchedule = [];
  String _therapistName = '';
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      
      // Load therapist profile
      final profileResponse = await http.get(
        Uri.parse('$apiUrl/therapist/profile/${widget.userId}'),
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        setState(() {
          _therapistName = 'Dr. ${profileData['first_name']} ${profileData['last_name']}';
        });
      }

      // Load today's appointments (if you have this endpoint)
      // final appointmentsResponse = await http.get(
      //   Uri.parse('$apiUrl/therapist/appointments/today/${widget.userId}'),
      // );

      setState(() {
        _isLoading = false;
      });
      await _loadUpcomingSchedule();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<void> _loadUpcomingSchedule() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final List<Map<String, dynamic>> scheduleData = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 5; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
          final availabilitySlots = List<Map<String, dynamic>>.from(data['availability_slots'] ?? []);
          
          for (var slot in availabilitySlots) {
            bool isBooked = false;
            String? clientName;
            
            for (var session in sessions) {
              final sessionTime = DateTime.parse(session['scheduled_at']);
              final slotStart = _parseTimeWithDate(dateStr, slot['start_time']);
              if (sessionTime.isAtSameMomentAs(slotStart)) {
                isBooked = true;
                clientName = session['client_name'];
                break;
              }
            }
            
            scheduleData.add({
              'date': dateStr,
              'start_time': slot['start_time'],
              'end_time': slot['end_time'],
              'availability_id': slot['availability_id'],
              'is_booked': isBooked,
              'client_name': clientName,
            });
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    if (mounted) {
      setState(() {
        _upcomingSchedule = scheduleData;
      });
    }
  }

  DateTime _parseTimeWithDate(String dateStr, String timeStr) {
    try {
      final date = DateTime.parse(dateStr);
      final timeParts = timeStr.split(':');
      final hourStr = timeParts[0];
      final minutePart = timeParts[1].split(' ');
      final minuteStr = minutePart[0];
      
      int hour = int.parse(hourStr);
      final minute = int.parse(minuteStr);
      
      final isPM = timeStr.toLowerCase().contains('pm');
      if (isPM && hour < 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return DateTime.parse(dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromRGBO(247, 244, 242, 1),
        body: Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(249, 115, 22, 1),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Nunito',
                              color: Color.fromRGBO(107, 114, 128, 1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _therapistName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(66, 32, 6, 1),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Color.fromRGBO(66, 32, 6, 1),
                            size: 20,
                          ),
                          onPressed: () {
                            // Navigate to settings
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Today's Appointments
                  const Text(
                    "Today's Appointments",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Appointment Cards or Empty State
                  _todaysAppointments.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No appointments scheduled for today',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _todaysAppointments.map((appointment) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Time
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appointment['time'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(249, 115, 22, 1),
                                        ),
                                      ),
                                      Text(
                                        appointment['period'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Nunito',
                                          color: Color.fromRGBO(107, 114, 128, 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appointment['client_name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(66, 32, 6, 1),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          appointment['type'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Nunito',
                                            color: Color.fromRGBO(107, 114, 128, 1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 32),

                  // Quick Actions (moved up)
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.calendar_today,
                          label: 'Manage Schedule',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManageScheduleScreen(
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.person_outline,
                          label: 'Edit Profile',
                          color: const Color.fromRGBO(249, 115, 22, 1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TherapistProfileScreen(userId: widget.userId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Upcoming Schedule (Next 5 Days) - moved below Quick Actions
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Upcoming Schedule (Next 5 Days)',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(66, 32, 6, 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _upcomingSchedule.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No upcoming schedule',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Color.fromRGBO(107, 114, 128, 1),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _upcomingSchedule.map((schedule) {
                            final date = DateTime.parse(schedule['date']);
                            final dateStr = "${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][date.weekday%7]}, ${date.month}/${date.day}";
                            final isBooked = schedule['is_booked'] ?? false;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isBooked
                                      ? const Color.fromRGBO(34, 197, 94, 0.3)
                                      : const Color.fromRGBO(249, 115, 22, 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(66, 32, 6, 1),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${schedule['start_time']} - ${schedule['end_time']}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Nunito',
                                            color: Color.fromRGBO(107, 114, 128, 1),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isBooked
                                                    ? const Color.fromRGBO(34, 197, 94, 0.1)
                                                    : const Color.fromRGBO(249, 115, 22, 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isBooked ? 'Booked' : 'Available',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.w600,
                                                  color: isBooked
                                                      ? const Color.fromRGBO(34, 197, 94, 1)
                                                      : const Color.fromRGBO(249, 115, 22, 1),
                                                ),
                                              ),
                                            ),
                                            if (isBooked && schedule['client_name'] != null) ...[
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  '• ${schedule['client_name']}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'Nunito',
                                                    color: Color.fromRGBO(107, 114, 128, 1),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    color: const Color.fromRGBO(249, 115, 22, 1),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ManageScheduleScreen(userId: widget.userId),
                                        ),
                                      );
                                      await _loadUpcomingSchedule();
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 375,
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
                    // Home Button (Active)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(249, 115, 22, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.home_outlined),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                    // Chat Button
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {
                        // Navigate to chat
                      },
                    ),
                    // Calendar Button
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageScheduleScreen(
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                    // Profile Button
                    IconButton(
                      icon: const Icon(Icons.person),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TherapistProfileScreen(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (color ?? const Color.fromRGBO(249, 115, 22, 1)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color ?? const Color.fromRGBO(249, 115, 22, 1),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}