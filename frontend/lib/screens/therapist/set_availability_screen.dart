import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SetAvailabilityScreen extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const SetAvailabilityScreen({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends State<SetAvailabilityScreen> {
  final List<Map<String, TimeOfDay>> _timeSlots = [];
  bool _applyToAllThursdays = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAvailability();
  }

  Future<void> _loadExistingAvailability() async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      final response = await http.get(
        Uri.parse('$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final availabilitySlots = data['availability_slots'] as List? ?? [];

        if (availabilitySlots.isNotEmpty) {
          setState(() {
            _timeSlots.clear();
            bool isRecurring = false;
            for (var slot in availabilitySlots) {
              final startTime = _parseTimeString(slot['start_time']);
              final endTime = _parseTimeString(slot['end_time']);
              _timeSlots.add({'from': startTime, 'to': endTime});
              // Check if it's a recurring availability (availability_date is null)
              if (slot['availability_date'] == null) {
                isRecurring = true;
              }
            }
            _applyToAllThursdays = isRecurring;
          });
        }
        // If no existing availability, don't add default slot - let user add manually
      }
    } catch (e) {
      // If loading fails, don't add default slot - let user add manually
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    // Parse "09:00 AM" or "02:30 PM" format
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    var hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1].toUpperCase() == 'PM';

    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add({
        'from': const TimeOfDay(hour: 14, minute: 0),
        'to': const TimeOfDay(hour: 17, minute: 0),
      });
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _selectTime(int index, String type) async {
    final initialTime =
        _timeSlots[index][type] ?? const TimeOfDay(hour: 9, minute: 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _timeSlots[index][type] = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getDayOfWeek() {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[widget.selectedDate.weekday - 1];
  }

  Future<void> _saveAvailability() async {
    // Check if there are any time slots
    if (_timeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one time slot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

      final slots = _timeSlots
          .map(
            (slot) => {
              'start_time': _formatTimeOfDay(slot['from']!),
              'end_time': _formatTimeOfDay(slot['to']!),
            },
          )
          .toList();

      if (_applyToAllThursdays) {
        // Apply to all same day of week in the month
        await _applyToAllDaysInMonth(apiUrl, slots);
      } else {
        // Apply to single date only
        final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
        await _saveSingleDate(apiUrl, slots, dateStr);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _applyToAllThursdays
                  ? 'Availability saved for all ${_getDayName()}s this month'
                  : 'Availability saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to schedule
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveSingleDate(
    String apiUrl,
    List<Map<String, dynamic>> slots,
    String dateStr,
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl/therapist/availability'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.userId,
        'day_of_week': _getDayOfWeek(),
        'slots': slots,
        'is_available': true,
        'availability_date': dateStr,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save availability: ${response.body}');
    }
  }

  Future<void> _applyToAllDaysInMonth(
    String apiUrl,
    List<Map<String, dynamic>> slots,
  ) async {
    final targetDayOfWeek = widget.selectedDate.weekday;
    final year = widget.selectedDate.year;
    final month = widget.selectedDate.month;

    // Get last day of the month
    final lastDay = DateTime(year, month + 1, 0);

    // Find all dates with matching day of week in this month
    final datesToApply = <DateTime>[];
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday == targetDayOfWeek) {
        datesToApply.add(date);
      }
    }

    // Save availability for each matching date
    for (final date in datesToApply) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      await _saveSingleDate(apiUrl, slots, dateStr);
    }
  }

  String _getDayName() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[widget.selectedDate.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dayName = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][widget.selectedDate.weekday - 1];
    final monthName = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][widget.selectedDate.month - 1];

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
                        'Set Availability',
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
                  // Editing Date
                  Container(
                    width: double.infinity,
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
                      children: [
                        const Text(
                          'Editing for:',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(107, 114, 128, 1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dayName, $monthName ${widget.selectedDate.day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(249, 115, 22, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Available Hours Label
                  const Text(
                    'Available Hours',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Slots or Empty State
                  if (_timeSlots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromRGBO(229, 231, 235, 1),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'No time slots added. Click "Add Time Slot" below to start.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(107, 114, 128, 1),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Time Slots
                  ..._timeSlots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;

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
                          // From Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    color: Color.fromRGBO(107, 114, 128, 1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectTime(index, 'from'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color.fromRGBO(
                                          229,
                                          231,
                                          235,
                                          1,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatTimeOfDay(slot['from']!),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(66, 32, 6, 1),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Color.fromRGBO(
                                            107,
                                            114,
                                            128,
                                            1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // To Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Nunito',
                                    color: Color.fromRGBO(107, 114, 128, 1),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectTime(index, 'to'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color.fromRGBO(
                                          229,
                                          231,
                                          235,
                                          1,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatTimeOfDay(slot['to']!),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(66, 32, 6, 1),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Color.fromRGBO(
                                            107,
                                            114,
                                            128,
                                            1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeTimeSlot(index),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add Time Slot Button
                  GestureDetector(
                    onTap: _addTimeSlot,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(243, 244, 246, 1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromRGBO(229, 231, 235, 1),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color.fromRGBO(66, 32, 6, 1)),
                          SizedBox(width: 8),
                          Text(
                            'Add Time Slot',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                              color: Color.fromRGBO(66, 32, 6, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recurring Option
                  const Text(
                    'Recurring',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                                'Apply to all ${dayName}s in ${monthName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w600,
                                  color: Color.fromRGBO(66, 32, 6, 1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set this time for every $dayName this month.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(107, 114, 128, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: _applyToAllThursdays,
                          onChanged: (value) {
                            setState(() {
                              _applyToAllThursdays = value ?? false;
                            });
                          },
                          activeColor: const Color.fromRGBO(249, 115, 22, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveAvailability,
                      child: const Text(
                        'Save Availability',
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
    );
  }
}
