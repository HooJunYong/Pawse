import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// --- Theme Constants ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _surfaceWhite = Colors.white;
const Color _textDark = Color(0xFF3E2723);
const Color _textGrey = Color(0xFF8D6E63);
const Color _primaryBrown = Color(0xFF5D4037);
const Color _accentOrange = Color(0xFFFB923C);

class BreathStep {
  const BreathStep({required this.label, required this.seconds});

  final String label;
  final int seconds;
}

class BreathPattern {
  const BreathPattern({required this.steps, this.cycles = 4});

  final List<BreathStep> steps;
  final int cycles;

  int get totalSeconds =>
      steps.fold<int>(0, (sum, step) => sum + step.seconds) * cycles;
}

class BreathingPlayerScreen extends StatefulWidget {
  const BreathingPlayerScreen(
      {Key? key, required this.title, required this.pattern})
      : super(key: key);

  final String title;
  final BreathPattern pattern;

  @override
  State<BreathingPlayerScreen> createState() => _BreathingPlayerScreenState();
}

class _BreathingPlayerScreenState extends State<BreathingPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radiusController;
  late Animation<double> _radiusAnimation;
  Timer? _stepTimer;
  int _currentCycle = 0;
  int _stepIndex = 0;
  int _remainingInStep = 0;
  bool _isRunning = false;

  BreathStep get _currentStep => widget.pattern.steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    // Animation for breathing circle
    _radiusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Slower, more relaxing default
    );
    
    _radiusAnimation = CurvedAnimation(
      parent: _radiusController,
      curve: Curves.easeInOut,
    );

    _resetStep();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _radiusController.dispose();
    super.dispose();
  }

  void _resetStep() {
    setState(() {
      _stepIndex = 0;
      _currentCycle = 0;
      _remainingInStep = widget.pattern.steps.first.seconds;
      _isRunning = false;
    });
    _stepTimer?.cancel();
    _radiusController.stop();
    _radiusController.reset(); 
  }

  void _startPattern() {
    if (_isRunning) {
      _pausePattern();
      return;
    }
    setState(() => _isRunning = true);
    
    // Start timer
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    
    // Sync animation with breathing step
    _animateBreathStep();
  }

  void _animateBreathStep() {
    // Simple animation logic: Expand on "Inhale", Contract on "Exhale", Hold on "Hold"
    final label = _currentStep.label.toLowerCase();
    final duration = Duration(seconds: _currentStep.seconds);

    if (label.contains('inhale')) {
      _radiusController.animateTo(1.0, duration: duration);
    } else if (label.contains('exhale')) {
      _radiusController.animateTo(0.0, duration: duration);
    } else {
      // Hold: Stop animation at current value
      _radiusController.stop();
    }
  }

  void _pausePattern() {
    _stepTimer?.cancel();
    _radiusController.stop();
    setState(() => _isRunning = false);
  }

  void _tick() {
    if (_remainingInStep > 1) {
      setState(() => _remainingInStep -= 1);
      return;
    }

    final bool isLastStep = _stepIndex == widget.pattern.steps.length - 1;
    if (isLastStep) {
      final bool isLastCycle = _currentCycle == widget.pattern.cycles - 1;
      if (isLastCycle) {
        _completePattern();
        return;
      }
      setState(() {
        _currentCycle += 1;
        _stepIndex = 0;
        _remainingInStep = widget.pattern.steps[_stepIndex].seconds;
      });
    } else {
      setState(() {
        _stepIndex += 1;
        _remainingInStep = widget.pattern.steps[_stepIndex].seconds;
      });
    }
    // Trigger animation for the new step
    if (_isRunning) _animateBreathStep();
  }

  void _completePattern() {
    _pausePattern();
    setState(() {
      _currentCycle = widget.pattern.cycles;
      _remainingInStep = 0;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Well Done!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        content: const Text(
          'You have completed your breathing session.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: _textGrey,
            fontSize: 16,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to Home
            },
            child: const Text(
              'Home',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: _textGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _resetStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'One More Set',
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

  String _formattedCycleLabel() {
    final current = min(_currentCycle + 1, widget.pattern.cycles);
    return 'Cycle $current of ${widget.pattern.cycles}';
  }

  @override
  Widget build(BuildContext context) {
    final String primaryInstruction = _currentStep.label.toUpperCase();
    final double progress = (_currentCycle * widget.pattern.steps.length + _stepIndex) / 
                           (widget.pattern.cycles * widget.pattern.steps.length);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgCream, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- AppBar ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: _textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetStep,
                      child: const Text(
                        'RESET',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: _accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Scrollable Body for Overflow Protection ---
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            
                            // --- Breathing Circle ---
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow
                                  AnimatedBuilder(
                                    animation: _radiusAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 200 + (_radiusAnimation.value * 80),
                                        height: 200 + (_radiusAnimation.value * 80),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _accentOrange.withOpacity(0.1 + (_radiusAnimation.value * 0.2)),
                                        ),
                                      );
                                    },
                                  ),
                                  // Main Circle
                                  AnimatedBuilder(
                                    animation: _radiusAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 180 + (_radiusAnimation.value * 40),
                                        height: 180 + (_radiusAnimation.value * 40),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _surfaceWhite,
                                          boxShadow: [
                                            BoxShadow(
                                              color: _accentOrange.withOpacity(0.2),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                primaryInstruction,
                                                style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 20,
                                                  color: _textDark,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${_remainingInStep}s',
                                                style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 42,
                                                  color: _accentOrange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),

                            // --- Progress Info ---
                            Text(
                              _formattedCycleLabel(),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textGrey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Simple progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: _bgCream,
                                valueColor: const AlwaysStoppedAnimation<Color>(_accentOrange),
                              ),
                            ),
                            
                            const SizedBox(height: 48),

                            // --- Play/Pause Button ---
                            GestureDetector(
                              onTap: _startPattern,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _primaryBrown,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryBrown.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40), // Bottom padding
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}