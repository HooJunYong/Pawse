import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'otp_screen.dart';

class ForgotPasswordWidget extends StatefulWidget {
  const ForgotPasswordWidget({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordWidget> createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      
      setState(() => _isLoading = true);

      try {
        final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
        final response = await http.post(
          Uri.parse('$apiUrl/otp/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reset code sent to $email'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpWidget(email: email),
            ),
          );
        } else {
          final error = jsonDecode(response.body);
          String errorMessage = error['detail'] ?? 'An error occurred';
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(response.statusCode == 404 ? 'Account Not Found' : 'Error'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connection Error'),
            content: Text('Failed to connect to server: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(40)),
                color: Color.fromRGBO(247, 244, 242, 1),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Mail Icon
                  Image.asset(
                    'assets/images/letter.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.mail_outline,
                      size: 70,
                      color: Color.fromRGBO(249, 115, 22, 1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(66, 32, 6, 1),
                      fontFamily: 'Nunito',
                      fontSize: 30,
                      fontWeight: FontWeight.normal,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No worries! Enter your email and we\'ll send you a reset code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(107, 114, 128, 1),
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Email field
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Color.fromRGBO(75, 85, 99, 1),
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              height: 1.4285714285714286,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.06),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              )
                            ],
                            color: const Color.fromRGBO(255, 255, 255, 1),
                            border: Border.all(
                              color: const Color.fromRGBO(229, 231, 235, 1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}")
                                  .hasMatch(value.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Send Code button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999)),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Send Code',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Nunito',
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Remembered your password? ",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromRGBO(107, 114, 128, 1),
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          height: 1.4285714285714286,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Log In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromRGBO(249, 115, 22, 1),
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            height: 1.4285714285714286,
                          ),
                        ),
                      ),
                    ],
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
