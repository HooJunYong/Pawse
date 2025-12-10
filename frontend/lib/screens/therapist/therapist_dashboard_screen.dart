import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../../services/session_event_bus.dart';
import '../../widgets/therapist_bottom_navigation.dart';
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

  DateTime? _tryBuildSessionDateTime(Map<String, dynamic> schedule) {
    final dynamic dateValue = schedule['date'];
    final String? startTimeRaw = schedule['start_time']?.toString();
    if (dateValue == null || startTimeRaw == null || startTimeRaw.isEmpty) {
      return null;
    }

    String? normalizedDate;
    if (dateValue is DateTime) {
      normalizedDate = DateFormat('yyyy-MM-dd').format(dateValue);
    } else if (dateValue is String && dateValue.isNotEmpty) {
      normalizedDate = dateValue;
    }
    if (normalizedDate == null) {
      return null;
    }

    try {
      return _parseTimeWithDate(normalizedDate, startTimeRaw);
    } catch (_) {
      return null;
    }
  }

  bool _shouldAutoRelease(Map<String, dynamic> schedule) {
    final DateTime? sessionDateTime = _tryBuildSessionDateTime(schedule);
    if (sessionDateTime == null) {
      return false;
    }

    final difference = sessionDateTime.difference(_nowInMalaysia());
    return difference.inDays >= 5;
  }

  Future<void> _autoReleaseIfNeeded(Map<String, dynamic> schedule) async {
    final String? sessionId = schedule['session_id']?.toString();
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }
    if (!_shouldAutoRelease(schedule)) {
      return;
    }

    try {
      await _bookingService.releaseCancelledSessionSlot(
        sessionId: sessionId,
        therapistUserId: widget.userId,
      );
      schedule['slot_released'] = true;
      SessionEventBus.instance.emit(
        SessionEvent(
          type: SessionEventType.slotReleased,
          sessionId: sessionId,
          therapistUserId: widget.userId,
        ),
      );
    } catch (_) {
      // Silent fail; therapist can still release manually if needed.
    }
  }

  List<Map<String, dynamic>> _todaysAppointments = [];
  List<Map<String, dynamic>> _upcomingSchedule = [];
  String _therapistName = '';
  bool _isLoading = true;
  String? _activeCancelSessionId;
  String? _activeCancelledTodaySessionId;
  String? _activeTodayCancelSessionId;
  String? _activeUpcomingReleaseSessionId;
  Timer? _cancelButtonTimer;
  Timer? _todayCancelTimer;
  Timer? _upcomingRefreshTimer;
  Timer? _upcomingReleaseTimer;
  String? _statusUpdatingSessionId;
  bool _isUpcomingLoading = false;
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  int _unreadMessageCount = 0;
  Timer? _chatUnreadTimer;
  StreamSubscription<SessionEvent>? _sessionEventSubscription;
  final Set<String> _releasingSessionIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUnreadCount();
    _chatUnreadTimer =
        Timer.periodic(const Duration(seconds: 25), (_) => _loadUnreadCount());
    _upcomingRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _loadUpcomingSchedule());
    _sessionEventSubscription = SessionEventBus.instance.stream.listen((event) {
      if (!mounted) {
        return;
      }
      if (event.therapistUserId == null || event.therapistUserId != widget.userId) {
        return;
      }
      _loadUpcomingSchedule();
      _loadTodaysAppointments();
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _cancelButtonTimer?.cancel();
    _todayCancelTimer?.cancel();
    _upcomingRefreshTimer?.cancel();
    _upcomingReleaseTimer?.cancel();
    _chatUnreadTimer?.cancel();
    _sessionEventSubscription?.cancel();
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
    final today = _nowInMalaysia();
    final dateStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final response = await http
          .get(Uri.parse('$apiUrl/therapist/schedule/${widget.userId}?date=$dateStr'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
        final todays = sessions.map((session) {
          final scheduledAt = _parseDateTimeIgnoreOffset(session['scheduled_at']);
          final statusRaw =
              (session['session_status'] ?? session['status'] ?? 'scheduled')
                  .toString();
          final durationMinutes =
              int.tryParse(session['duration_minutes']?.toString() ?? '') ?? 50;
          final endAt = scheduledAt.add(Duration(minutes: durationMinutes));
          return {
            'session_id': session['session_id']?.toString() ?? '',
            'scheduled_at': scheduledAt,
            'end_at': endAt,
            'time': DateFormat('h:mm').format(scheduledAt),
            'period': DateFormat('a').format(scheduledAt),
            'client_name': session['client_name'] ?? 'Client',
            'client_user_id': session['user_id']?.toString() ?? '',
            'status': statusRaw,
            'slot_released': session['slot_released'] == true,
          };
        }).toList();
        if (mounted) {
          setState(() {
            _todaysAppointments = todays;
            _activeCancelledTodaySessionId = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _todaysAppointments = [];
            _activeCancelledTodaySessionId = null;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _todaysAppointments = [];
          _activeCancelledTodaySessionId = null;
        });
      }
    }
  }

  Future<void> _loadUpcomingSchedule() async {
    if (_isUpcomingLoading) return;
    _isUpcomingLoading = true;
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final List<Map<String, dynamic>> scheduleData = [];
    final now = _nowInMalaysia();

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
              Map<String, dynamic>? matchedSession;

              for (final session in sessions) {
                final sessionTime = _parseDateTimeIgnoreOffset(session['scheduled_at']);
                final slotStart =
                    _parseTimeWithDate(dateStr, slot['start_time']);
                if (sessionTime.isAtSameMomentAs(slotStart)) {
                  sessionId = session['session_id']?.toString();
                  clientName = session['client_name'];
                  clientUserId = session['user_id'];
                  matchedSession = session;
                  break;
                }
              }
              if (sessionId != null) {
                final Map<String, dynamic> sessionData =
                    matchedSession ?? <String, dynamic>{};
                final statusRaw =
                    (sessionData['session_status'] ??
                            sessionData['status'] ??
                            'scheduled')
                        .toString();
                final statusLower = statusRaw.toLowerCase();
                bool slotReleased = sessionData['slot_released'] == true;
                if (statusLower.contains('cancel') && !slotReleased) {
                  final Map<String, dynamic> releaseCandidate = {
                    'session_id': sessionId,
                    'date': dateStr,
                    'start_time': slot['start_time'],
                  };
                  if (_shouldAutoRelease(releaseCandidate)) {
                    await _autoReleaseIfNeeded(releaseCandidate);
                    slotReleased = true;
                    sessionData['slot_released'] = true;
                  }
                }
                final bool isBooked =
                    !(statusLower.contains('cancel') || slotReleased);
                scheduleData.add({
                  'date': dateStr,
                  'start_time': slot['start_time'],
                  'end_time': slot['end_time'],
                  'availability_id': slot['availability_id'],
                  'is_booked': isBooked,
                  'client_name': clientName,
                  'session_id': sessionId,
                  'client_user_id': clientUserId,
                  'session_status': statusRaw,
                  'slot_released': slotReleased,
                  'booked_session_status':
                      slot['booked_session_status']?.toString(),
                  'cancellation_reason':
                      sessionData['cancellation_reason']?.toString(),
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
          _activeUpcomingReleaseSessionId = null;
        });
      }
    } finally {
      _isUpcomingLoading = false;
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final conversations = await _chatService.getConversations(
        userId: widget.userId,
        isTherapist: true,
      );
      if (!mounted) {
        return;
      }
      final int total = conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
      setState(() {
        _unreadMessageCount = total;
      });
    } catch (_) {
      // Ignore unread count fetch errors silently to keep dashboard responsive.
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

  DateTime _parseDateTimeIgnoreOffset(String isoString) {
    final trimmed = isoString.trim();
    if (trimmed.isEmpty) {
      return _nowInMalaysia();
    }

    final tzMatch = RegExp(r'([+-]\d{2}:?\d{2}|Z)$').firstMatch(trimmed);
    if (tzMatch != null) {
      final tzPart = tzMatch.group(0)!;
      final core = trimmed.substring(0, tzMatch.start);

      if (tzPart == 'Z') {
        final utc = DateTime.parse(trimmed).toUtc();
        final myTime = utc.add(const Duration(hours: 8));
        return DateTime(
          myTime.year,
          myTime.month,
          myTime.day,
          myTime.hour,
          myTime.minute,
          myTime.second,
          myTime.millisecond,
          myTime.microsecond,
        );
      }

      // If offset is provided (e.g. +08:00), treat the face value as the intended local time.
      final parsed = DateTime.parse(core);
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }

    // No timezone info provided: treat as UTC and convert to Malaysia time (+8).
    final parsed = DateTime.parse(trimmed);
    final utc = DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
    final myTime = utc.add(const Duration(hours: 8));
    return DateTime(
      myTime.year,
      myTime.month,
      myTime.day,
      myTime.hour,
      myTime.minute,
      myTime.second,
      myTime.millisecond,
      myTime.microsecond,
    );
  }

  DateTime? _tryParseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      try {
        return _parseDateTimeIgnoreOffset(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DateTime _nowInMalaysia() {
    final utcNow = DateTime.now().toUtc();
    final myTime = utcNow.add(const Duration(hours: 8));
    return DateTime(
      myTime.year,
      myTime.month,
      myTime.day,
      myTime.hour,
      myTime.minute,
      myTime.second,
      myTime.millisecond,
      myTime.microsecond,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchSessionHistory({
    int lookbackDays = 30,
    int maxEntries = 20,
  }) async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final now = _nowInMalaysia();
    final seenSessionIds = <String>{};
    final history = <Map<String, dynamic>>[];
    
    // Get today's date string for comparison
    final todayDateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    for (int i = -1; i < lookbackDays && history.length < maxEntries; i++) {
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
          
          // Include all statuses for today, only history statuses for past dates
          final isToday = dateStr == todayDateStr;
          if (!isToday && !_isHistoryStatus(statusRaw)) {
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
          final dynamic userRating = session['user_rating'];
          final String? userFeedback = session['user_feedback']?.toString();

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
            'user_rating': userRating,
            'user_feedback': userFeedback,
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
                                          .format(scheduledAt),
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 13,
                                        color: _textGrey,
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                      if (status == 'completed' && record['user_rating'] != null && record['user_rating'] > 0) ...[
                                        const SizedBox(width: 8),
                                        const Text('·', style: TextStyle(color: _textGrey)),
                                        const SizedBox(width: 6),
                                        ...List.generate(5, (index) {
                                          final ratingValue = record['user_rating'] is int
                                              ? (record['user_rating'] as int).toDouble()
                                              : (record['user_rating'] as double);
                                          return Icon(
                                            index < ratingValue.round()
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 14,
                                            color: _accentOrange,
                                          );
                                        }),
                                      ],
                                    ],
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
    final dynamic userRating = record['user_rating'];
    final String? userFeedback = record['user_feedback']?.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: _bgCream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _historyDetailRow(
                          'Client',
                          record['client_name']?.toString() ?? 'Client',
                          icon: Icons.person_outline,
                        ),
                        if (scheduledAt != null)
                          _historyDetailRow(
                            'Scheduled At',
                            DateFormat('MMM d, yyyy · h:mm a')
                                .format(scheduledAt),
                            icon: Icons.calendar_today_outlined,
                          ),
                        if (endAt != null)
                          _historyDetailRow(
                            'Ended At',
                            DateFormat('MMM d, yyyy · h:mm a')
                                .format(endAt),
                            icon: Icons.access_time,
                          ),
                        if (duration != null)
                          _historyDetailRow(
                            'Duration', 
                            '$duration minutes',
                            icon: Icons.timer_outlined,
                          ),
                        if (reason != null && reason.trim().isNotEmpty)
                          _historyDetailRow(
                            'Reason', 
                            reason,
                            icon: Icons.info_outline,
                            valueColor: _errorRed,
                          ),
                        if (notes != null && notes.trim().isNotEmpty)
                          _historyDetailRow(
                            'Notes', 
                            notes,
                            icon: Icons.note_outlined,
                          ),
                        if (sessionNotes != null && sessionNotes.trim().isNotEmpty)
                          _historyDetailRow(
                            'Session Notes', 
                            sessionNotes,
                            icon: Icons.description_outlined,
                          ),
                        if (therapistNotes != null &&
                            therapistNotes.trim().isNotEmpty)
                          _historyDetailRow(
                            'Therapist Notes', 
                            therapistNotes,
                            icon: Icons.edit_note,
                          ),
                        
                        // Client Rating Section
                        if (status == 'completed') ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Client Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (userRating != null && userRating > 0) ...[
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  final ratingValue = userRating is int
                                      ? userRating.toDouble()
                                      : (userRating as double);
                                  return Icon(
                                    index < ratingValue.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 28,
                                    color: _accentOrange,
                                  );
                                }),
                              ],
                            ),
                            if (userFeedback != null && userFeedback.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _surfaceWhite,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Client Feedback',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w600,
                                        color: _textGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      userFeedback,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
                                        color: _textDark,
                                        height: 1.4,
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
                                color: _textGrey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.star_border,
                                    color: _textGrey,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Not rated yet',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Nunito',
                                      color: _textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close',
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
          ),
        );
      },
    );
  }

  Widget _historyDetailRow(String label, String value, {Color? valueColor, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _textGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: _textGrey),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
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
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelBookingDialog(Map<String, dynamic> schedule) async {
    final String? sessionId = schedule['session_id']?.toString();
    final String? clientUserId = schedule['client_user_id']?.toString();
    if (sessionId == null || sessionId.isEmpty ||
        clientUserId == null || clientUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel this booking right now.')),
      );
      return;
    }

    bool isSubmitting = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleCancel() async {
              if (isSubmitting) return;
              setStateDialog(() {
                isSubmitting = true;
                errorMessage = null;
              });

              try {
                await _bookingService.cancelBooking(
                  sessionId: sessionId,
                  clientUserId: clientUserId,
                  therapistUserId: widget.userId,
                  cancelledBy: 'therapist',
                );

                if (!mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled successfully.')),
                );

                if (schedule.isNotEmpty && _shouldAutoRelease(schedule)) {
                  await _autoReleaseIfNeeded(schedule);
                }

                await Future.wait([
                  _loadUpcomingSchedule(),
                  _loadTodaysAppointments(),
                ]);
              } catch (e) {
                if (mounted) {
                  setStateDialog(() {
                    isSubmitting = false;
                    errorMessage = 'Failed to cancel booking: $e';
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: _bgCream,
              title: const Text(
                'Cancel Booking',
                style: TextStyle(
                  color: _textDark,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will cancel the selected session. The client will be notified and the slot can be reopened for other bookings.',
                    style: TextStyle(
                      color: _textDark.withOpacity(0.8),
                      fontFamily: 'Nunito',
                      fontSize: 14,
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: _errorRed,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: _textGrey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _errorRed,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting ? null : handleCancel,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Confirm Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _releaseCancelledSlot(Map<String, dynamic> schedule) async {
    final String? sessionId = schedule['session_id']?.toString();
    if (sessionId == null || _releasingSessionIds.contains(sessionId)) {
      return;
    }

    setState(() => _releasingSessionIds.add(sessionId));
    try {
      await _bookingService.releaseCancelledSessionSlot(
        sessionId: sessionId,
        therapistUserId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      if (_activeUpcomingReleaseSessionId == sessionId) {
        setState(() {
          _activeUpcomingReleaseSessionId = null;
        });
      }
      _upcomingReleaseTimer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot marked available for booking.')),
      );
      await Future.wait([
        _loadUpcomingSchedule(),
        _loadTodaysAppointments(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to release slot: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _releasingSessionIds.remove(sessionId));
      } else {
        _releasingSessionIds.remove(sessionId);
      }
    }
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
                            final String statusLower = status.toLowerCase();
                            final String statusLabel =
                                _formatStatusLabel(status);
                            final Color statusColor = _statusColor(status);
                            final DateTime? endAt =
                              appointment['end_at'] as DateTime?;
                            final DateTime? startAt =
                              appointment['scheduled_at'] as DateTime?;
                            final DateTime nowMy = _nowInMalaysia();
                            final int minutesUntilStart = startAt != null
                              ? startAt.difference(nowMy).inMinutes
                              : -1;
                            final bool isCancelled =
                                statusLower.contains('cancel');
                            final bool slotReleased =
                                appointment['slot_released'] == true;
                            final bool meetsReleaseWindow = true; // Allow release at any time
                            final bool isScheduled = statusLower == 'scheduled';
                            final bool canUpdate = isScheduled &&
                              endAt != null &&
                              nowMy.isAfter(endAt);
                            final bool isUpdating =
                                _statusUpdatingSessionId == sessionId;
                            final bool revealRelease = isCancelled &&
                                _activeCancelledTodaySessionId == sessionId;
                            final bool isReleasing =
                                _releasingSessionIds.contains(sessionId);
                            final bool canRelease = isCancelled &&
                                !slotReleased &&
                                meetsReleaseWindow;
                            final bool canCancelBooking = isScheduled &&
                                minutesUntilStart >= 30;
                            final bool revealTodayCancel = isScheduled &&
                                _activeTodayCancelSessionId == sessionId;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: isCancelled
                                  ? () {
                                      setState(() {
                                        if (_activeCancelledTodaySessionId ==
                                            sessionId) {
                                          _activeCancelledTodaySessionId = null;
                                        } else {
                                          _activeCancelledTodaySessionId =
                                              sessionId;
                                        }
                                      });
                                    }
                                  : canCancelBooking
                                      ? () {
                                          setState(() {
                                            if (_activeTodayCancelSessionId ==
                                                sessionId) {
                                              _activeTodayCancelSessionId = null;
                                              _todayCancelTimer?.cancel();
                                            } else {
                                              _activeTodayCancelSessionId = sessionId;
                                              _todayCancelTimer?.cancel();
                                              _todayCancelTimer = Timer(
                                                const Duration(seconds: 5),
                                                () {
                                                  if (mounted) {
                                                    setState(() {
                                                      _activeTodayCancelSessionId = null;
                                                    });
                                                  }
                                                },
                                              );
                                            }
                                          });
                                        }
                                      : null,
                              child: Container(
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
                                          CrossAxisAlignment.center,
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
                                    // Cancel Booking Button or Info Message
                                    if (isScheduled && minutesUntilStart < 30 && minutesUntilStart >= 0) ...[
                                      const SizedBox(height: 16),
                                      const Divider(height: 1, color: _bgCream),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.amber.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 20,
                                              color: Colors.amber.shade700,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'You are not able to cancel booking within 30 minutes before the session starts.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.amber.shade900,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (canCancelBooking) ...[
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: revealTodayCancel
                                            ? Column(
                                                key: ValueKey('cancel-today-$sessionId'),
                                                children: [
                                                  const SizedBox(height: 16),
                                                  const Divider(height: 1, color: _bgCream),
                                                  const SizedBox(height: 16),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        _todayCancelTimer?.cancel();
                                                        _showCancelBookingDialog({
                                                          'session_id': sessionId,
                                                          'client_user_id': appointment['client_user_id'],
                                                          'date': DateFormat('yyyy-MM-dd').format(startAt ?? nowMy),
                                                          'start_time': appointment['time'] ?? '',
                                                        });
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: _accentOrange,
                                                        foregroundColor: Colors.white,
                                                        elevation: 0,
                                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Text('Cancel Booking'),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                    if (isCancelled) ...[
                                      const SizedBox(height: 16),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: revealRelease
                                            ? Column(
                                                key: ValueKey(
                                                    'release-today-$sessionId'),
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Divider(
                                                      height: 1,
                                                      color: _bgCream),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'This session was cancelled. You can reopen the slot for other clients.',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: 'Nunito',
                                                      color: Colors
                                                          .grey.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  if (slotReleased)
                                                    Text(
                                                      'Slot already available for rebooking.',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontFamily: 'Nunito',
                                                        color:
                                                            Colors.grey[500],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    )
                                                  else
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed: isReleasing
                                                            ? null
                                                            : () =>
                                                                _releaseCancelledSlot(
                                                                  {
                                                                    'session_id':
                                                                        sessionId,
                                                                  },
                                                                ),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              _primaryBrown,
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          padding: const EdgeInsets
                                                                  .symmetric(
                                                              vertical: 12),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        child: isReleasing
                                                            ? const SizedBox(
                                                                width: 18,
                                                                height: 18,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<Color>(
                                                                    Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              )
                                                            : const Text(
                                                                'Set Available',
                                                              ),
                                                      ),
                                                    ),
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
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
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                      _successGreen,
                                                  foregroundColor:
                                                      Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  padding: const EdgeInsets
                                                          .symmetric(
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
                                                style: OutlinedButton
                                                    .styleFrom(
                                                  foregroundColor: _errorRed,
                                                  side: const BorderSide(
                                                      color: _errorRed),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  padding: const EdgeInsets
                                                          .symmetric(
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
                            final String? sessionId =
                                schedule['session_id']?.toString();
                            if (sessionId == null || sessionId.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            DateTime parsedDate = _nowInMalaysia();
                            String normalizedSourceDate = '';
                            final dynamic dateValue = schedule['date'];
                            if (dateValue is DateTime) {
                              parsedDate = dateValue;
                            } else if (dateValue is String) {
                              normalizedSourceDate = dateValue;
                              try {
                                parsedDate = DateTime.parse(dateValue);
                              } catch (_) {}
                            }
                            if (normalizedSourceDate.isEmpty) {
                              normalizedSourceDate =
                                  DateFormat('yyyy-MM-dd').format(parsedDate);
                            }
                            final String dateStr =
                                DateFormat('EEE, MMM d').format(parsedDate);

                            final String startTimeLabel =
                                schedule['start_time']?.toString() ?? '';
                            final DateTime sessionDateTime = startTimeLabel.isNotEmpty
                              ? _parseTimeWithDate(normalizedSourceDate, startTimeLabel)
                              : parsedDate;
                            final DateTime nowMy = _nowInMalaysia();
                            final int minutesUntilSession = sessionDateTime
                              .difference(nowMy)
                              .inMinutes;

                            final String statusRaw =
                                schedule['session_status']?.toString() ??
                                    'scheduled';
                            final String statusLower = statusRaw.toLowerCase();
                            final bool isCancelled =
                                statusLower.contains('cancel');
                            final bool slotReleased =
                                schedule['slot_released'] == true;
                            final bool revealCancel = !isCancelled &&
                                _activeCancelSessionId == sessionId;
                            final bool canCancel =
                                !isCancelled && minutesUntilSession >= 720;
                            final bool revealUpcomingRelease = isCancelled &&
                              _activeUpcomingReleaseSessionId == sessionId;
                            final bool meetsReleaseWindow = true; // Allow release at any time
                            final bool canReleaseSlot = isCancelled &&
                              !slotReleased &&
                              meetsReleaseWindow;
                            final bool showReleaseButton =
                              revealUpcomingRelease && canReleaseSlot;
                            final bool showReleaseLockoutMessage =
                              revealUpcomingRelease &&
                                !meetsReleaseWindow &&
                                !slotReleased;
                            final bool isReleasing =
                                _releasingSessionIds.contains(sessionId);
                            final String? clientName =
                                schedule['client_name']?.toString();
                            final String? cancellationReason =
                                schedule['cancellation_reason']?.toString();

                            final Color statusColor =
                                isCancelled ? _errorRed : _successGreen;
                            final String statusLabel =
                                _formatStatusLabel(statusRaw);

                            return GestureDetector(
                                onTap: () {
                                  if (isCancelled) {
                                    final bool shouldReveal =
                                        _activeUpcomingReleaseSessionId !=
                                            sessionId;
                                    _upcomingReleaseTimer?.cancel();
                                    setState(() {
                                      _activeUpcomingReleaseSessionId =
                                          shouldReveal ? sessionId : null;
                                    });
                                    if (shouldReveal) {
                                      _upcomingReleaseTimer =
                                          Timer(const Duration(seconds: 5), () {
                                        if (mounted &&
                                            _activeUpcomingReleaseSessionId ==
                                                sessionId) {
                                          setState(() {
                                            _activeUpcomingReleaseSessionId =
                                                null;
                                          });
                                        }
                                      });
                                    }
                                    return;
                                  }

                                  final bool shouldRevealCancel =
                                      _activeCancelSessionId != sessionId;
                                  _cancelButtonTimer?.cancel();
                                  setState(() {
                                    _activeCancelSessionId =
                                        shouldRevealCancel ? sessionId : null;
                                  });
                                  if (shouldRevealCancel) {
                                    _cancelButtonTimer =
                                        Timer(const Duration(seconds: 5), () {
                                      if (mounted &&
                                          _activeCancelSessionId == sessionId) {
                                        setState(() {
                                          _activeCancelSessionId = null;
                                        });
                                      }
                                    });
                                  }
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
                                      color: statusColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor
                                            .withOpacity(revealCancel ? 0.12 : 0.06),
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
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'Nunito',
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
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
                                      if (isCancelled &&
                                          cancellationReason != null &&
                                          cancellationReason.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Cancellation reason: $cancellationReason',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Nunito',
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                      if (isCancelled) ...[
                                        if (slotReleased)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'Slot already available for rebooking.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        if (!slotReleased && revealUpcomingRelease) ...[
                                          const SizedBox(height: 16),
                                          if (showReleaseButton)
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: (slotReleased || isReleasing)
                                                    ? null
                                                    : () =>
                                                        _releaseCancelledSlot(schedule),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _primaryBrown,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: isReleasing
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              const AlwaysStoppedAnimation<Color>(
                                                            Colors.white,
                                                          ),
                                                        ),
                                                      )
                                                    : const Text('Set Available'),
                                              ),
                                            ),
                                        ],
                                      ] else ...[
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: revealCancel
                                              ? Column(
                                                  key: ValueKey('cancel-$sessionId'),
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
                                                              .symmetric(vertical: 12),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: const Text('Cancel Booking'),
                                                      ),
                                                    ),
                                                    if (!canCancel)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(top: 8),
                                                        child: Text(
                                                          'Too late to cancel (12h rule)',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[500],
                                                            fontStyle: FontStyle.italic,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
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
      bottomNavigationBar: TherapistBottomNavigation(
        userId: widget.userId,
        currentTab: TherapistNavTab.dashboard,
        unreadCount: _unreadMessageCount,
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
        height: 150,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}