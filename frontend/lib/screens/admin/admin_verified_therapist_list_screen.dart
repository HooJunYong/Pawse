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
        
        // Debug: Print first therapist data to check rating and image fields
        if (data.isNotEmpty) {
          print('First therapist data: ${data[0]}');
          print('Average rating: ${data[0]['average_rating']}');
          print('Total ratings: ${data[0]['total_ratings']}');
          print('Profile picture URL: ${data[0]['profile_picture_url']}');
          print('Profile picture URL length: ${data[0]['profile_picture_url']?.toString().length ?? 0}');
          print('Profile picture base64: ${data[0]['profile_picture_base64']?.toString().substring(0, 50) ?? 'null'}...');
        }
        
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

  void _showTherapistDetails(Map<String, dynamic> therapist) {
    final firstName = therapist['first_name'] ?? '';
    final lastName = therapist['last_name'] ?? '';
    final fullName = 'Dr. $firstName $lastName';
    final email = therapist['email'] ?? 'N/A';
    final contactNumber = therapist['contact_number'] ?? 'N/A';
    
    // Handle specializations (array)
    final specializationData = therapist['specializations'] ?? therapist['specialization'];
    String specialization = 'N/A';
    if (specializationData != null) {
      if (specializationData is List && specializationData.isNotEmpty) {
        specialization = specializationData.join(', ');
      } else if (specializationData is String && specializationData.isNotEmpty) {
        specialization = specializationData;
      }
    }
    
    // Handle languages (array)
    final languagesData = therapist['languages_spoken'] ?? therapist['languages'];
    String languages = 'N/A';
    if (languagesData != null) {
      if (languagesData is List && languagesData.isNotEmpty) {
        languages = languagesData.join(', ');
      } else if (languagesData is String && languagesData.isNotEmpty) {
        languages = languagesData;
      }
    }
    
    final centerName = therapist['office_name'] ?? 'N/A';
    final hourlyRate = therapist['hourly_rate'] != null 
        ? 'RM ${therapist['hourly_rate']}' 
        : 'N/A';
    
    // Get rating information
    final averageRating = therapist['average_rating'] ?? 0.0;
    final totalRatings = therapist['total_ratings'] ?? 0;
    final ratingText = averageRating > 0 
        ? '${averageRating.toStringAsFixed(1)} ⭐ ($totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'})'
        : 'No ratings yet';
    
    // Combine address fields
    final officeAddress = therapist['office_address']?.toString() ?? '';
    final city = therapist['city']?.toString() ?? '';
    final state = therapist['state']?.toString() ?? '';
    final zip = therapist['zip']?.toString() ?? '';
    
    final addressParts = [officeAddress, city, state, zip]
        .where((part) => part.isNotEmpty)
        .toList();
    final fullAddress = addressParts.isEmpty ? 'N/A' : addressParts.join(', ');

    // Safe profile picture URL check
    final profilePictureUrl = therapist['profile_picture_url'];
    final hasValidProfilePicture = profilePictureUrl != null && 
                                   profilePictureUrl is String && 
                                   profilePictureUrl.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: const Color(0xFFF7F4F2),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: _buildProfileImage(
                        therapist['profile_picture_url'],
                        size: 64,
                        iconColor: const Color(0xFF10B981),
                        icon: Icons.verified_user,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 20,
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
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.phone, 'Contact Number', contactNumber),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.psychology, 'Specialization', specialization),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.language, 'Languages', languages),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.business, 'Center Name', centerName),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, 'Address', fullAddress),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.attach_money, 'Hourly Rate', hourlyRate),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.star, 'Rating', ratingText),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF422006),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Nunito',
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  color: Color(0xFF422006),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(String? imageData, {required double size, required Color iconColor, required IconData icon}) {
    if (imageData == null || imageData.isEmpty) {
      return Icon(icon, color: iconColor, size: size / 2);
    }

    // Handle data URI (base64)
    if (imageData.startsWith('data:image')) {
      try {
        final base64String = imageData.split(',').last;
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              return Icon(icon, color: iconColor, size: size / 2);
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return Icon(icon, color: iconColor, size: size / 2);
      }
    }

    // Handle regular URL
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        imageData,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return Icon(icon, color: iconColor, size: size / 2);
        },
      ),
    );
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

                      return GestureDetector(
                        onTap: () => _showTherapistDetails(therapist),
                        child: Container(
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
                                  child: _buildProfileImage(
                                    therapist['profile_picture_url'],
                                    size: 48,
                                    iconColor: const Color(0xFF10B981),
                                    icon: Icons.verified_user,
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Color(0xFFFB923C),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  () {
                                    final avgRating = therapist['average_rating'] ?? 0.0;
                                    final ratings = therapist['total_ratings'] ?? 0;
                                    return avgRating > 0 
                                        ? '${avgRating.toStringAsFixed(1)} ($ratings ${ratings == 1 ? 'rating' : 'ratings'})'
                                        : 'No ratings yet';
                                  }(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Nunito',
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
