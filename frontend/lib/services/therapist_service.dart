import 'dart:async';

import '../models/therapist_model.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

class TherapistService {
  // TODO: Replace with your actual Python server URL (e.g., 'http://127.0.0.1:5000')
  static const String baseUrl = 'http://your-python-api.com';

  Future<List<Therapist>> getTherapists() async {
    // Uncomment for real backend
    /*
    try {
      final response = await http.get(Uri.parse('$baseUrl/therapists'));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Therapist> therapists = body
            .map((dynamic item) => Therapist.fromJson(item))
            .toList();
        return therapists;
      } else {
        throw Exception('Failed to load therapists');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
    */

    // Mock data for UI demo
    await Future.delayed(const Duration(seconds: 1));
    return [
      Therapist(
        id: '1',
        name: 'Mr. Lim Wei',
        specialties: 'Depression, Trauma',
        location: 'Penang',
        languages: 'EN, M',
        rating: 4.8,
        imageUrl: 'Mr.L',
      ),
      Therapist(
        id: '2',
        name: 'Ms. Chloe Tan',
        specialties: 'Family, Self-Esteem',
        location: 'Johor Bahru',
        languages: 'EN, C',
        rating: 4.9,
        imageUrl: 'Ms.C',
      ),
      Therapist(
        id: '3',
        name: 'Dr. Rajesh',
        specialties: 'Career, Life Transitions',
        location: 'Selangor',
        languages: 'EN, T',
        rating: 4.7,
        imageUrl: 'Dr.R',
      ),
    ];
  }
}
