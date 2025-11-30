import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import 'set_availability_screen.dart';
import 'therapist_dashboard_screen.dart';
import 'therapist_profile_screen.dart';

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
  Set<String> _datesWithSchedule = {};
  bool _isLoading = true;
  // int _selectedIndex = 2; // Calendar is selected by default
  final BookingService _bookingService = BookingService();

  Map<String, dynamic>? _findSessionById(String? sessionId) {
    if (sessionId == null) return null;
    try {
      return _sessions.firstWhere(
        (session) => (session['session_id'] ?? '') == sessionId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _promptCancelBookedSlot(Map<String, dynamic> slot) async {
    final String? sessionId = slot['booked_session_id'] as String?;
    final Map<String, dynamic>? session = _findSessionById(sessionId);
    if (sessionId == null || session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to locate the booked session for this slot.'),
        ),
      );
      return;
    }

    String? errorMessage;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2), // Light red
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), // Red
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cancel Session?',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Are you sure you want to cancel the session with ${session['client_name'] ?? 'the client'}?",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: Color(0xFF4B5563),
                        height: 1.5,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 20, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              foregroundColor: const Color(0xFF374151),
                            ),
                            child: const Text(
                              'Keep Booking',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setStateDialog(() {
                                      isSubmitting = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
                                      final response = await http.post(
                                        Uri.parse('$apiUrl/booking/cancel'),
                                        headers: {'Content-Type': 'application/json'},
                                        body: jsonEncode({
                                          'session_id': sessionId,
                                          'client_user_id': session['user_id'],
                                          'reason': 'Cancelled by therapist',
                                        }),
                                      );

                                      if (response.statusCode == 200) {
                                        Navigator.of(dialogContext).pop();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Booking cancelled successfully.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          await _loadSchedule();
                                          await _loadMonthSchedule();
                                        }
                                      } else {
                                        final Map<String, dynamic>? payload = response.body.isNotEmpty
                                            ? jsonDecode(response.body) as Map<String, dynamic>?
                                            : null;
                                        setStateDialog(() {
                                          isSubmitting = false;
                                          errorMessage = payload != null && payload['detail'] != null
                                              ? payload['detail'].toString()
                                              : 'Failed to cancel booking. Please try again.';
                                        });
                                      }
                                    } catch (e) {
                                      setStateDialog(() {
                                        isSubmitting = false;
                                        errorMessage = 'Failed to cancel booking: $e';
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Yes, Cancel',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper to parse time string like '01:00 PM' to TimeOfDay
  TimeOfDay _parseTimeString(String timeStr) {
    final time = timeStr.trim().toUpperCase();
    final isPM = time.contains('PM');
    final parts = time.replaceAll('AM', '').replaceAll('PM', '').split(':');
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1].split(' ')[0]);
    if (isPM && hour < 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _loadMonthSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Load schedule for the day (includes both sessions and availability)
      final scheduleResponse = await http.get(
        Uri.parse('$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'),
      );

      if (scheduleResponse.statusCode == 200) {
        final scheduleData = jsonDecode(scheduleResponse.body);
        final List<Map<String, dynamic>> sessions =
            List<Map<String, dynamic>>.from(
          scheduleData['sessions'] ?? [],
        );
        final List<Map<String, dynamic>> availabilitySlots =
            List<Map<String, dynamic>>.from(
          scheduleData['availability_slots'] ?? [],
        );

        for (final slot in availabilitySlots) {
          final String? bookedSessionId =
              (slot['booked_session_id'] ?? slot['session_id'])?.toString();
          if (bookedSessionId == null || bookedSessionId.isEmpty) {
            continue;
          }

          Map<String, dynamic>? session;
          try {
            session = sessions.firstWhere(
              (element) =>
                  (element['session_id'] ?? '').toString() == bookedSessionId,
            );
          } catch (_) {
            session = null;
          }
          if (session == null) {
            continue;
          }

          final String statusRaw =
              (session['session_status'] ?? session['status'] ?? '')
                  .toString()
                  .toLowerCase();
          bool slotReleased =
              session['slot_released'] == true ||
                  slot['slot_released'] == true ||
                  slot['is_released'] == true;

          if (statusRaw.contains('cancel') && !slotReleased) {
            final String? scheduledAtRaw = session['scheduled_at']?.toString();
            final DateTime? scheduledAt = scheduledAtRaw != null
                ? DateTime.tryParse(scheduledAtRaw)
                : null;
            if (scheduledAt != null &&
                scheduledAt.difference(DateTime.now()).inDays >= 5) {
              try {
                await _bookingService.releaseCancelledSessionSlot(
                  sessionId: bookedSessionId,
                  therapistUserId: widget.userId,
                );
                slotReleased = true;
              } catch (_) {}
            }
          }

          if (slotReleased) {
            slot['slot_released'] = true;
            slot['is_booked'] = false;
            slot['status'] = 'available';
            session['slot_released'] = true;
          }
        }

        if (mounted) {
          setState(() {
            _sessions = sessions;
            _availabilitySlots = availabilitySlots;
            _availabilitySlots.sort((a, b) {
              final aTime = _parseTimeString(a['start_time']);
              final bTime = _parseTimeString(b['start_time']);
              final aMinutes = aTime.hour * 60 + aTime.minute;
              final bMinutes = bTime.hour * 60 + bTime.minute;
              return aMinutes.compareTo(bMinutes);
            });
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _sessions = [];
          _availabilitySlots = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schedule: $e')));
      }
    }
  }

  Future<void> _loadMonthSchedule() async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final year = _selectedDate.year;
      final month = _selectedDate.month;

      final response = await http.get(
        Uri.parse(
          '$apiUrl/therapist/schedule/${widget.userId}/month?year=$year&month=$month',
        ),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final dates = List<String>.from(data['scheduled_dates'] ?? []);
        setState(() {
          _datesWithSchedule = dates.toSet();
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  void _changeMonth(int delta) {
    final DateTime newDate = DateTime(
      _selectedDate.year,
      _selectedDate.month + delta,
      1,
    );

    setState(() {
      _selectedDate = newDate;
    });

    _loadMonthSchedule();
    _loadSchedule();
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
                          padding: const EdgeInsets.only(left: 12),
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

                  // Sessions List
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
                    // Show available time slots (booked/available states rendered inside)
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
                      onPressed: _editAvailabilitySlot,
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
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Row(
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
                  // Home Button
                  IconButton(
                    icon: const Icon(Icons.home_outlined),
                    color: const Color.fromRGBO(107, 114, 128, 1),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TherapistDashboardScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  // Chat Button
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: const Color.fromRGBO(107, 114, 128, 1),
                    onPressed: () {
                      // Navigate to chat
                    },
                  ),
                  // Calendar Button (Active)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(249, 115, 22, 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      color: Colors.white,
                      onPressed: () {
                        // Already on schedule screen
                      },
                    ),
                  ),
                  // Profile Button
                  IconButton(
                    icon: const Icon(Icons.person),
                    color: const Color.fromRGBO(107, 114, 128, 1),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TherapistProfileScreen(userId: widget.userId),
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

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: dayWidgets),
    );
  }

  Widget _buildAvailabilityCard(Map<String, dynamic> slot) {
    final String rawStatus = (slot['booked_session_status'] ?? slot['status'] ?? '')
      .toString()
      .toLowerCase();
    final bool slotReleased = slot['slot_released'] == true || slot['is_released'] == true;
    final bool isCancelled = rawStatus.contains('cancel');
    final bool isBooked =
      slot['is_booked'] == true && !isCancelled && !slotReleased;
    final bool awaitingRelease = isCancelled && !slotReleased;

    final Color backgroundColor;
    final Color borderColor;
    final Color labelBackground;
    final Color labelBorder;
    final Color labelTextColor;
    final IconData statusIcon;
    final String statusLabel;
    final String subtitleText;

    if (awaitingRelease) {
      backgroundColor = const Color.fromRGBO(254, 226, 226, 1); // light red
      borderColor = const Color.fromRGBO(239, 68, 68, 0.4);
      labelBackground = const Color.fromRGBO(254, 202, 202, 1);
      labelBorder = const Color.fromRGBO(239, 68, 68, 0.5);
      labelTextColor = const Color.fromRGBO(185, 28, 28, 1);
      statusIcon = Icons.cancel_outlined;
      statusLabel = 'Cancelled';
      subtitleText = 'Tap "Set Available" on the dashboard to reopen.';
    } else if (isBooked) {
      backgroundColor = const Color.fromRGBO(59, 130, 246, 0.08);
      borderColor = const Color.fromRGBO(59, 130, 246, 0.3);
      labelBackground = const Color.fromRGBO(59, 130, 246, 0.12);
      labelBorder = const Color.fromRGBO(59, 130, 246, 0.3);
      labelTextColor = const Color.fromRGBO(30, 64, 175, 1);
      statusIcon = Icons.event_busy;
      statusLabel = 'Booked';
      subtitleText = 'Slot no longer available';
    } else {
      backgroundColor = const Color.fromRGBO(249, 115, 22, 0.1);
      borderColor = const Color.fromRGBO(249, 115, 22, 0.3);
      labelBackground = Colors.green[50]!;
      labelBorder = Colors.green[200]!;
      labelTextColor = Colors.green[700]!;
      statusIcon = Icons.schedule;
      statusLabel = 'Available';
      subtitleText = 'Available for booking';
    }

    final Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: awaitingRelease
              ? const Color.fromRGBO(185, 28, 28, 1)
              : isBooked
                ? const Color.fromRGBO(30, 64, 175, 1)
                : const Color.fromRGBO(249, 115, 22, 1),
          ),
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
                  subtitleText,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: awaitingRelease
                        ? const Color.fromRGBO(127, 29, 29, 1)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: labelBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: labelBorder, width: 1),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Nunito',
                color: labelTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (awaitingRelease || !isBooked) {
      return cardContent;
    }

    return GestureDetector(
      onTap: () => _promptCancelBookedSlot(slot),
      child: cardContent,
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
