import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AvailableTimeSlot {
  final String slotId;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final String date;

  AvailableTimeSlot({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.date,
  });

  factory AvailableTimeSlot.fromJson(Map<String, dynamic> json) {
    return AvailableTimeSlot(
      slotId: json['slot_id']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isAvailable: json['is_available'] ?? true,
      date: json['date']?.toString() ?? '',
    );
  }
}

class TherapistAvailability {
  final String therapistId;
  final String therapistName;
  final String date;
  final List<AvailableTimeSlot> availableSlots;
  final double price;
  final String centerName;

  TherapistAvailability({
    required this.therapistId,
    required this.therapistName,
    required this.date,
    required this.availableSlots,
    required this.price,
    required this.centerName,
  });

  factory TherapistAvailability.fromJson(Map<String, dynamic> json) {
    var slotsJson = json['available_slots'] as List? ?? [];
    List<AvailableTimeSlot> slots = slotsJson
        .map((slot) => AvailableTimeSlot.fromJson(slot))
        .toList();

    return TherapistAvailability(
      therapistId: json['therapist_id']?.toString() ?? '',
      therapistName: json['therapist_name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      availableSlots: slots,
      price: (json['price'] ?? 0.0).toDouble(),
      centerName: json['center_name']?.toString() ?? '',
    );
  }
}

class TherapySession {
  final String sessionId;
  final String therapistUserId;
  final String therapistName;
  final DateTime scheduledAt;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double sessionFee;
  final String sessionStatus;
  final String sessionType;
  final String? centerName;
  final String? centerAddress;
  final String? therapistProfilePictureUrl;

  TherapySession({
    required this.sessionId,
    required this.therapistUserId,
    required this.therapistName,
    required this.scheduledAt,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.sessionFee,
    required this.sessionStatus,
    required this.sessionType,
    this.centerName,
    this.centerAddress,
    this.therapistProfilePictureUrl,
  });

  factory TherapySession.fromJson(Map<String, dynamic> json) {
    final scheduledAtRaw = json['scheduled_at'];
    DateTime scheduledAt;
    if (scheduledAtRaw == null || (scheduledAtRaw is String && scheduledAtRaw.isEmpty)) {
      scheduledAt = DateTime.now();
    } else if (scheduledAtRaw is DateTime) {
      scheduledAt = scheduledAtRaw;
    } else {
      try {
        scheduledAt = DateTime.parse(scheduledAtRaw.toString());
      } catch (_) {
        scheduledAt = DateTime.now();
      }
    }

    final rawFee = json['session_fee'] ?? json['price'];
    double sessionFee;
    if (rawFee is num) {
      sessionFee = rawFee.toDouble();
    } else {
      sessionFee = double.tryParse(rawFee?.toString() ?? '') ?? 0.0;
    }

    return TherapySession(
      sessionId: json['session_id']?.toString() ?? '',
      therapistUserId: json['therapist_user_id']?.toString() ?? '',
      therapistName: json['therapist_name']?.toString() ?? '',
      scheduledAt: scheduledAt,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      durationMinutes: int.tryParse(json['duration_minutes']?.toString() ?? '') ?? 50,
      sessionFee: sessionFee,
      sessionStatus: json['session_status']?.toString() ?? json['status']?.toString() ?? '',
      sessionType: json['session_type']?.toString() ?? 'in_person',
      centerName: json['center_name']?.toString(),
      centerAddress: json['center_address']?.toString(),
      therapistProfilePictureUrl: json['therapist_profile_picture_url']?.toString(),
    );
  }

  TherapySession copyWith({String? therapistProfilePictureUrl}) {
    return TherapySession(
      sessionId: sessionId,
      therapistUserId: therapistUserId,
      therapistName: therapistName,
      scheduledAt: scheduledAt,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      sessionFee: sessionFee,
      sessionStatus: sessionStatus,
      sessionType: sessionType,
      centerName: centerName,
      centerAddress: centerAddress,
      therapistProfilePictureUrl: therapistProfilePictureUrl ?? this.therapistProfilePictureUrl,
    );
  }
}

class PendingRatingSession {
  final String sessionId;
  final String therapistUserId;
  final String therapistName;
  final DateTime scheduledAt;
  final String endTime;
  final int durationMinutes;
  final String sessionType;
  final String? therapistProfilePictureUrl;

  PendingRatingSession({
    required this.sessionId,
    required this.therapistUserId,
    required this.therapistName,
    required this.scheduledAt,
    required this.endTime,
    required this.durationMinutes,
    required this.sessionType,
    this.therapistProfilePictureUrl,
  });

