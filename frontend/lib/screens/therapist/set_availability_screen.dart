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
  // Sort slots chronologically so locked entries remain in place.
  void _sortTimeSlots() {
    _timeSlots.sort((a, b) {
      final TimeOfDay aFrom = a['from'] as TimeOfDay;
      final TimeOfDay bFrom = b['from'] as TimeOfDay;
      final int aMinutes = aFrom.hour * 60 + aFrom.minute;
      final int bMinutes = bFrom.hour * 60 + bFrom.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  static const List<Map<String, int>> _recommendedSlotTemplates = [
    {
      'startHour': 10,
      'startMinute': 0,
      'endHour': 12,
      'endMinute': 0,
    },
    {
      'startHour': 14,
      'startMinute': 0,
      'endHour': 16,
      'endMinute': 0,
    },
    {
      'startHour': 16,
      'startMinute': 0,
      'endHour': 18,
      'endMinute': 0,
    },
  ];

  String _slotKey(TimeOfDay from, TimeOfDay to) {
    return '${from.hour}:${from.minute}-${to.hour}:${to.minute}';
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Map<String, dynamic>? _buildRecommendedSlot(
    Set<String> usedKeys,
    bool isToday,
    int nowMinutes,
  ) {
    for (final template in _recommendedSlotTemplates) {
      final from = TimeOfDay(
        hour: template['startHour']!,
        minute: template['startMinute']!,
      );
      final to = TimeOfDay(
        hour: template['endHour']!,
        minute: template['endMinute']!,
      );
      final key = _slotKey(from, to);
      final startMinutes = from.hour * 60 + from.minute;
      if (isToday && startMinutes < nowMinutes) {
        continue;
      }
      if (!usedKeys.contains(key)) {
        return {
          'from': from,
          'to': to,
          'locked': false,
          'lockReason': null,
        };
      }
    }
    return null;
  }

  Map<String, dynamic> _buildNextAvailableSlot(
    Set<String> usedKeys,
    bool isToday,
    int nowMinutes,
  ) {
    final int minStartHour;
    if (isToday) {
      minStartHour = ((nowMinutes + 59) ~/ 60).clamp(8, 20);
    } else {
      minStartHour = 8;
    }

    for (int startHour = minStartHour; startHour <= 20; startHour++) {
      if (isToday && (startHour * 60) < nowMinutes) {
        continue;
      }
      final endHour = startHour + 2;
      if (endHour > 22) {
        break;
      }
      final from = TimeOfDay(hour: startHour, minute: 0);
      final to = TimeOfDay(hour: endHour, minute: 0);
      final key = _slotKey(from, to);
      if (!usedKeys.contains(key)) {
        return {
          'from': from,
          'to': to,
          'locked': false,
          'lockReason': null,
        };
      }
    }

    // Fall back to the next two-hour window starting from now/today or default morning slot.
    if (isToday) {
      int startHour = (nowMinutes ~/ 60);
      int startMinute = nowMinutes % 60;
      if (startHour < 8) {
        startHour = 8;
      }
      if (startHour > 23) {
        startHour = 23;
        if (startMinute < 0) {
          startMinute = 0;
        } else if (startMinute > 59) {
          startMinute = 59;
        }
      }

      int endHour = startHour + 2;
      int endMinute = startMinute;
      if (endHour > 23) {
        endHour = 23;
        endMinute = 59;
        if (startHour == endHour && endMinute <= startMinute) {
          startMinute = (startMinute > 0) ? startMinute - 1 : 0;
        }
      }
      return {
        'from': TimeOfDay(hour: startHour, minute: startMinute),
        'to': TimeOfDay(hour: endHour, minute: endMinute),
        'locked': false,
        'lockReason': null,
      };
    }

    return {
      'from': const TimeOfDay(hour: 10, minute: 0),
      'to': const TimeOfDay(hour: 12, minute: 0),
      'locked': false,
      'lockReason': null,
    };
  }

  final List<Map<String, dynamic>> _timeSlots = [];
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
          final DateTime today = DateUtils.dateOnly(DateTime.now());
          final DateTime selectedDateOnly = DateUtils.dateOnly(widget.selectedDate);
          final bool isToday = DateUtils.isSameDay(selectedDateOnly, today);
          final bool isPastDate = selectedDateOnly.isBefore(today);
          final int nowMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
          setState(() {
            _timeSlots.clear();
            bool isRecurring = false;
            for (var slot in availabilitySlots) {
              final startTime = _parseTimeString(slot['start_time']);
              final endTime = _parseTimeString(slot['end_time']);
              final List<dynamic> statusCandidates = [
                slot['booked_session_status'],
                slot['session_status'],
                slot['booking_status'],
                slot['status'],
                slot['slot_status'],
              ];
              final dynamic rawStatusValue = statusCandidates.firstWhere(
                (value) => value != null && value.toString().isNotEmpty,
                orElse: () => '',
              );
              final String statusLower = rawStatusValue.toString().toLowerCase();
              final bool isReleased =
                  slot['slot_released'] == true || slot['is_released'] == true;
              final bool isExplicitlyBooked = statusLower.contains('book');
              final bool apiBookedFlag = slot['is_booked'] == true;
              final bool isBooked =
                !isReleased && !statusLower.contains('cancel') &&
                (apiBookedFlag || isExplicitlyBooked);
              final bool awaitingRelease =
                  statusLower.contains('cancel') && !isReleased;
              final bool isPastSlot = !isBooked && !awaitingRelease && !isReleased && (
                isPastDate || (isToday && _timeToMinutes(startTime) < nowMinutes)
              );
              final bool isLocked = isBooked || awaitingRelease || isReleased;

              _timeSlots.add({
                'from': startTime,
                'to': endTime,
                'locked': isLocked || isPastSlot,
                'lockReason': isBooked
                    ? 'booked'
                    : isReleased
                        ? 'released'
                        : awaitingRelease
                            ? 'cancelled'
                            : isPastSlot
                                ? 'past'
                                : null,
              });
              // Check if it's a recurring availability (availability_date is null)
              if (slot['availability_date'] == null) {
                isRecurring = true;
              }
            }
            _sortTimeSlots();
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
      final usedKeys = _timeSlots
          .map((slot) =>
              _slotKey(slot['from'] as TimeOfDay, slot['to'] as TimeOfDay))
          .toSet();
      final bool isToday =
          DateUtils.isSameDay(widget.selectedDate, DateTime.now());
      final int nowMinutes =
          TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
      final nextSlot = _buildRecommendedSlot(usedKeys, isToday, nowMinutes) ??
          _buildNextAvailableSlot(usedKeys, isToday, nowMinutes);
      nextSlot['lockReason'] = null;
      _timeSlots.add(nextSlot);
      _sortTimeSlots();
    });
  }

  void _removeTimeSlot(int index) {
    if (_timeSlots[index]['locked'] == true) {
      _showLockedSlotMessage(_timeSlots[index]['lockReason'] as String?);
      return;
    }
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _selectTime(int index, String type) async {
    if (_timeSlots[index]['locked'] == true) {
      _showLockedSlotMessage(_timeSlots[index]['lockReason'] as String?);
      return;
    }

    final TimeOfDay initialTime = _timeSlots[index][type] as TimeOfDay? ??
        const TimeOfDay(hour: 9, minute: 0);
    int hour = initialTime.hourOfPeriod == 0 ? 12 : initialTime.hourOfPeriod;
    int minute = initialTime.minute;
    bool isPM = initialTime.period == DayPeriod.pm;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              backgroundColor: const Color(0xFFF7F4F2),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select time',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xFF422006))),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up,
                                    size: 28),
                                onPressed: () {
                                  setState(() {
                                    hour = hour == 1 ? 12 : hour - 1;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                              Text('$hour',
                                  style: const TextStyle(
                                      fontSize: 36, color: Color(0xFF422006))),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 28),
                                onPressed: () {
                                  setState(() {
                                    hour = hour == 12 ? 1 : hour + 1;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Colon
                        const Text(':',
                            style: TextStyle(
                                fontSize: 36, color: Color(0xFF422006))),
                        const SizedBox(width: 12),
                        // Minute
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up,
                                    size: 28),
                                onPressed: () {
                                  setState(() {
                                    // Upper Click: -10 minutes (wrapping)
                                    minute = (minute - 10 + 60) % 60;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                              Text(minute.toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                      fontSize: 36, color: Color(0xFF422006))),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 28),
                                onPressed: () {
                                  setState(() {
                                    // Down Click: +10 minutes (wrapping)
                                    minute = (minute + 10) % 60;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // AM/PM toggle
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() {
                                isPM = false;
                              }),
                              child: Container(
                                width: 48,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !isPM
                                      ? const Color(0xFFF7F4F2)
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: const Color(0xFFBDBDBD)),
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6)),
                                ),
                                child: Text('AM',
                                    style: TextStyle(
                                        color: !isPM
                                            ? Colors.black
                                            : Colors.black54,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                isPM = true;
                              }),
                              child: Container(
                                width: 48,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isPM
                                      ? const Color(0xFFFFE4EA)
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: const Color(0xFFBDBDBD)),
                                  borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(6),
                                      bottomRight: Radius.circular(6)),
                                ),
                                child: Text('PM',
                                    style: TextStyle(
                                        color:
                                            isPM ? Colors.black : Colors.black54,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            int saveHour = hour % 12;
                            if (isPM) saveHour += 12;
                            if (!isPM && saveHour == 12) saveHour = 0;
                            Navigator.pop(context,
                                TimeOfDay(hour: saveHour, minute: minute));
                          },
                          child: const Text('OK'),
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
    ).then((picked) {
      if (picked != null && picked is TimeOfDay) {
        setState(() {
          _timeSlots[index][type] = picked;
          // If selecting 'from', auto-set 'to' to 2 hours after 'from'
          if (type == 'from') {
            final from = picked;
            int endHour = from.hour + 2;
            int endMinute = from.minute;
            if (endHour >= 24) {
              endHour = 23;
              endMinute = 59;
            }
            _timeSlots[index]['to'] =
                TimeOfDay(hour: endHour, minute: endMinute);
          }
          _sortTimeSlots();
        });
      }
    });
  }

  void _showLockedSlotMessage([String? reason]) {
    final String helperText;
    switch (reason) {
      case 'booked':
        helperText = 'Booked slots are managed automatically and cannot be edited.';
        break;
      case 'released':
        helperText = 'This slot was auto-released and stays locked to keep records consistent.';
        break;
      case 'cancelled':
        helperText = 'Cancelled slots awaiting release cannot be edited.';
        break;
      case 'past':
        helperText = 'Past slots are locked automatically and cannot be edited.';
        break;
      default:
        helperText = 'This slot is managed automatically and cannot be edited.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(helperText),
      ),
    );
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
    // Prevent setting slots in the past ONLY if selected date is today
    final isToday = DateUtils.isSameDay(widget.selectedDate, DateTime.now());
    
    if (isToday) {
      final now = TimeOfDay.now();
      final nowInMinutes = now.hour * 60 + now.minute;
      
      for (int i = 0; i < _timeSlots.length; i++) {
        // Skip locked slots (booked/released) - they don't need validation
        if (_timeSlots[i]['locked'] == true) {
          continue;
        }
        
        final TimeOfDay from = _timeSlots[i]['from'] as TimeOfDay;
        final fromInMinutes = from.hour * 60 + from.minute;
        
        // If the slot starts before now, show error
        if (fromInMinutes < nowInMinutes) {
          await showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: const Color(0xFFF7F4F2),
              child: SizedBox(
                width: 350,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invalid Time Slot',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF422006),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You cannot set a time slot that starts before the current time (${now.format(context)}).',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          color: Color(0xFF422006),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          return;
        }
      }
    }
    // Validate for overlapping/duplicate slots before saving
    bool hasOverlap = false;
    String? overlapMsg;
    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
    for (int i = 0; i < _timeSlots.length; i++) {
      final slotA = _timeSlots[i];
      final TimeOfDay fromTimeA = slotA['from'] as TimeOfDay;
      final TimeOfDay toTimeA = slotA['to'] as TimeOfDay;
      final fromA = toMinutes(fromTimeA);
      final toA = toMinutes(toTimeA);
      // Enforce max 2 hour duration
      if (toA - fromA > 120) {
        hasOverlap = true;
        overlapMsg = 'Each slot can be a maximum of 2 hours.';
        break;
      }
      if (fromA >= toA) {
        hasOverlap = true;
        overlapMsg =
            'The start time must be before the end time in all slots.';
        break;
      }
      for (int j = 0; j < _timeSlots.length; j++) {
        if (i == j) continue;
        final slotB = _timeSlots[j];
        final TimeOfDay fromTimeB = slotB['from'] as TimeOfDay;
        final TimeOfDay toTimeB = slotB['to'] as TimeOfDay;
        final fromB = toMinutes(fromTimeB);
        final toB = toMinutes(toTimeB);
        if (!(toA <= fromB || fromA >= toB)) {
          hasOverlap = true;
          overlapMsg =
              'Duplicate/Overlapping Slot: ${_formatTimeOfDay(fromTimeA)} - ${_formatTimeOfDay(toTimeA)} overlaps with ${_formatTimeOfDay(fromTimeB)} - ${_formatTimeOfDay(toTimeB)}.';
          break;
        }
      }
      if (hasOverlap) break;
    }
    if (hasOverlap) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFF7F4F2),
          child: SizedBox(
            width: 350,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invalid Slot',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF422006),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    overlapMsg ??
                        'This time slot overlaps with another slot. Please choose a different time.',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: Color(0xFF422006),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return;
    }
    // Show loading dialog
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
              'start_time': _formatTimeOfDay(slot['from'] as TimeOfDay),
              'end_time': _formatTimeOfDay(slot['to'] as TimeOfDay),
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
        Navigator.pop(context); // Close loading dialog

        final message = _timeSlots.isNotEmpty
            ? 'Availability saved successfully'
            : 'No Availability set for this date';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _applyToAllThursdays
                  ? 'Availability updated for all ${_getDayName()}s this month'
                  : message,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to schedule screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        String? errorMsg;
        try {
          final errStr = e.toString();
          final match =
              RegExp(r'\{"detail":\s*"([^"]+)"\}').firstMatch(errStr);
          if (match != null) {
            errorMsg = match.group(1);
          }
        } catch (_) {}
        await showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFFF7F4F2),
            child: SizedBox(
              width: 330,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error saving availability',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF422006),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMsg ?? e.toString(),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        color: Color(0xFF422006),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        'is_available': slots.isNotEmpty,
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                    final int index = entry.key;
                    final Map<String, dynamic> slot = entry.value;
                    final bool isLocked = slot['locked'] == true;
                    final TimeOfDay fromTime = slot['from'] as TimeOfDay;
                    final TimeOfDay toTime = slot['to'] as TimeOfDay;
                    final String lockReason =
                        (slot['lockReason'] as String?) ?? '';
                    final String lockMessage;
                    switch (lockReason) {
                      case 'booked':
                        lockMessage = 'Booked slot – edits disabled';
                        break;
                      case 'released':
                        lockMessage = 'Auto-released slot – edits disabled';
                        break;
                      case 'cancelled':
                        lockMessage =
                            'Cancelled slot – use "Set Available" on the dashboard.';
                        break;
                      case 'past':
                        lockMessage = 'Past slot – edits disabled';
                        break;
                      default:
                        lockMessage = 'Managed slot – edits disabled';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLocked ? const Color(0xFFF3F4F6) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isLocked
                            ? Border.all(color: const Color(0xFFCBD5F5))
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isLocked ? 0.02 : 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLocked)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lock,
                                    size: 16, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    lockMessage,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Nunito',
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (isLocked) const SizedBox(height: 12),
                          Row(
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
                                      onTap: isLocked
                                          ? null
                                          : () => _selectTime(index, 'from'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isLocked
                                              ? const Color(0xFFE5E7EB)
                                              : null,
                                          border: Border.all(
                                            color: const Color.fromRGBO(
                                                229, 231, 235, 1),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatTimeOfDay(fromTime),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Nunito',
                                                fontWeight: FontWeight.w600,
                                                color: isLocked
                                                    ? const Color(0xFF4B5563)
                                                    : const Color.fromRGBO(
                                                        66, 32, 6, 1),
                                              ),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              size: 18,
                                              color: isLocked
                                                  ? const Color(0xFF9CA3AF)
                                                  : const Color.fromRGBO(
                                                      107, 114, 128, 1),
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
                                      onTap: isLocked
                                          ? null
                                          : () => _selectTime(index, 'to'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isLocked
                                              ? const Color(0xFFE5E7EB)
                                              : null,
                                          border: Border.all(
                                            color: const Color.fromRGBO(
                                                229, 231, 235, 1),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatTimeOfDay(toTime),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Nunito',
                                                fontWeight: FontWeight.w600,
                                                color: isLocked
                                                    ? const Color(0xFF4B5563)
                                                    : const Color.fromRGBO(
                                                        66, 32, 6, 1),
                                              ),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              size: 18,
                                              color: isLocked
                                                  ? const Color(0xFF9CA3AF)
                                                  : const Color.fromRGBO(
                                                      107, 114, 128, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: isLocked
                                      ? const Color(0xFF9CA3AF)
                                      : Colors.red,
                                ),
                                onPressed: () {
                                  if (isLocked) {
                                    _showLockedSlotMessage();
                                  } else {
                                    _removeTimeSlot(index);
                                  }
                                },
                              ),
                            ],
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