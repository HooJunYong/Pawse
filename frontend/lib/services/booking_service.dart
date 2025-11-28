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
    );
  }
}

class BookingService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

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
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/client/$clientUserId/upcoming'),
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') {
          return null;
        }

        final dynamic decoded = json.decode(response.body);
        if (decoded == null) {
          return null;
        }

        if (decoded is Map<String, dynamic>) {
          return TherapySession.fromJson(decoded);
        }

        throw Exception('Unexpected response format for upcoming session');
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load upcoming session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching upcoming session: $e');
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
}
