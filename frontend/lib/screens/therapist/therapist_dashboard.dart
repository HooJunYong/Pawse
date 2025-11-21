import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'manage_schedule_screen.dart';

class TherapistDashboard extends StatefulWidget {
  final String userId;
  
  const TherapistDashboard({super.key, required this.userId});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  List<Map<String, dynamic>> _todaysAppointments = [];
  List<Map<String, dynamic>> _upcomingAvailability = [];
  String _therapistName = 'Dr. Therapist';
  bool _isLoading = true;
  int _selectedIndex = 0;

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
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
      print('Loading dashboard from: $apiUrl/therapist/dashboard/${widget.userId}');
      
      final response = await http.get(
        Uri.parse('$apiUrl/therapist/dashboard/${widget.userId}'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _therapistName = data['therapist_name'] ?? 'Dr. Therapist';
          _todaysAppointments = List<Map<String, dynamic>>.from(
            data['today_appointments'] ?? []
          );
          _upcomingAvailability = List<Map<String, dynamic>>.from(
            data['upcoming_availability'] ?? []
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load dashboard: ${response.statusCode} - ${response.body}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 375,
                    padding: const EdgeInsets.all(24),
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
                            fontSize: 14,
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments scheduled for today',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _todaysAppointments.map((appointment) => Container(
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
                      SizedBox(
                        width: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment['time'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(249, 115, 22, 1),
                              ),
                            ),
                            Text(
                              appointment['period'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Nunito',
                                color: Color.fromRGBO(107, 114, 128, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(66, 32, 6, 1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appointment['session'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                color: Color.fromRGBO(107, 114, 128, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                      ),
                const SizedBox(height: 32),

                // Quick Actions
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
                          // Navigate to profile edit
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Upcoming Scheduled Days
                if (_upcomingAvailability.isNotEmpty) ...[
                  const Text(
                    'Upcoming Scheduled Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._upcomingAvailability.map((availability) => 
                    _buildAvailabilityCard(availability)
                  ),
                ],
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
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavIcon(Icons.home, 0, true),
                _buildNavIcon(Icons.chat_bubble_outline, 1, false),
                _buildNavIcon(Icons.calendar_today_outlined, 2, false),
                _buildNavIcon(Icons.person_outline, 3, false),
              ],
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

  Widget _buildAvailabilityCard(Map<String, dynamic> availability) {
    final date = availability['date'] as String;
    final dayName = availability['day_name'] as String;
    final slots = availability['slots'] as List;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      color: Color.fromRGBO(107, 114, 128, 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...slots.map((slot) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color.fromRGBO(249, 115, 22, 1),
                ),
                const SizedBox(width: 8),
                Text(
                  '${slot['start_time']} - ${slot['end_time']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: const Color.fromRGBO(249, 115, 22, 1),
                  onPressed: () => _editAvailabilitySlot(slot['availability_id'], slot),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  onPressed: () => _deleteAvailabilitySlot(slot['availability_id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Future<void> _editAvailabilitySlot(String availabilityId, Map<String, dynamic> slot) async {
    final startController = TextEditingController(text: slot['start_time']);
    final endController = TextEditingController(text: slot['end_time']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Availability'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'Start Time (HH:MM AM/PM)',
                hintText: '09:00 AM',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'End Time (HH:MM AM/PM)',
                hintText: '05:00 PM',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
        final response = await http.put(
          Uri.parse('$apiUrl/therapist/availability/$availabilityId?user_id=${widget.userId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'start_time': startController.text,
            'end_time': endController.text,
          }),
        );

        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability updated successfully')),
          );
          _loadDashboardData(); // Reload data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAvailabilitySlot(String availabilityId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Availability'),
        content: const Text('Are you sure you want to delete this availability slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
        final response = await http.delete(
          Uri.parse('$apiUrl/therapist/availability/$availabilityId?user_id=${widget.userId}'),
        );

        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability deleted successfully')),
          );
          _loadDashboardData(); // Reload data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildNavIcon(IconData icon, int index, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          // Calendar icon - navigate to manage schedule
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageScheduleScreen(
                userId: widget.userId,
              ),
            ),
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? const Color.fromRGBO(249, 115, 22, 1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color.fromRGBO(107, 114, 128, 1),
          size: 24,
        ),
      ),
    );
  }
}
