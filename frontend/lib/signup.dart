import 'package:flutter/material.dart';

class SignupWidget extends StatefulWidget {
  const SignupWidget({Key? key}) : super(key: key);

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      // For now just show a SnackBar. Replace with real registration call later.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Creating account for $name ($email)')),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/Tile0002.png'),
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      const Text(
                        'Create Account',
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
                        'Sign up to start your wellness journey.',
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
                      // Name field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Full Name',
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
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email field
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
                      // Password field
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
                      const SizedBox(height: 16),
                      // Confirm Password field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Confirm Password',
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
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm your password',
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sign Up button
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
                            'Sign Up',
                            style: TextStyle(fontSize: 18, fontFamily: 'Nunito'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text(
                            "Already have an account? ",
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
        ),
      ),
    );
  }
}
