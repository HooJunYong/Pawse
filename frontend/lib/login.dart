import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Generated Figma layout wrapped into a reusable widget.
class LoginWidget extends StatelessWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              height: 812,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                color: Color.fromRGBO(247, 244, 242, 1),
              ),
              child: Stack(
                children: <Widget>[
                  const Positioned(top: 0, left: 0, child: SizedBox.shrink()),
                  const Positioned(top: 778, left: 0, child: SizedBox.shrink()),
                  Positioned(
                    top: 44,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Container(
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(9999)),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Container(
                                                    width: 150,
                                                    height: 150,
                                                    child: Stack(
                                                      children: <Widget>[
                                                        Positioned(
                                                          top: 0,
                                                          left: 0,
                                                          child: SvgPicture.asset(
                                                            'assets/images/vector.svg',
                                                            semanticsLabel: 'vector',
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 28.5,
                                                          left: 28.5,
                                                          child: Container(
                                                            width: 100,
                                                            height: 100,
                                                            decoration: const BoxDecoration(
                                                              image: DecorationImage(
                                                                image: AssetImage('assets/images/Tile0002.png'),
                                                                fit: BoxFit.fitWidth,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const <Widget>[
                                Text(
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const <Widget>[
                                Text(
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                          // Email field label + placeholder box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text(
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
                                const SizedBox(height: 4.5),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.25),
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    )],
                                    color: const Color.fromRGBO(255, 255, 255, 1),
                                    border: Border.all(
                                      color: const Color.fromRGBO(229, 231, 235, 1),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
                                  child: Row(
                                    children: const <Widget>[
                                      Expanded(
                                        child: Text(
                                          'you@example.com',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            color: Color.fromRGBO(156, 163, 175, 1),
                                            fontFamily: 'Nunito',
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password label + placeholder
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text(
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
                                const SizedBox(height: 4.5),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.25),
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    )],
                                    color: const Color.fromRGBO(255, 255, 255, 1),
                                    border: Border.all(
                                      color: const Color.fromRGBO(229, 231, 235, 1),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
                                  child: Row(
                                    children: const <Widget>[
                                      Expanded(
                                        child: Text(
                                          '••••••••',
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            color: Color.fromRGBO(156, 163, 175, 1),
                                            fontFamily: 'Nunito',
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                          // Log In button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999),
                                    boxShadow: const [BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.25),
                                      offset: Offset(0, 4),
                                      blurRadius: 4,
                                    )],
                                    color: const Color.fromRGBO(66, 32, 6, 1),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                                  child: const Center(
                                    child: Text(
                                      'Log In',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color.fromRGBO(255, 255, 255, 1),
                                        fontFamily: 'Nunito',
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal,
                                        height: 1.5555555555555556,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const <Widget>[
                                Text(
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text(
                                  "Don't have an an account? ",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(107, 114, 128, 1),
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    height: 1.4285714285714286,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    // TODO: navigate to signup
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
                          ),
                        ],
                      ),
                    ),
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

