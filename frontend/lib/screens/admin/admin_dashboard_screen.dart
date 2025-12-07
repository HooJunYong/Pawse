import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../auth/login_screen.dart';
import 'admin_therapist_management.dart';
import 'admin_user_list_screen.dart';
import 'admin_verified_therapist_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminUserId;
  const AdminDashboardScreen({super.key, required this.adminUserId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _totalUsers = 0;
  int _verifiedTherapists = 0;
  int _pendingVerifications = 0;
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      
      // Load admin profile
      final adminResponse = await http.get(
        Uri.parse('$apiUrl/profile/${widget.adminUserId}'),
      );
      
      if (adminResponse.statusCode == 200) {
        final adminData = jsonDecode(adminResponse.body);
        setState(() {
          _adminName = adminData['full_name'] ?? 'Admin';
        });
      }

      // Load dashboard stats
      final statsResponse = await http.get(
        Uri.parse('$apiUrl/admin/dashboard-stats'),
      );

      if (statsResponse.statusCode == 200) {
        final stats = jsonDecode(statsResponse.body);
        setState(() {
          _totalUsers = stats['total_users'] ?? 0;
          _verifiedTherapists = stats['verified_therapists'] ?? 0;
          _pendingVerifications = stats['pending_verifications'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Color(0xFF422006),
          ),
        ),
        backgroundColor: const Color(0xFFF7F4F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Color(0xFF422006),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginWidget()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
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
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Nunito',
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF97316),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, $_adminName',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF422006),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Welcome to Admin Dashboard',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Color(0xFF422006),
                              ),
                              onPressed: _logout,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Stats Cards
                        _buildStatCard(
                          title: 'Total Users',
                          count: _totalUsers.toString(),
                          color: const Color(0xFF3B82F6),
                          icon: Icons.people,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminUserListScreen(
                                  adminUserId: widget.adminUserId,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildStatCard(
                          title: 'Verified Therapists',
                          count: _verifiedTherapists.toString(),
                          color: const Color(0xFF10B981),
                          icon: Icons.verified_user,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminVerifiedTherapistListScreen(
                                  adminUserId: widget.adminUserId,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildStatCard(
                          title: 'Pending Verifications',
                          count: _pendingVerifications.toString(),
                          color: const Color(0xFFF97316),
                          icon: Icons.pending_actions,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminTherapistManagement(
                                  adminUserId: widget.adminUserId,
                                ),
                              ),
                            ).then((_) => _loadDashboardData()); // Refresh after returning
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
