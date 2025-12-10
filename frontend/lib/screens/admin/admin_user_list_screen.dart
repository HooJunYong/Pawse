import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AdminUserListScreen extends StatefulWidget {
  final String adminUserId;
  const AdminUserListScreen({super.key, required this.adminUserId});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$apiUrl/admin/users'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final fullName = user['full_name'] ?? '$firstName $lastName'.trim();
    final email = user['email'] ?? 'N/A';
    final contactNumber = user['contact_number'] ?? 'N/A';
    final gender = user['gender'] ?? 'N/A';
    final dateOfBirth = _formatDate(user['date_of_birth']);
    
    // Combine address fields
    final homeAddress = user['home_address'] ?? '';
    final city = user['city'] ?? '';
    final state = user['state'] ?? '';
    final zip = user['zip'] ?? '';
    
    final addressParts = [homeAddress, city, state, zip]
        .where((part) => part.isNotEmpty)
        .toList();
    final fullAddress = addressParts.isEmpty ? 'N/A' : addressParts.join(', ');

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
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: user['profile_picture'] != null && 
                             user['profile_picture'].toString().isNotEmpty &&
                             user['profile_picture'] != ''
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.network(
                                user['profile_picture'],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Color(0xFF3B82F6),
                                    size: 32,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Color(0xFF3B82F6),
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? 'Unknown User' : fullName,
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
                _buildDetailRow(Icons.person_outline, 'Gender', gender),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.cake, 'Date of Birth', dateOfBirth),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.home, 'Address', fullAddress),
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
          'All Users',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF422006)),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF97316),
              ),
            )
          : _users.isEmpty
              ? const Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return GestureDetector(
                        onTap: () => _showUserDetails(user),
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
                                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: user['profile_picture'] != null && 
                                         user['profile_picture'].toString().isNotEmpty &&
                                         user['profile_picture'] != ''
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: Image.network(
                                            user['profile_picture'],
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                color: Color(0xFF3B82F6),
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Color(0xFF3B82F6),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (user['full_name'] as String?) ?? 
                                        ('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isEmpty 
                                            ? 'Unknown User' 
                                            : '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF422006),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user['email'] ?? 'No email',
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
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Created: ${_formatDate(user['created_at'])}',
                                  style: const TextStyle(
                                    fontSize: 12,
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
