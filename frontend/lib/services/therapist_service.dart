import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/therapist_model.dart';

class TherapistService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  Future<List<Therapist>> getTherapists({String? searchQuery}) async {
    try {
      String endpoint = '/therapist/verified';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        endpoint += '?search=$searchQuery';
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _mapTherapistFromBackend(json)).toList();
      } else {
        throw Exception('Failed to load therapists');
      }
    } catch (e) {
      throw Exception('Error getting therapists: $e');
    }
  }

  Therapist _mapTherapistFromBackend(Map<String, dynamic> json) {
    // Map backend therapist profile to frontend Therapist model
    // Build full address from backend fields with null safety
    final officeAddress = json['office_address']?.toString() ?? '';
    final city = json['city']?.toString() ?? '';
    final postalCode = json['postal_code']?.toString() ?? '';
    final state = json['state']?.toString() ?? '';
    
    // Construct address, removing empty parts and extra commas
    final addressParts = [officeAddress, city, postalCode, state]
        .where((part) => part.isNotEmpty)
        .join(', ');
    
    final address = addressParts.isNotEmpty ? addressParts : state;
      final ratingValue = (json['average_rating'] as num?)?.toDouble();
      final ratingCount = (json['rating_count'] as num?)?.toInt() ?? 0;
    
    final imageUrl = _resolveImageCandidate(json);
    final initials = _getInitials(
      json['first_name']?.toString(),
      json['last_name']?.toString(),
    );

    return Therapist(
      id: json['user_id']?.toString() ?? '',
      name: '${json['first_name']?.toString() ?? ''} ${json['last_name']?.toString() ?? ''}'.trim(),
      specialties:
          (json['specializations'] as List<dynamic>?)?.join(', ') ?? 'General Counseling',
      location: state,
      address: address.isEmpty ? 'Location not specified' : address,
      languages:
          (json['languages_spoken'] as List<dynamic>?)?.join(', ') ?? 'English',
        rating: ratingValue ?? 0.0,
        ratingCount: ratingCount,
      imageUrl: imageUrl,
      initials: initials,
      title: json['license_number'] != null
          ? 'Licensed Therapist'
          : 'Counselor',
      centerName: json['office_name']?.toString() ?? 'Holistic Mind Center',
      quote: json['bio']?.toString() ?? 'Here to help you on your journey.',
      price: (json['hourly_rate'] as num?)?.toDouble() ?? 150.0,
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials.isNotEmpty ? initials : '?';
  }

  String? _resolveImageCandidate(Map<String, dynamic> json) {
    final candidates = <String?>[
      json['profile_picture_url']?.toString(),
      json['profile_picture']?.toString(),
      json['profile_picture_base64']?.toString(),
      json['avatar_url']?.toString(),
      json['avatar_base64']?.toString(),
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeImage(candidate);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  String? _normalizeImage(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('data:image/')) {
      return trimmed;
    }
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    if (lower == 'null' || lower == 'none') {
      return null;
    }

    final mimeType = _guessImageMime(trimmed);
    return 'data:$mimeType;base64,$trimmed';
  }

  String _guessImageMime(String base64) {
    final snippet = base64.length > 30 ? base64.substring(0, 30) : base64;
    if (snippet.startsWith('/9j/')) {
      return 'image/jpeg';
    }
    if (snippet.startsWith('iVBORw0KGgo')) {
      return 'image/png';
    }
    if (snippet.startsWith('R0lGOD')) {
      return 'image/gif';
    }
    if (snippet.startsWith('Qk')) {
      return 'image/bmp';
    }
    return 'image/png';
  }

  Future<Therapist> getTherapistById(String therapistId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/therapist/profile/$therapistId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapTherapistFromBackend(data);
      } else {
        throw Exception('Failed to load therapist');
      }
    } catch (e) {
      throw Exception('Error getting therapist: $e');
    }
  }
}
