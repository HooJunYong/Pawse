import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'manage_schedule_screen.dart';
import 'therapist_profile_screen.dart';

class TherapistDashboardScreen extends StatefulWidget {
  final String userId;

  const TherapistDashboardScreen({super.key, required this.userId});

  @override
  State<TherapistDashboardScreen> createState() =>
      _TherapistDashboardScreenState();
}

class _TherapistDashboardScreenState extends State<TherapistDashboardScreen> {
  static const Color _accent = Color.fromRGBO(249, 115, 22, 1);
  static const Color _textPrimary = Color.fromRGBO(66, 32, 6, 1);
  static const Color _popupBg = Color.fromRGBO(
    247,
    244,
    242,
    1,
  ); // match profile
  static const Color _popupBorder = Color.fromRGBO(
    249,
    115,
    22,
    0.15,
  ); // subtle accent border
  static const double _popupRadius = 40.0; // match profile

  // ignore: unused_element
  Future<void> _showEditScheduleDialog(Map<String, dynamic> schedule) async {
    TimeOfDay selectedStartTime = _parseTimeOfDay(schedule['start_time']);
    TimeOfDay selectedEndTime = _parseTimeOfDay(schedule['end_time']);

    int startHour = selectedStartTime.hour;
    int startMinute = selectedStartTime.minute;
    int endHour = selectedEndTime.hour;
    int endMinute = selectedEndTime.minute;

    bool isSaving = false;
    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildTimePicker(
              String label,
              int hour,
              int minute,
              void Function(int, int) onChanged,
            ) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 110,
                    height: 128,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _popupBorder, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hour
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_up,
                                size: 28,
                              ),
                              onPressed: () {
                                int newHour = (hour - 1) < 0 ? 23 : hour - 1;
                                onChanged(newHour, minute);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Text(
                              hour.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: _textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 28,
                              ),
                              onPressed: () {
                                int newHour = (hour + 1) > 23 ? 0 : hour + 1;
                                onChanged(newHour, minute);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 18),
                        // Minute
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_up,
                                size: 28,
                              ),
                              onPressed: () {
                                int newMinute = (minute - 1) < 0
                                    ? 59
                                    : minute - 1;
                                onChanged(hour, newMinute);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Text(
                              minute.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: _textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 28,
                              ),
                              onPressed: () {
                                int newMinute = (minute + 1) > 59
                                    ? 0
                                    : minute + 1;
                                onChanged(hour, newMinute);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                width: 350,
                decoration: BoxDecoration(
                  color: _popupBg,
                  borderRadius: BorderRadius.circular(_popupRadius),
                  border: Border.all(color: _popupBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Edit Schedule',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildTimePicker('Start Time', startHour, startMinute, (
                          h,
                          m,
                        ) {
                          setState(() {
                            startHour = h;
                            startMinute = m;
                          });
                        }),
                        buildTimePicker('End Time', endHour, endMinute, (h, m) {
                          setState(() {
                            endHour = h;
                            endMinute = m;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (isSaving)
                      const Center(child: CircularProgressIndicator()),
                    if (!isSaving)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                              textStyle: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                isSaving = true;
                              });
                              final apiUrl =
                                  dotenv.env['API_BASE_URL'] ??
                                  'http://localhost:8000';
                              final availabilityId =
                                  schedule['availability_id'];
                              final userId = widget.userId;
                              final startTimeStr = TimeOfDay(
                                hour: startHour,
                                minute: startMinute,
                              ).format(context);
                              final endTimeStr = TimeOfDay(
                                hour: endHour,
                                minute: endMinute,
                              ).format(context);
                              try {
                                final response = await http.put(
                                  Uri.parse(
                                    '$apiUrl/therapist/availability/$availabilityId?user_id=$userId',
                                  ),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'start_time': startTimeStr,
                                    'end_time': endTimeStr,
                                  }),
                                );
                                if (response.statusCode == 200) {
                                  await _loadUpcomingSchedule();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Update successful'),
                                    ),
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Update failed: \\${response.body}',
                                      ),
                                    ),
                                  );
                                  setState(() {
                                    isSaving = false;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: \\${e.toString()}'),
                                  ),
                                );
                                setState(() {
                                  isSaving = false;
                                });
                              }
                            },
                            child: const Text('Save'),
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

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final time = timeStr.trim().toUpperCase();
    final isPM = time.contains('PM');
    final parts = time.replaceAll('AM', '').replaceAll('PM', '').split(':');
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1].split(' ')[0]);
    if (isPM && hour < 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  List<Map<String, dynamic>> _todaysAppointments = [];
  List<Map<String, dynamic>> _upcomingSchedule = [];
  String _therapistName = '';
  bool _isLoading = true;
  String? _activeCancelSessionId;
  Timer? _cancelButtonTimer;
  String? _statusUpdatingSessionId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _cancelButtonTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

      final profileResponse = await http.get(
        Uri.parse('$apiUrl/therapist/profile/${widget.userId}'),
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        if (mounted) {
          setState(() {
            _therapistName =
                'Dr. ${profileData['first_name']} ${profileData['last_name']}';
          });
        }
      }

      await Future.wait([_loadTodaysAppointments(), _loadUpcomingSchedule()]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodaysAppointments() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final today = DateTime.now();
    final dateStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = List<Map<String, dynamic>>.from(
          data['sessions'] ?? [],
        );

        sessions.sort((a, b) {
          final aTime = DateTime.parse(a['scheduled_at']);
          final bTime = DateTime.parse(b['scheduled_at']);
          return aTime.compareTo(bTime);
        });

        final todays = sessions.map((session) {
          final scheduledAt = DateTime.parse(session['scheduled_at']);
          final statusRaw =
              (session['session_status'] ?? session['status'] ?? 'scheduled')
                  .toString();
          final durationMinutes =
              int.tryParse(session['duration_minutes']?.toString() ?? '') ?? 50;
          final endAt = scheduledAt.add(Duration(minutes: durationMinutes));
          return {
            'session_id': session['session_id']?.toString() ?? '',
            'scheduled_at': scheduledAt.toIso8601String(),
            'end_at': endAt.toIso8601String(),
            'time': DateFormat('h:mm').format(scheduledAt),
            'period': DateFormat('a').format(scheduledAt),
            'client_name': session['client_name'] ?? 'Client',
            'status': statusRaw,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _todaysAppointments = todays;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _todaysAppointments = [];
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _todaysAppointments = [];
        });
      }
    }
  }

  Future<void> _loadUpcomingSchedule() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final List<Map<String, dynamic>> scheduleData = [];
    final now = DateTime.now();

    for (int i = 1; i <= 5; i++) {
      final date = now.add(Duration(days: i));
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      try {
        final response = await http.get(
          Uri.parse(
            '$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final sessions = List<Map<String, dynamic>>.from(
            data['sessions'] ?? [],
          );
          final availabilitySlots = List<Map<String, dynamic>>.from(
            data['availability_slots'] ?? [],
          );

          for (final slot in availabilitySlots) {
            String? sessionId;
            String? clientName;
            dynamic clientUserId;

            for (final session in sessions) {
              final sessionTime = DateTime.parse(session['scheduled_at']);
              final slotStart = _parseTimeWithDate(dateStr, slot['start_time']);
              if (sessionTime.isAtSameMomentAs(slotStart)) {
                sessionId = session['session_id']?.toString();
                clientName = session['client_name'];
                clientUserId = session['user_id'];
                break;
              }
            }

            if (sessionId != null && clientUserId != null) {
              scheduleData.add({
                'date': dateStr,
                'start_time': slot['start_time'],
                'end_time': slot['end_time'],
                'availability_id': slot['availability_id'],
                'is_booked': true,
                'client_name': clientName,
                'session_id': sessionId,
                'client_user_id': clientUserId,
              });
            }
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (!mounted) return;

    scheduleData.sort((a, b) {
      final dateA = _parseTimeWithDate(
        a['date'] as String,
        a['start_time'] as String,
      );
      final dateB = _parseTimeWithDate(
        b['date'] as String,
        b['start_time'] as String,
      );
      return dateA.compareTo(dateB);
    });

    setState(() {
      _upcomingSchedule = scheduleData;
      _activeCancelSessionId = null;
    });
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

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'no_show':
        return 'No-Show';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color.fromRGBO(22, 163, 74, 1);
      case 'no_show':
        return const Color.fromRGBO(220, 38, 38, 1);
      case 'cancelled':
        return const Color.fromRGBO(239, 68, 68, 1);
      default:
        return const Color.fromRGBO(37, 99, 235, 1);
    }
  }

  Future<void> _showCancelBookingDialog(Map<String, dynamic> schedule) async {
    final String? sessionId = schedule['session_id'] as String?;
    final dynamic clientUserId = schedule['client_user_id'];
    if (sessionId == null || clientUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to cancel this booking right now.'),
        ),
      );
      return;
    }

    final TextEditingController reasonController = TextEditingController();
    String? errorMessage;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF7F4F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Cancel Booking',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color.fromRGBO(66, 32, 6, 1),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let ${schedule['client_name'] ?? 'the client'} know why you need to cancel this session.",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Color.fromRGBO(66, 32, 6, 1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cancellation Reason',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color.fromRGBO(107, 114, 128, 1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            'Share a brief note about the cancellation...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Color.fromRGBO(156, 163, 175, 1),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(229, 231, 235, 1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(229, 231, 235, 1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(249, 115, 22, 1),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromRGBO(66, 32, 6, 1),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Keep Booking'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (reasonController.text.trim().isEmpty) {
                            setStateDialog(() {
                              errorMessage = 'Please provide a short reason.';
                            });
                            return;
                          }

                          setStateDialog(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          try {
                            final apiUrl =
                                dotenv.env['API_BASE_URL'] ??
                                'http://localhost:8000';
                            final response = await http.post(
                              Uri.parse('$apiUrl/booking/cancel'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'session_id': sessionId,
                                'client_user_id': clientUserId,
                                'reason': reasonController.text.trim(),
                              }),
                            );

                            if (response.statusCode == 200) {
                              Navigator.of(dialogContext).pop();
                              if (mounted) {
                                setState(() {
                                  _activeCancelSessionId = null;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Booking cancelled successfully.',
                                    ),
                                  ),
                                );
                                await _loadUpcomingSchedule();
                              }
                            } else {
                              final Map<String, dynamic>? payload =
                                  response.body.isNotEmpty
                                  ? jsonDecode(response.body)
                                        as Map<String, dynamic>?
                                  : null;
                              setStateDialog(() {
                                isSubmitting = false;
                                errorMessage =
                                    payload != null && payload['detail'] != null
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
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Cancel Session',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();
  }

  Future<void> _updateSessionStatus({
    required String sessionId,
    required String newStatus,
  }) async {
    if (sessionId.isEmpty) {
      return;
    }

    setState(() {
      _statusUpdatingSessionId = sessionId;
    });

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$apiUrl/booking/session/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'therapist_user_id': widget.userId,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session marked as ${_formatStatusLabel(newStatus)}.',
            ),
          ),
        );
        await _loadTodaysAppointments();
        await _loadUpcomingSchedule();
      } else {
        final Map<String, dynamic>? payload = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>?
            : null;
        final error = payload != null && payload['detail'] != null
            ? payload['detail'].toString()
            : 'Failed to update session status.';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating session: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _statusUpdatingSessionId = null;
        });
      }
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
                            final String sessionId =
                                appointment['session_id']?.toString() ?? '';
                            final String status =
                                appointment['status']?.toString() ??
                                'scheduled';
                            final String statusLabel = _formatStatusLabel(
                              status,
                            );
                            final Color statusColor = _statusColor(status);
                            final DateTime? endAt =
                                appointment['end_at'] != null
                                ? DateTime.tryParse(
                                    appointment['end_at'] as String,
                                  )
                                : null;
                            final bool isScheduled =
                                status.toLowerCase() == 'scheduled';
                            final bool canUpdate =
                                isScheduled &&
                                endAt != null &&
                                DateTime.now().isAfter(endAt);
                            final bool isUpdating =
                                _statusUpdatingSessionId == sessionId;

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Time
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appointment['time'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromRGBO(
                                                249,
                                                115,
                                                22,
                                                1,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            appointment['period'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Nunito',
                                              color: Color.fromRGBO(
                                                107,
                                                114,
                                                128,
                                                1,
                                              ),
                                            ),
                                          ),
                                          if (endAt != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                'Ends ${DateFormat('h:mm a').format(endAt)}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'Nunito',
                                                  color: Color.fromRGBO(
                                                    156,
                                                    163,
                                                    175,
                                                    1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appointment['client_name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'Nunito',
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromRGBO(
                                                  66,
                                                  32,
                                                  6,
                                                  1,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (canUpdate) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Update session outcome',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w600,
                                        color: Color.fromRGBO(66, 32, 6, 1),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (isUpdating)
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    if (!isUpdating)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                // CHANGED: Green color for Completed
                                                backgroundColor: const Color(
                                                  0xFF22C55E,
                                                ),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                              ),
                                              onPressed: () {
                                                _updateSessionStatus(
                                                  sessionId: sessionId,
                                                  newStatus: 'completed',
                                                );
                                              },
                                              child: const Text(
                                                'Completed', // CHANGED: Shortened text
                                                style: TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                // Kept Red color for No Show
                                                foregroundColor:
                                                    const Color.fromRGBO(
                                                      220,
                                                      38,
                                                      38,
                                                      1,
                                                    ),
                                                side: const BorderSide(
                                                  color: Color.fromRGBO(
                                                    220,
                                                    38,
                                                    38,
                                                    1,
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed: () {
                                                _updateSessionStatus(
                                                  sessionId: sessionId,
                                                  newStatus: 'no_show',
                                                );
                                              },
                                              child: const Text(
                                                'No Show', // CHANGED: Shortened text
                                                style: TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
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
                                builder: (context) =>
                                    ManageScheduleScreen(userId: widget.userId),
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
                                builder: (context) => TherapistProfileScreen(
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Upcoming Appointments (Next 5 Days) - moved below Quick Actions
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Upcoming Appointments (Next 5 Days)',
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
                              'No booked appointments yet',
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
                            const monthNames = [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec',
                            ];
                            const dayNames = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            final dateStr =
                                '${dayNames[date.weekday - 1]}, ${monthNames[date.month - 1]} ${date.day}';
                            final String? sessionId =
                                schedule['session_id'] as String?;
                            if (sessionId == null) {
                              return const SizedBox.shrink();
                            }
                            final bool revealCancel =
                                _activeCancelSessionId == sessionId;
                            final DateTime sessionDateTime = _parseTimeWithDate(
                              schedule['date'] as String,
                              schedule['start_time'] as String,
                            );
                            final int minutesUntilSession = sessionDateTime
                                .difference(DateTime.now())
                                .inMinutes;
                            final bool canCancel = minutesUntilSession >= 720;
                            final String? clientName =
                                schedule['client_name'] as String?;

                            return GestureDetector(
                              onTap: () {
                                _cancelButtonTimer?.cancel();
                                setState(() {
                                  _activeCancelSessionId = sessionId;
                                });
                                _cancelButtonTimer = Timer(
                                  const Duration(seconds: 5),
                                  () {
                                    if (mounted &&
                                        _activeCancelSessionId == sessionId) {
                                      setState(() {
                                        _activeCancelSessionId = null;
                                      });
                                    }
                                  },
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color.fromRGBO(
                                      34,
                                      197,
                                      94,
                                      0.28,
                                    ),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        revealCancel ? 0.08 : 0.04,
                                      ),
                                      blurRadius: revealCancel ? 14 : 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
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
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(
                                              34,
                                              197,
                                              94,
                                              0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: const Color.fromRGBO(
                                                34,
                                                197,
                                                94,
                                                0.4,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Booked',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w600,
                                              color: Color.fromRGBO(
                                                34,
                                                197,
                                                94,
                                                1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (clientName != null) ...[
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              '• $clientName',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'Nunito',
                                                color: Color.fromRGBO(
                                                  107,
                                                  114,
                                                  128,
                                                  1,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: revealCancel
                                          ? Column(
                                              key: ValueKey(
                                                'cancel-$sessionId',
                                              ),
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 16),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: canCancel
                                                        ? () {
                                                            _cancelButtonTimer
                                                                ?.cancel();
                                                            _showCancelBookingDialog(
                                                              schedule,
                                                            );
                                                          }
                                                        : null,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color.fromRGBO(
                                                            249,
                                                            115,
                                                            22,
                                                            1,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      disabledForegroundColor:
                                                          Colors.white
                                                              .withOpacity(0.7),
                                                      disabledBackgroundColor:
                                                          const Color.fromRGBO(
                                                            249,
                                                            115,
                                                            22,
                                                            0.4,
                                                          ),
                                                      elevation: 0,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      textStyle:
                                                          const TextStyle(
                                                            fontFamily:
                                                                'Nunito',
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Cancel Booking',
                                                    ),
                                                  ),
                                                ),
                                                if (!canCancel)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8,
                                                        ),
                                                    child: Text(
                                                      'Cancellations close 12 hours before the session.',
                                                      style: TextStyle(
                                                        fontFamily: 'Nunito',
                                                        fontSize: 12,
                                                        color:
                                                            const Color.fromRGBO(
                                                              107,
                                                              114,
                                                              128,
                                                              1,
                                                            ).withOpacity(0.9),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                            builder: (context) =>
                                ManageScheduleScreen(userId: widget.userId),
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
                color: (color ?? const Color.fromRGBO(249, 115, 22, 1))
                    .withOpacity(0.1),
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