  factory PendingRatingSession.fromJson(Map<String, dynamic> json) {
    final scheduledRaw = json['scheduled_at'];
    DateTime scheduledAt;
    if (scheduledRaw is DateTime) {
      scheduledAt = scheduledRaw;
    } else if (scheduledRaw is String) {
      scheduledAt = DateTime.tryParse(scheduledRaw) ?? DateTime.now();
    } else {
      scheduledAt = DateTime.now();
    }

    return PendingRatingSession(
      sessionId: json['session_id']?.toString() ?? '',
      therapistUserId: json['therapist_user_id']?.toString() ?? '',
      therapistName: json['therapist_name']?.toString() ?? 'Therapist',
      scheduledAt: scheduledAt,
      endTime: json['end_time']?.toString() ?? '',
      durationMinutes: int.tryParse(json['duration_minutes']?.toString() ?? '') ?? 50,
      sessionType: json['session_type']?.toString() ?? 'in_person',
      therapistProfilePictureUrl: json['therapist_profile_picture_url']?.toString(),
    );
  }
}

class BookingService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  final Map<String, String?> _therapistPhotoCache = {};

  Future<TherapistAvailability> getTherapistAvailability(
    String therapistUserId,
    String date,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/availability/$therapistUserId?date=$date'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TherapistAvailability.fromJson(data);
      } else {
        throw Exception('Failed to load availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching availability: $e');
    }
  }

  Future<Set<String>> getTherapistScheduledDates(
    String therapistUserId,
    int year,
    int month,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/therapist/schedule/$therapistUserId/month?year=$year&month=$month',
        ),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final scheduled = decoded['scheduled_dates'];
          if (scheduled is List) {
            return scheduled
                .map((date) => date?.toString() ?? '')
                .where((date) => date.isNotEmpty)
                .toSet();
          }
        }
        return <String>{};
      } else {
        throw Exception('Failed to load monthly schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching monthly schedule: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String clientUserId,
    required String therapistUserId,
    required String date,
    required String startTime,
    int durationMinutes = 50,
    String? notes,
    String sessionType = 'in_person',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_user_id': clientUserId,
          'therapist_user_id': therapistUserId,
          'date': date,
          'start_time': startTime,
          'duration_minutes': durationMinutes,
          'notes': notes,
          'session_type': sessionType,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  Future<TherapySession?> getUpcomingSession(String clientUserId) async {
    final sessions = await getUpcomingSessions(clientUserId, limit: 1);
    return sessions.isNotEmpty ? sessions.first : null;
  }

  Future<List<TherapySession>> getUpcomingSessions(String clientUserId, {int? limit}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/client/$clientUserId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load upcoming sessions: ${response.statusCode}');
      }

      final dynamic decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format for upcoming sessions');
      }

      final bookingsRaw = decoded['bookings'];
      if (bookingsRaw is! List) {
        return [];
      }

      final now = DateTime.now();
      final sessions = bookingsRaw
          .map((item) => item is Map<String, dynamic> ? TherapySession.fromJson(item) : null)
          .whereType<TherapySession>()
          .where((session) {
            final sessionStart = session.scheduledAt.toLocal();
            final status = session.sessionStatus.toLowerCase();
            return status.contains('scheduled') && sessionStart.isAfter(now);
          })
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      final effectiveLimit = limit != null && limit > 0 ? limit : null;
      final limitedSessions = effectiveLimit != null
          ? sessions.take(effectiveLimit).toList()
          : sessions;

      if (limitedSessions.isEmpty) {
        return limitedSessions;
      }

      final therapistIds = limitedSessions.map((s) => s.therapistUserId).toSet();
      final Map<String, String?> photoMap = {};
      await Future.wait(therapistIds.map((id) async {
        photoMap[id] = await _getTherapistProfilePicture(id);
      }));

      return limitedSessions
          .map((session) => session.copyWith(
                therapistProfilePictureUrl: photoMap[session.therapistUserId],
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching upcoming sessions: $e');
    }
  }

  Future<void> cancelBooking({
    required String sessionId,
    required String clientUserId,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'client_user_id': clientUserId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return;
      }

      final decoded = json.decode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString() ?? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Failed to cancel booking: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error cancelling booking: $e');
    }
  }

  Future<PendingRatingSession?> getPendingRating(String clientUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/client/$clientUserId/pending-rating'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load pending rating: ${response.statusCode}');
      }

      final dynamic decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final hasPending = decoded['has_pending'] == true;
        final session = decoded['session'];
        if (hasPending && session is Map<String, dynamic>) {
          return PendingRatingSession.fromJson(session);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Error fetching pending rating: $e');
    }
  }

  Future<void> submitSessionRating({
    required String sessionId,
    required String clientUserId,
    required int rating,
    String? feedback,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/booking/session/rate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'client_user_id': clientUserId,
          'rating': rating,
          if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
        }),
      );

      if (response.statusCode == 200) {
        return;
      }

      final dynamic decoded = json.decode(response.body);
      final message = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString() ?? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Failed to submit rating: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error submitting rating: $e');
    }
  }

  Future<String?> _getTherapistProfilePicture(String therapistUserId) async {
    if (therapistUserId.isEmpty) {
      return null;
    }

    if (_therapistPhotoCache.containsKey(therapistUserId)) {
      return _therapistPhotoCache[therapistUserId];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/therapist/profile/$therapistUserId'),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final url = decoded['profile_picture_url']?.toString();
          _therapistPhotoCache[therapistUserId] = url;
          return url;
        }
      }
    } catch (_) {
      // Ignore errors; default to null
    }

    _therapistPhotoCache[therapistUserId] = null;
    return null;
  }
}
