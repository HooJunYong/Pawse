import 'package:flutter/material.dart';
import 'dart:async';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // State to handle the text fading in AFTER the high five
  bool _isTextVisible = false;

  @override
  void initState() {
    super.initState();

    // Setup the Animation Controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Slightly longer for the elastic bounce
      vsync: this,
    );

    // Define the "High Five" Physics
    _scaleAnimation = Tween<double>(begin: 2.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceOut, 
      ),
    );

    // Fade in quickly so it doesn't look glitchy
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Start the animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // A slight delay before the paw slaps the screen
    await Future.delayed(Duration(milliseconds: 300));
    _controller.forward();

    // Show the text 500ms after the paw hits
    await Future.delayed(Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isTextVisible = true;
      });
    }

    // Navigate away after the whole show is done
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    // Total wait time (Animation + Reading time)
    await Future.delayed(Duration(seconds: 3));
    
    if (mounted) {
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginWidget()),
       );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color(0xFFF7F4F2);
    final contentColor = Color(0xFF4F3422);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // THE PAW (High Fiving)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Image.asset(
                      'assets/images/paw_logo.png',
                      width: 120, 
                      height: 120,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 30),
            
            // THE TEXT (Fades in gently after impact)
            AnimatedOpacity(
              opacity: _isTextVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOut,
              child: Text(
                'PAWSE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}