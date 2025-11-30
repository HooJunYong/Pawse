import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../chat/chat_contacts_screen.dart';
import 'manage_schedule_screen.dart';
import 'therapist_profile_screen.dart';

// --- Theme Constants (Earthy/Warm Vibe) ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _surfaceWhite = Colors.white;
const Color _textDark = Color(0xFF3E2723); // Dark Brown
const Color _textGrey = Color(0xFF8D6E63); // Warm Grey
const Color _primaryBrown = Color(0xFF5D4037);
const Color _accentOrange = Color(0xFFFB923C); // Matches your nav active color
const Color _successGreen = Color(0xFF22C55E);
const Color _errorRed = Color(0xFFEF4444);

final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: const Color(0xFF5D4037).withOpacity(0.08),
    blurRadius: 15,
    offset: const Offset(0, 5),
  ),
];

class TherapistDashboardScreen extends StatefulWidget {
  final String userId;

  const TherapistDashboardScreen({super.key, required this.userId});

  @override
  State<TherapistDashboardScreen> createState() =>
      _TherapistDashboardScreenState();
}

class _TherapistDashboardScreenState extends State<TherapistDashboardScreen> {
  // --- Time Picker Logic ---
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
            Widget buildTimePicker(String label, int hour, int minute,
                void Function(int, int) onChanged) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _textDark,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _primaryBrown.withOpacity(0.1), width: 1),
                      boxShadow: _softShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour
                        Column(
                          children: [
                            InkWell(
                              onTap: () => onChanged(
                                  (hour - 1) < 0 ? 23 : hour - 1, minute),
                              child: const Icon(Icons.keyboard_arrow_up,
                                  color: _textGrey),
                            ),
                            Text(
                              hour.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: _textDark),
                            ),
                            InkWell(
                              onTap: () => onChanged(
                                  (hour + 1) > 23 ? 0 : hour + 1, minute),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  color: _textGrey),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text(":",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _textGrey)),
                        const SizedBox(width: 8),
                        // Minute
                        Column(
                          children: [
                            InkWell(
                              onTap: () => onChanged(
                                  hour, (minute - 1) < 0 ? 59 : minute - 1),
                              child: const Icon(Icons.keyboard_arrow_up,
                                  color: _textGrey),
                            ),
                            Text(
                              minute.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: _textDark),
                            ),
                            InkWell(
                              onTap: () => onChanged(
                                  hour, (minute + 1) > 59 ? 0 : minute + 1),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  color: _textGrey),
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
              backgroundColor: _bgCream,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Schedule',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildTimePicker('Start Time', startHour, startMinute,
                            (h, m) {
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
                      const CircularProgressIndicator(color: _primaryBrown)
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: _textGrey,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBrown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              setState(() {
                                isSaving = true;
                              });
                              // API Logic would go here
                              Navigator.of(context).pop();
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

  DateTime _parseTimeWithDate(String dateStr, String timeStr) {
    final DateTime baseDate = DateFormat('yyyy-MM-dd').parse(dateStr);
    final TimeOfDay time = _parseTimeOfDay(timeStr);
    return DateTime(baseDate.year, baseDate.month, baseDate.day, time.hour, time.minute);
  }

  List<Map<String, dynamic>> _todaysAppointments = [];
  List<Map<String, dynamic>> _upcomingSchedule = [];
  String _therapistName = '';
  bool _isLoading = true;
  String? _activeCancelSessionId;
  Timer? _cancelButtonTimer;
  Timer? _upcomingRefreshTimer;
  String? _statusUpdatingSessionId;
  bool _isUpcomingLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _upcomingRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _loadUpcomingSchedule());
  }

  @override
  void dispose() {
    _cancelButtonTimer?.cancel();
    _upcomingRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final profileResponse =
          await http.get(Uri.parse('$apiUrl/therapist/profile/${widget.userId}'));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTodaysAppointments() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final today = DateTime.now();
    final dateStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final response = await http
          .get(Uri.parse('$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
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
        if (mounted) setState(() => _todaysAppointments = todays);
      } else {
        if (mounted) setState(() => _todaysAppointments = []);
      }
    } catch (_) {
      if (mounted) setState(() => _todaysAppointments = []);
    }
  }

  Future<void> _loadUpcomingSchedule() async {
    if (_isUpcomingLoading) return;
    _isUpcomingLoading = true;
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final List<Map<String, dynamic>> scheduleData = [];
    final now = DateTime.now();

    try {
      for (int i = 1; i <= 5; i++) {
        final date = now.add(Duration(days: i));
        final dateStr =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        try {
          final response = await http.get(Uri.parse(
              '$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final sessions =
                List<Map<String, dynamic>>.from(data['sessions'] ?? []);
            final availabilitySlots =
                List<Map<String, dynamic>>.from(data['availability_slots'] ?? []);

            for (final slot in availabilitySlots) {
              String? sessionId;
              String? clientName;
              dynamic clientUserId;

              for (final session in sessions) {
                final sessionTime = DateTime.parse(session['scheduled_at']);
                final slotStart =
                    _parseTimeWithDate(dateStr, slot['start_time']);
                if (sessionTime.isAtSameMomentAs(slotStart)) {
                  sessionId = session['session_id']?.toString();
                  clientName = session['client_name'];
                  clientUserId = session['user_id'];
                  break;
                }
              }
              if (sessionId != null) {
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
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _upcomingSchedule = scheduleData;
          _activeCancelSessionId = null;
        });
      }
    } finally {
      _isUpcomingLoading = false;
    }
  }

  String _formatStatusLabel(String status) {
    final lower = status.toLowerCase();
    switch (lower) {
      case 'completed':
        return 'Completed';
      case 'no_show':
        return 'No-Show';
      case 'cancelled':
      case 'cancelled_by_client':
      case 'cancelled_by_therapist':
        return 'Cancelled';
      default:
        if (lower.contains('cancel')) {
          return 'Cancelled';
        }
        return 'Scheduled';
    }
  }

  Color _statusColor(String status) {
    final lower = status.toLowerCase();
    switch (lower) {
      case 'completed':
        return _successGreen;
      case 'no_show':
        return _errorRed;
      case 'cancelled':
      case 'cancelled_by_client':
      case 'cancelled_by_therapist':
        return _errorRed;
      default:
        if (lower.contains('cancel')) {
          return _errorRed;
        }
        return Colors.blueAccent;
    }
  }

  IconData _historyStatusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower == 'completed') {
      return Icons.check_circle_outline;
    }
    if (lower == 'no_show') {
      return Icons.event_busy;
    }
    if (lower.contains('cancel')) {
      return Icons.cancel_outlined;
    }
    return Icons.history_toggle_off;
  }

  bool _isHistoryStatus(String status) {
    final lower = status.toLowerCase();
    return lower == 'completed' || lower == 'no_show' || lower.contains('cancel');
  }

  DateTime? _tryParseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchSessionHistory({
    int lookbackDays = 30,
    int maxEntries = 20,
  }) async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final now = DateTime.now();
    final seenSessionIds = <String>{};
    final history = <Map<String, dynamic>>[];

    for (int i = 0; i < lookbackDays && history.length < maxEntries; i++) {
      final date = now.subtract(Duration(days: i + 1));
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      try {
        final response = await http.get(Uri.parse(
            '$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'));
        if (response.statusCode != 200) {
          continue;
        }

        final data = jsonDecode(response.body);
        final sessions =
            List<Map<String, dynamic>>.from(data['sessions'] ?? []);

        for (final session in sessions) {
          final statusRaw =
              (session['session_status'] ?? session['status'] ?? '').toString();
          if (!_isHistoryStatus(statusRaw)) {
            continue;
          }

          final sessionId = session['session_id']?.toString() ?? '';
          if (sessionId.isEmpty || seenSessionIds.contains(sessionId)) {
            continue;
          }

          final scheduledAt = _tryParseDateTime(session['scheduled_at']);
          final dynamic durationRaw = session['duration_minutes'];
          final int? durationMinutes = durationRaw is int
              ? durationRaw
              : int.tryParse(durationRaw?.toString() ?? '');
          DateTime? endAt = _tryParseDateTime(session['end_at']);
          if (endAt == null && scheduledAt != null && durationMinutes != null) {
            endAt = scheduledAt.add(Duration(minutes: durationMinutes));
          }

          final String? notes = session['notes']?.toString();
          final String? sessionNotes = session['session_notes']?.toString();
          final String? therapistNotes = session['therapist_notes']?.toString();
          final String? cancellationReason =
              session['cancellation_reason']?.toString() ??
                  session['cancel_reason']?.toString();

          history.add({
            'session_id': sessionId,
            'status': statusRaw.toLowerCase(),
            'client_name': session['client_name'] ?? 'Client',
            'scheduled_at': scheduledAt,
            'end_at': endAt,
            'duration_minutes': durationMinutes,
            'notes': notes,
            'session_notes': sessionNotes,
            'therapist_notes': therapistNotes,
            'cancellation_reason': cancellationReason,
          });
          seenSessionIds.add(sessionId);

          if (history.length >= maxEntries) {
            break;
          }
        }
      } catch (_) {
        // Ignore day-level fetch errors to keep history resilient.
      }
    }

    history.sort((a, b) {
      final aDate = _tryParseDateTime(a['scheduled_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _tryParseDateTime(b['scheduled_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return history;
  }

  Future<void> _showHistorySheet() async {
    if (!mounted) return;
    final future = _fetchSessionHistory();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        return Container(
          height: maxHeight,
          decoration: const BoxDecoration(
            color: _surfaceWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Session History',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: _primaryBrown),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load history right now.',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                color: _textGrey,
                              ),
                            ),
                          );
                        }

                        final records = snapshot.data ?? [];
                        if (records.isEmpty) {
                          return Center(
                            child: Text(
                              'No past sessions yet.',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                color: _textGrey,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final record = records[index];
                            final status = (record['status'] ?? '').toString();
                            final statusLabel = _formatStatusLabel(status);
                            final statusColor = _statusColor(status);
                            final scheduledAt = _tryParseDateTime(record['scheduled_at']);

                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              tileColor: _surfaceWhite,
                              onTap: () => _showHistoryDetailDialog(record),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: statusColor.withOpacity(0.12),
                                child: Icon(
                                  _historyStatusIcon(status),
                                  color: statusColor,
                                ),
                              ),
                              title: Text(
                                record['client_name']?.toString() ?? 'Client',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (scheduledAt != null)
                                    Text(
                                      DateFormat('MMM d, yyyy · h:mm a')
                                          .format(scheduledAt.toLocal()),
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 13,
                                        color: _textGrey,
                                      ),
                                    ),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: _textGrey,
                              ),
                            );
                          },
                        );
                      },
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

  void _showHistoryDetailDialog(Map<String, dynamic> record) {
    if (!mounted) return;
    final status = (record['status'] ?? '').toString();
    final statusLabel = _formatStatusLabel(status);
    final statusColor = _statusColor(status);
    final scheduledAt = _tryParseDateTime(record['scheduled_at']);
    final endAt = _tryParseDateTime(record['end_at']);
    final dynamic durationRaw = record['duration_minutes'];
    final int? duration = durationRaw is int
        ? durationRaw
        : int.tryParse(durationRaw?.toString() ?? '');
    final String? reason = record['cancellation_reason']?.toString();
    final String? notes = record['notes']?.toString();
    final String? sessionNotes = record['session_notes']?.toString();
    final String? therapistNotes = record['therapist_notes']?.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _bgCream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Session Details',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _historyDetailRow(
                  'Client',
                  record['client_name']?.toString() ?? 'Client',
                ),
                if (scheduledAt != null)
                  _historyDetailRow(
                    'Scheduled At',
                    DateFormat('MMM d, yyyy · h:mm a')
                        .format(scheduledAt.toLocal()),
                  ),
                if (endAt != null)
                  _historyDetailRow(
                    'Ended At',
                    DateFormat('MMM d, yyyy · h:mm a').format(endAt.toLocal()),
                  ),
                if (duration != null)
                  _historyDetailRow('Duration', '$duration minutes'),
                if (reason != null && reason.trim().isNotEmpty)
                  _historyDetailRow('Reason', reason),
                if (notes != null && notes.trim().isNotEmpty)
                  _historyDetailRow('Notes', notes),
                if (sessionNotes != null && sessionNotes.trim().isNotEmpty)
                  _historyDetailRow('Session Notes', sessionNotes),
                if (therapistNotes != null &&
                    therapistNotes.trim().isNotEmpty)
                  _historyDetailRow('Therapist Notes', therapistNotes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  color: _primaryBrown,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: _textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              height: 1.4,
              color: valueColor ?? _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelBookingDialog(Map<String, dynamic> schedule) async {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
                backgroundColor: _bgCream,
                title: const Text('Cancel Booking',
                    style: TextStyle(
                        color: _textDark,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Please provide a reason for cancellation."),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        hintText: 'Reason...',
                      ),
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Back',
                          style: TextStyle(color: _textGrey))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _errorRed,
                        foregroundColor: Colors.white),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setStateDialog(() => isSubmitting = true);
                            // Mock delay/API call
                            await Future.delayed(const Duration(seconds: 1));
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              _loadUpcomingSchedule();
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(color: Colors.white))
                        : const Text('Confirm Cancel'),
                  )
                ]);
          });
        });
  }

  Future<void> _updateSessionStatus(
      {required String sessionId, required String newStatus}) async {
    setState(() => _statusUpdatingSessionId = sessionId);
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      await http.post(Uri.parse('$apiUrl/booking/session/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'session_id': sessionId,
            'therapist_user_id': widget.userId,
            'status': newStatus
          }));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session marked as $newStatus')));
        _loadTodaysAppointments();
        _loadUpcomingSchedule();
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _statusUpdatingSessionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgCream,
        body: Center(child: CircularProgressIndicator(color: _primaryBrown)),
      );
    }

    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
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
                              color: _textGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _therapistName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _surfaceWhite,
                          shape: BoxShape.circle,
                          boxShadow: _softShadow,
                        ),
                        child: IconButton(
                          tooltip: 'Session history',
                          icon: const Icon(Icons.history,
                              color: _primaryBrown, size: 22),
                          onPressed: _showHistorySheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Today's Appointments ---
                  const Text(
                    "Today's Appointments",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _todaysAppointments.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: _surfaceWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _softShadow,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No appointments today',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
                                    color: Colors.grey[500],
                                  ),
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
                            final String statusLabel =
                                _formatStatusLabel(status);
                            final Color statusColor = _statusColor(status);
                            final DateTime? endAt =
                                appointment['end_at'] != null
                                    ? DateTime.tryParse(
                                        appointment['end_at'] as String)
                                    : null;
                            final bool isScheduled =
                                status.toLowerCase() == 'scheduled';
                            final bool canUpdate = isScheduled &&
                                endAt != null &&
                                DateTime.now().isAfter(endAt);
                            final bool isUpdating =
                                _statusUpdatingSessionId == sessionId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _surfaceWhite,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _softShadow,
                                border: Border.all(
                                    color: _primaryBrown.withOpacity(0.05)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Time Column
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appointment['time'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w800,
                                              color: _accentOrange,
                                            ),
                                          ),
                                          Text(
                                            appointment['period'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w600,
                                              color: _textGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      // Info Column
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
                                                color: _textDark,
                                              ),
                                            ),
                                            if (endAt != null)
                                              Text(
                                                'Ends ${DateFormat('h:mm a').format(endAt)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'Nunito',
                                                  color: _textGrey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Status Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Action Buttons
                                  if (canUpdate) ...[
                                    const SizedBox(height: 20),
                                    const Divider(height: 1, color: _bgCream),
                                    const SizedBox(height: 16),
                                    if (isUpdating)
                                      const Center(
                                          child: CircularProgressIndicator(
                                              color: _primaryBrown))
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _successGreen,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                              ),
                                              onPressed: () {
                                                _updateSessionStatus(
                                                  sessionId: sessionId,
                                                  newStatus: 'completed',
                                                );
                                              },
                                              child: const Text(
                                                'Completed',
                                                style: TextStyle(
                                                    fontFamily: 'Nunito',
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: _errorRed,
                                                side: const BorderSide(
                                                    color: _errorRed),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                              ),
                                              onPressed: () {
                                                _updateSessionStatus(
                                                  sessionId: sessionId,
                                                  newStatus: 'no_show',
                                                );
                                              },
                                              child: const Text(
                                                'No Show',
                                                style: TextStyle(
                                                    fontFamily: 'Nunito',
                                                    fontWeight:
                                                        FontWeight.bold),
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

                  // --- Quick Actions ---
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.calendar_month_rounded,
                          label: 'Manage Schedule',
                          color: _primaryBrown,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          color: _accentOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TherapistProfileScreen(
                                    userId: widget.userId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Upcoming Appointments ---
                  const Text(
                    'Upcoming (Next 5 Days)',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _upcomingSchedule.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _surfaceWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _softShadow,
                          ),
                          child: Center(
                            child: Text(
                              'No booked appointments yet',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: _upcomingSchedule.map((schedule) {
                            final date = DateTime.parse(schedule['date']);
                            final dateStr =
                                DateFormat('EEE, MMM d').format(date);
                            final String? sessionId =
                                schedule['session_id'] as String?;
                            if (sessionId == null)
                              return const SizedBox.shrink();

                            final bool revealCancel =
                                _activeCancelSessionId == sessionId;
                            final DateTime sessionDateTime =
                                _parseTimeWithDate(schedule['date'] as String,
                                    schedule['start_time'] as String);
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
                                    const Duration(seconds: 5), () {
                                  if (mounted &&
                                      _activeCancelSessionId == sessionId) {
                                    setState(() {
                                      _activeCancelSessionId = null;
                                    });
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _successGreen.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E)
                                          .withOpacity(revealCancel ? 0.1 : 0.05),
                                      blurRadius: revealCancel ? 12 : 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Nunito',
                                                fontWeight: FontWeight.bold,
                                                color: _textDark,
                                              ),
                                            ),
                                            Text(
                                              '${schedule['start_time']} - ${schedule['end_time']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontFamily: 'Nunito',
                                                color: _textGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _successGreen.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Booked',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.bold,
                                              color: _successGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (clientName != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Client: $clientName',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Nunito',
                                          color: _textDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    // Animated Cancel Button Area
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: revealCancel
                                          ? Column(
                                              key: ValueKey(
                                                  'cancel-$sessionId'),
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
                                                                schedule);
                                                          }
                                                        : null,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: _accentOrange,
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12)),
                                                    ),
                                                    child: const Text(
                                                        'Cancel Booking'),
                                                  ),
                                                ),
                                                if (!canCancel)
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                        top: 8),
                                                    child: Text(
                                                      'Too late to cancel (12h rule)',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[500],
                                                          fontStyle:
                                                              FontStyle.italic),
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
      // --- Bottom Nav (Restored Original Design) ---
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
                        color: _accentOrange,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatContactsScreen(
                              currentUserId: widget.userId,
                              isTherapist: true,
                            ),
                          ),
                        );
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (color ?? _primaryBrown).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color ?? _primaryBrown,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}