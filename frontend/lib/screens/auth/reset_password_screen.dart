      import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ResetPassword extends StatefulWidget {
  final String email;
  final String? otpCode;
  const ResetPassword({super.key, required this.email, this.otpCode});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromRGBO(249, 115, 22, 1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
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

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // Check if new password is empty
    if (_newPasswordController.text.isEmpty) {
      _showErrorDialog('Please enter a new password');
      return;
    }

    // Check if new password meets minimum length
    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return;
    }

    // Check if passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$apiUrl/otp/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': widget.otpCode ?? '',
          'new_password': _newPasswordController.text,
        }),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (response.statusCode == 200) {
          // Show success message and navigate to login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to login screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          final error = jsonDecode(response.body);
          _showErrorDialog(error['detail'] ?? 'Failed to reset password');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error: $e');
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color.fromRGBO(107, 114, 128, 1),
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 375,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Lock icon
                      Image.asset(
                        'assets/images/resetpassword1.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.lock_reset,
                          size: 64,
                          color: Color.fromRGBO(249, 115, 22, 1),
                        ),
                      ),
                      const SizedBox(height: 24),
                  const Text(
                    'Create New Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your new password must be unique\nfrom those previously used.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      color: Color.fromRGBO(107, 114, 128, 1),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPasswordField(
                    label: 'New Password',
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    onToggleVisibility: () {
                      setState(() => _obscureNewPassword = !_obscureNewPassword);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    onToggleVisibility: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _resetPassword,
                      child: const Text(
                        'Reset Password',
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}