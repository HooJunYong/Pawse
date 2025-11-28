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
    
    return Therapist(
      id: json['user_id']?.toString() ?? '',
      name: '${json['first_name']?.toString() ?? ''} ${json['last_name']?.toString() ?? ''}'.trim(),
      specialties:
          (json['specializations'] as List<dynamic>?)?.join(', ') ?? 'General Counseling',
      location: state,
      address: address.isEmpty ? 'Location not specified' : address,
      languages:
          (json['languages_spoken'] as List<dynamic>?)?.join(', ') ?? 'English',
      rating: 4.5, // Default rating as backend doesn't have this yet
      imageUrl: _getInitials(json['first_name']?.toString(), json['last_name']?.toString()),
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
