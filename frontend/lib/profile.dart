import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'changepassword.dart';
import 'editprofile.dart';
import 'login.dart';

class Profile extends StatefulWidget {
  final String userId;
  const Profile({super.key, required this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<Map<String, dynamic>> _profileFuture;

  Widget _initialsCircle(String initials) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFED7AA),
        border: Border.all(
          color: const Color(0xFFF97316),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
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

  Future<Map<String, dynamic>> _fetchProfile() async {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final resp = await http.get(Uri.parse('$apiUrl/profile/${widget.userId}'));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load profile (${resp.statusCode})');
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
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
        leading: Icon(icon, color: const Color.fromRGBO(66, 32, 6, 1), size: 20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
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
                        Text(
                          'Failed to load profile',
                          style: const TextStyle(
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
                  final fullName = (data['full_name'] as String?) ?? 'User';
                  final initials = (data['initials'] as String?) ?? 'U';
                  final avatarUrl = data['avatar_url'] as String?;
                  final avatarBase64 = data['avatar_base64'] as String?;

                  Widget avatarWidget;
                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
                    avatarWidget = Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF97316),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFFED7AA),
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    );
                  } else if (avatarBase64 != null && avatarBase64.isNotEmpty) {
                    try {
                      final bytes = base64Decode(avatarBase64);
                      avatarWidget = Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFF97316),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFFFED7AA),
                          backgroundImage: MemoryImage(bytes),
                        ),
                      );
                    } catch (_) {
                      avatarWidget = _initialsCircle(initials);
                    }
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
                      const SizedBox(height: 32),
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfile(userId: widget.userId),
                            ),
                          );
                          // Refresh profile data after returning from edit page
                          setState(() {
                            _profileFuture = _fetchProfile();
                          });
                        },
                      ),
                      _buildMenuItem(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
                      _buildMenuItem(icon: Icons.settings_outlined, title: 'Customize Your Companion', onTap: () {}),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePassword(userId: widget.userId),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
                      _buildMenuItem(icon: Icons.email_outlined, title: 'Contact Us', onTap: () {}),
                      _buildMenuItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
                      _buildMenuItem(icon: Icons.person_add_outlined, title: 'Join as a Therapist', onTap: () {}),
                      const SizedBox(height: 24),
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
                                builder: (context) => const LoginWidget(),
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
      // Bottom Navigation Bar
      // We wrap it in a Row/Container to constrain width to "Mobile Size" (375px)
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
                    IconButton(
                      icon: const Icon(Icons.home_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.military_tech_outlined),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_outline),
                      color: const Color.fromRGBO(107, 114, 128, 1),
                      onPressed: () {},
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(249, 115, 22, 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person),
                        color: Colors.white,
                        onPressed: () {},
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
}