import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AdminVerifiedTherapistListScreen extends StatefulWidget {
  final String adminUserId;
  const AdminVerifiedTherapistListScreen({super.key, required this.adminUserId});

  @override
  State<AdminVerifiedTherapistListScreen> createState() =>
      _AdminVerifiedTherapistListScreenState();
}

class _AdminVerifiedTherapistListScreenState
    extends State<AdminVerifiedTherapistListScreen> {
  List<Map<String, dynamic>> _therapists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerifiedTherapists();
  }

  Future<void> _loadVerifiedTherapists() async {
    setState(() => _isLoading = true);
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$apiUrl/therapist/verified'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _therapists = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F4F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF422006)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verified Therapists',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF422006)),
            onPressed: _loadVerifiedTherapists,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF97316),
              ),
            )
          : _therapists.isEmpty
              ? const Center(
                  child: Text(
                    'No verified therapists found',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVerifiedTherapists,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _therapists.length,
                    itemBuilder: (context, index) {
                      final therapist = _therapists[index];
                      final firstName = therapist['first_name'] ?? '';
                      final lastName = therapist['last_name'] ?? '';
                      final centerName = therapist['office_name'] ?? 'N/A';
                      final email = therapist['email'] ?? 'No email';

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
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: therapist['profile_picture_url'] != null && therapist['profile_picture_url'].isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: Image.network(
                                            therapist['profile_picture_url'],
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.verified_user,
                                                color: Color(0xFF10B981),
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.verified_user,
                                          color: Color(0xFF10B981),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dr. $firstName $lastName',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF422006),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Nunito',
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    centerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF422006),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
