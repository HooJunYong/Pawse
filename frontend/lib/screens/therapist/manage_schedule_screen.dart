import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'set_availability_screen.dart';

class ManageScheduleScreen extends StatefulWidget {
  final String userId;

  const ManageScheduleScreen({super.key, required this.userId});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _availabilitySlots = [];
  Set<String> _datesWithSchedule =
      {}; // Track dates with availability or sessions
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _loadMonthSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final response = await http.get(
        Uri.parse('$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sessions = (data['sessions'] as List).cast<Map<String, dynamic>>();
          _availabilitySlots = (data['availability_slots'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _sessions = [];
          _availabilitySlots = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _sessions = [];
        _availabilitySlots = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMonthSchedule() async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      final scheduledDates = <String>{};

      // Check each day in the month
      for (int day = 1; day <= lastDay.day; day++) {
        final checkDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          day,
        );
        final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);

        final response = await http.get(
          Uri.parse(
            '$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final sessions = data['sessions'] as List? ?? [];
          final availability = data['availability_slots'] as List? ?? [];

          if (sessions.isNotEmpty || availability.isNotEmpty) {
            scheduledDates.add(dateStr);
          }
        }
      }

      setState(() {
        _datesWithSchedule = scheduledDates;
      });
    } catch (e) {
      // Silently fail - calendar will still work without highlighting
    }
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + direction,
        _selectedDate.day,
      );
    });
    _loadMonthSchedule(); // Reload month data when changing months
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadSchedule();
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Manage Schedule',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Calendar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        // Month Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _changeMonth(-1),
                              color: const Color.fromRGBO(66, 32, 6, 1),
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(66, 32, 6, 1),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _changeMonth(1),
                              color: const Color.fromRGBO(66, 32, 6, 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Day Labels
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                          ), // 👈 adjust the padding you want
                          child: Row(
                            children: [
                              ...['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map(
                                (day) => Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        day,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w600,
                                          color: Color.fromRGBO(
                                            107,
                                            114,
                                            128,
                                            1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        // Calendar Grid
                        _buildCalendarGrid(),
                        const SizedBox(height: 16),
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      249,
                                      115,
                                      22,
                                      0.2,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                        249,
                                        115,
                                        22,
                                        0.5,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Has Schedule',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Nunito',
                                    color: Color.fromRGBO(107, 114, 128, 1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color.fromRGBO(249, 115, 22, 1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Selected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Nunito',
                                    color: Color.fromRGBO(107, 114, 128, 1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's Schedule Header
                  Text(
                    "Today's Schedule (${DateFormat('MMM d').format(_selectedDate)})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sessions List (includes booked sessions and available slots)
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromRGBO(249, 115, 22, 1),
                      ),
                    )
                  else if (_sessions.isEmpty && _availabilitySlots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No schedule set for this day',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(107, 114, 128, 1),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Show booked sessions
                    ..._sessions.map((session) => _buildSessionCard(session)),
                    // Show available time slots
                    ..._availabilitySlots.map(
                      (slot) => _buildAvailabilityCard(slot),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Set Availability Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(249, 115, 22, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetAvailabilityScreen(
                              userId: widget.userId,
                              selectedDate: _selectedDate,
                            ),
                          ),
                        );
                        // Reload schedule after returning
                        _loadSchedule();
                      },
                      child: const Text(
                        'Set Availability',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Block out times you're unavailable.",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Nunito',
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final List<Widget> dayWidgets = [];

    // Add empty cells for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 32, height: 32));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final isSelected =
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday =
          date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      final hasSchedule = _datesWithSchedule.contains(dateStr);

      dayWidgets.add(
        GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromRGBO(249, 115, 22, 1)
                  : hasSchedule
                  ? const Color.fromRGBO(249, 115, 22, 0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: hasSchedule && !isSelected
                  ? Border.all(
                      color: const Color.fromRGBO(249, 115, 22, 0.5),
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : hasSchedule
                      ? const Color.fromRGBO(249, 115, 22, 1)
                      : const Color.fromRGBO(66, 32, 6, 1),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: dayWidgets);
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final scheduledAt = DateTime.parse(session['scheduled_at']);
    final startTime = DateFormat('h:mm').format(scheduledAt);
    final endTime = DateFormat('h:mm a').format(
      scheduledAt.add(Duration(minutes: session['duration_minutes'] ?? 50)),
    );

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(249, 115, 22, 1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session['client_name'] ?? 'Unknown Client',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                Text(
                  'Session with ${session['client_name']?.split(' ').first ?? 'Client'}',
                  style: const TextStyle(
                    fontSize: 12,
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
  }

  Widget _buildAvailabilityCard(Map<String, dynamic> slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(249, 115, 22, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(249, 115, 22, 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Color.fromRGBO(249, 115, 22, 1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot['start_time']} - ${slot['end_time']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available for booking',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!, width: 1),
            ),
            child: Text(
              'Available',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Nunito',
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAvailabilitySlot() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetAvailabilityScreen(
          userId: widget.userId,
          selectedDate: _selectedDate,
        ),
      ),
    );
    // Reload schedule after returning
    _loadSchedule();
    _loadMonthSchedule();
  }
}
