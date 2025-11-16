import 'package:flutter/material.dart';

import 'signup.dart';

// Generated Figma layout wrapped into a reusable widget.
class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      // For now just show a SnackBar. Replace with real auth call later.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logging in as $email')),
      );
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
                  // Logo
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFED7AA),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          offset: Offset(0, 2),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Center(
                        child: Image.asset(
                          'assets/images/tile001.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back!',
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
                    'Log in to continue your wellness journey.',
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
                  // Email field label + input
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
                        const SizedBox(height: 16),
                        // Password label + input
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
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
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Log In button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999)),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Nunito',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(107, 114, 128, 1),
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      height: 1.4285714285714286,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Don't have an account? ",
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupWidget(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
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