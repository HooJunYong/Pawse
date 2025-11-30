import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../profile/profile_screen.dart';
import 'manage_schedule_screen.dart';
import 'therapist_dashboard_screen.dart';
import 'therapist_edit_profile_screen.dart';

class TherapistProfileScreen extends StatefulWidget {
  final String userId;

  const TherapistProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  // Theme colors
  static const Color _background = Color.fromRGBO(247, 244, 242, 1);
  static const Color _accent = Color.fromRGBO(249, 115, 22, 1);
  static const Color _textPrimary = Color.fromRGBO(66, 32, 6, 1);

  late Future<Map<String, dynamic>> _profileFuture;
  int _profileImageVersion = 0;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final resp = await http.get(Uri.parse('$apiUrl/therapist/profile/${widget.userId}'));
    
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load therapist profile (${resp.statusCode})');
  }

  Widget _initialsCircle(String initials) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _accent,
          width: 3,
        ),
      ),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFFFED7AA),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 40,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(40)),
                color: Color.fromRGBO(247, 244, 242, 1),
              ),
              padding: const EdgeInsets.all(32),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(66, 32, 6, 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _profileFuture = _fetchProfile());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }

                  final data = snapshot.data!;
                  final firstName = (data['first_name'] as String?) ?? '';
                  final lastName = (data['last_name'] as String?) ?? '';
                  final fullName = 'Dr. $firstName $lastName'.trim();
                  final initials = (firstName.isNotEmpty ? firstName[0] : '') + 
                                   (lastName.isNotEmpty ? lastName[0] : '');
                  final profilePictureUrl = data['profile_picture_url'] as String?;
                  final double ratingValue = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
                  final int ratingCount = (data['rating_count'] as num?)?.toInt() ?? 0;
                  final bool hasRating = ratingCount > 0;
                  String? displayUrl = profilePictureUrl;
                  if (displayUrl != null && _isRemoteUrl(displayUrl) && _profileImageVersion != 0) {
                    final separator = displayUrl.contains('?') ? '&' : '?';
                    displayUrl = '$displayUrl${separator}v=$_profileImageVersion';
                  }

                  Widget avatarWidget;
                  if (_isDataUri(displayUrl)) {
                    final bytes = _decodeDataUri(displayUrl!);
                    if (bytes != null) {
                      avatarWidget = Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFFFED7AA),
                          backgroundImage: MemoryImage(bytes),
                        ),
                      );
                    } else {
                      avatarWidget = _initialsCircle(initials);
                    }
                  } else if (displayUrl != null && displayUrl.isNotEmpty) {
                    avatarWidget = Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFFED7AA),
                        backgroundImage: NetworkImage(displayUrl),
                      ),
                    );
                  } else {
                    avatarWidget = _initialsCircle(initials);
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      avatarWidget,
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(66, 32, 6, 1),
                        ),
                      ),
                      const SizedBox(height: 12), // Spacing between Name and Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Shrink to fit content
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              hasRating ? ratingValue.toStringAsFixed(1) : 'New',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Nunito',
                                color: Color.fromRGBO(66, 32, 6, 1),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasRating
                                  ? '${ratingCount} review${ratingCount == 1 ? '' : 's'}'
                                  : 'No ratings yet',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                color: Color.fromRGBO(156, 163, 175, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Menu Items
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TherapistEditProfileScreen(userId: widget.userId),
                            ),
                          );
                          // If the edit screen returns true, refresh the profile
                          bool shouldRefresh = false;
                          if (result == true) {
                            shouldRefresh = true;
                          } else if (result is Map) {
                            shouldRefresh = result['updated'] == true;
                          }

                          if (shouldRefresh) {
                            setState(() {
                              _profileFuture = _fetchProfile();
                              _profileImageVersion = DateTime.now().millisecondsSinceEpoch;
                            });
                          }
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.email_outlined,
                        title: 'Contact Us',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),
                      
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Profile(userId: widget.userId),
                              ),
                            );
                          },
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 375,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Home Button
                    IconButton(
                      icon: const Icon(Icons.home_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TherapistDashboardScreen(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                    // Chat Button
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {
                        // Navigate to chat
                      },
                    ),
                    // Calendar Button
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageScheduleScreen(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                    // Profile Button (Active)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(249, 115, 22, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person),
                        color: Colors.white,
                        onPressed: () {
                          // Already on profile screen
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: _textPrimary, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color.fromRGBO(107, 114, 128, 1),
        ),
        onTap: onTap,
      ),
    );
  }

  bool _isDataUri(String? value) {
    if (value == null) return false;
    final lower = value.toLowerCase();
    return lower.startsWith('data:image/');
  }

  bool _isRemoteUrl(String? value) {
    if (value == null) return false;
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Uint8List? _decodeDataUri(String dataUri) {
    final parts = dataUri.split(',');
    if (parts.length < 2) {
      return null;
    }
    try {
      return base64Decode(parts.last);
    } catch (_) {
      return null;
    }
  }
}