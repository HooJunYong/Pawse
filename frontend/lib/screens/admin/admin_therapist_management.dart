import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../services/therapist_application_notification_service.dart';

class AdminTherapistManagement extends StatefulWidget {
  final String adminUserId;
  const AdminTherapistManagement({super.key, required this.adminUserId});

  @override
  State<AdminTherapistManagement> createState() => _AdminTherapistManagementState();
}

class _AdminTherapistManagementState extends State<AdminTherapistManagement> {
  List<Map<String, dynamic>> _pendingApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingApplications();
  }

  Future<void> _loadPendingApplications() async {
    setState(() => _isLoading = true);
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$apiUrl/therapist/pending'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Debug: print first application to check fields
        if (data.isNotEmpty) {
          print('First application data: ${data[0]}');
          print('Profile picture URL: ${data[0]['profile_picture_url']}');
        }
        setState(() {
          _pendingApplications = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorDialog('Failed to load applications');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> _approveApplication(String userId, String firstName, String lastName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.put(
        Uri.parse('$apiUrl/therapist/verify/$userId?status=approved'),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200) {
          // Send approval notification to therapist
          await TherapistApplicationNotificationService.showApprovedNotification(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
          );
          
          _showSuccessDialog('$firstName $lastName has been approved as a therapist!');
          _loadPendingApplications(); // Refresh list
        } else {
          _showErrorDialog('Failed to approve application');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Error: $e');
      }
    }
  }

  Future<void> _rejectApplication(String userId, String firstName, String lastName) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reject Application',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejecting $firstName $lastName\'s application:',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Color.fromRGBO(107, 114, 128, 1),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g., License number is invalid...',
                hintStyle: const TextStyle(
                  color: Color.fromRGBO(156, 163, 175, 1),
                  fontFamily: 'Nunito',
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromRGBO(229, 231, 235, 1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromRGBO(229, 231, 235, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromRGBO(249, 115, 22, 1)),
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Nunito',
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Color.fromRGBO(107, 114, 128, 1),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(220, 38, 38, 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, reasonController.text);
            },
            child: const Text(
              'Reject',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
        final response = await http.put(
          Uri.parse('$apiUrl/therapist/verify/$userId?status=rejected'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'rejection_reason': result}),
        );

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          if (response.statusCode == 200) {
            // Send rejection notification to applicant
            await TherapistApplicationNotificationService.showRejectedNotification(
              userId: userId,
              firstName: firstName,
              lastName: lastName,
              rejectionReason: result,
            );
            
            _showSuccessDialog('Application rejected');
            _loadPendingApplications(); // Refresh list
          } else {
            _showErrorDialog('Failed to reject application');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          _showErrorDialog('Error: $e');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Error',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(220, 38, 38, 1),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Color.fromRGBO(249, 115, 22, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Success',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(34, 197, 94, 1),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Color.fromRGBO(249, 115, 22, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    // Debug: Print the application data to see what we're working with
    print('Application details: $application');
    print('Specializations type: ${application['specializations']?.runtimeType ?? 'null'}');
    print('Specializations value: ${application['specializations']}');
    print('Languages type: ${application['languages_spoken']?.runtimeType ?? 'null'}');
    print('Languages value: ${application['languages_spoken']}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(247, 244, 242, 1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(209, 213, 219, 1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailCard('Personal Information', [
                        _buildDetailRow('Name', '${application['first_name'] ?? 'N/A'} ${application['last_name'] ?? 'N/A'}'),
                        _buildDetailRow('Email', application['email']?.toString() ?? 'N/A'),
                        _buildDetailRow('Contact', application['contact_number']?.toString() ?? 'N/A'),
                        _buildDetailRow('License Number', application['license_number']?.toString() ?? 'N/A'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailCard('Office Information', [
                        _buildDetailRow('Office Name', application['office_name']?.toString() ?? 'N/A'),
                        _buildDetailRow('Address', application['office_address']?.toString() ?? 'N/A'),
                        _buildDetailRow('City', application['city']?.toString() ?? 'N/A'),
                        _buildDetailRow('State', application['state']?.toString() ?? 'N/A'),
                        _buildDetailRow('Zip Code', application['zip']?.toString() ?? 'N/A'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailCard('Professional Details', [
                        _buildDetailRow('Hourly Rate', 'RM ${application['hourly_rate']?.toString() ?? '0'}'),
                        _buildChipRow('Specializations', _safeListExtract(application['specializations'])),
                        _buildChipRow('Languages', _safeListExtract(application['languages_spoken'])),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
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
                            const Text(
                              'Bio',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(66, 32, 6, 1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              application['bio'] ?? 'No bio provided',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                color: Color.fromRGBO(107, 114, 128, 1),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(220, 38, 38, 1),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _rejectApplication(
                                  application['user_id'],
                                  application['first_name'],
                                  application['last_name'],
                                );
                              },
                              child: const Text(
                                'Reject',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(34, 197, 94, 1),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _approveApplication(
                                  application['user_id'],
                                  application['first_name'],
                                  application['last_name'],
                                );
                              },
                              child: const Text(
                                'Approve',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic> app) {
    Widget buildPlaceholder() {
      return const Icon(
        Icons.person,
        color: Color.fromRGBO(249, 115, 22, 1),
      );
    }

    Widget buildNetworkAvatar(String url) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
        ),
      );
    }

    Widget? buildMemoryAvatar(String base64Data) {
      if (base64Data.isEmpty) {
        return null;
      }
      try {
        final decoded = base64Decode(base64Data);
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.memory(
            decoded,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return null;
      }
    }

    // Safe string extraction helper
    String? _safeString(dynamic value) {
      if (value == null) return null;
      if (value is! String) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
      return trimmed;
    }

    final profileUrl = _safeString(app['profile_picture_url']);
    final profileBase64 = _safeString(app['profile_picture_base64']);

    if (profileUrl != null) {
      if (profileUrl.startsWith('data:image')) {
        final parts = profileUrl.split(',');
        if (parts.length == 2) {
          final memoryAvatar = buildMemoryAvatar(parts[1]);
          if (memoryAvatar != null) {
            return memoryAvatar;
          }
        }
      } else {
        return buildNetworkAvatar(profileUrl);
      }
    }

    if (profileBase64 != null) {
      final memoryAvatar = buildMemoryAvatar(profileBase64);
      if (memoryAvatar != null) {
        return memoryAvatar;
      }
    }

    return buildPlaceholder();
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(66, 32, 6, 1),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Nunito',
                color: Color.fromRGBO(107, 114, 128, 1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _safeListExtract(dynamic value) {
    try {
      if (value == null) {
        return [];
      }

      if (value is List) {
        final result = <String>[];
        for (final item in value) {
          if (item == null) {
            continue;
          }
          // Handle both String and non-String items
          String text;
          if (item is String) {
            text = item.trim();
          } else if (item is Map) {
            // If it's a map, try to get a 'name' or 'value' field
            text = (item['name'] ?? item['value'] ?? item.toString()).toString().trim();
          } else {
            text = item.toString().trim();
          }
          
          if (text.isEmpty || text.toLowerCase() == 'null') {
            continue;
          }
          result.add(text);
        }
        return result;
      }

      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
          return [];
        }
        // Handle comma-separated strings
        final result = <String>[];
        for (final part in trimmed.split(',')) {
          final text = part.trim();
          if (text.isEmpty || text.toLowerCase() == 'null') {
            continue;
          }
          result.add(text);
        }
        return result;
      }

      return [];
    } catch (e) {
      print('Error in _safeListExtract: $e, value: $value, type: ${value.runtimeType}');
      return [];
    }
  }

  Widget _buildChipRow(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Nunito',
              color: Color.fromRGBO(107, 114, 128, 1),
            ),
          ),
          const SizedBox(height: 8),
          items.isEmpty
              ? Text(
                  'None specified',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(254, 243, 199, 1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromRGBO(249, 115, 22, 0.3),
                      ),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                        color: Color.fromRGBO(146, 64, 14, 1),
                      ),
                    ),
                  )).toList(),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(66, 32, 6, 1)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Therapist Applications',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color.fromRGBO(66, 32, 6, 1)),
            onPressed: _loadPendingApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(249, 115, 22, 1),
              ),
            )
          : _pendingApplications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Pending Applications',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All applications have been reviewed',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Nunito',
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color.fromRGBO(249, 115, 22, 1),
                  onRefresh: _loadPendingApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _pendingApplications.length,
                    itemBuilder: (context, index) {
                      final app = _pendingApplications[index];
                      return InkWell(
                        onTap: () => _showApplicationDetails(app),
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
                                      color: const Color.fromRGBO(254, 243, 199, 1),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: _buildProfileAvatar(app),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${app['first_name']} ${app['last_name']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(66, 32, 6, 1),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          app['email'] ?? 'No email',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Nunito',
                                            color: Color.fromRGBO(107, 114, 128, 1),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Color.fromRGBO(249, 115, 22, 1),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(254, 243, 199, 1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Pending Review',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromRGBO(146, 64, 14, 1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color.fromRGBO(107, 114, 128, 1),
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
