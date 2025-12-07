import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/breathing_models.dart';
import '../../services/breathing_service.dart';

// --- Theme Constants ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _surfaceWhite = Colors.white;
const Color _textDark = Color(0xFF3E2723);
const Color _textGrey = Color(0xFF8D6E63);
const Color _primaryBrown = Color(0xFF5D4037);
const Color _accentFallback = Color(0xFFFB923C);

class BreathingPlayerScreen extends StatefulWidget {
  const BreathingPlayerScreen({
    super.key,
    required this.exercise,
    required this.userId,
    Color? accentColor,
    this.onSessionLogged,
  }) : accentColor = accentColor ?? _accentFallback;

  final BreathingExercise exercise;
  final String userId;
  final Color accentColor;
  final Future<void> Function()? onSessionLogged;

  @override
  State<BreathingPlayerScreen> createState() => _BreathingPlayerScreenState();
}

class _BreathingPlayerScreenState extends State<BreathingPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final BreathPattern _pattern = widget.exercise.pattern;
  late AnimationController _radiusController;
  late Animation<double> _radiusAnimation;
  final BreathingApiService _breathingService = BreathingApiService();

  Timer? _stepTimer;
  int _currentCycle = 0;
  int _stepIndex = 0;
  int _remainingInStep = 0;
  bool _isRunning = false;
  bool _hasStartedSession = false;
  bool _hasLoggedSession = false;
  bool _isSaving = false;
  DateTime? _sessionStart;

  bool get _hasValidPattern =>
      _pattern.steps.isNotEmpty && _pattern.cycles > 0;

  BreathStep get _currentStep => _pattern.steps[_stepIndex];
  Color get _accentColor => widget.accentColor;

  @override
  void initState() {
    super.initState();
    _radiusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
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
    _stepTimer?.cancel();
    _radiusController.stop();
    _radiusController.reset();
    setState(() {
      _stepIndex = 0;
      _currentCycle = 0;
      _remainingInStep =
          _pattern.steps.isNotEmpty ? _pattern.steps.first.seconds : 0;
      _isRunning = false;
      _hasStartedSession = false;
      _hasLoggedSession = false;
      _isSaving = false;
    });
    _sessionStart = null;
  }

  void _startPattern() {
    if (!_hasValidPattern) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This breathing exercise is currently unavailable.'),
        ),
      );
      return;
    }

    if (_isRunning) {
      _pausePattern();
      return;
    }

    setState(() {
      _isRunning = true;
      _hasStartedSession = true;
      _hasLoggedSession = false;
      _sessionStart ??= DateTime.now();
    });

    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _animateBreathStep();
  }

  void _animateBreathStep() {
    if (!_hasValidPattern) {
      return;
    }
    final BreathStep step = _currentStep;
    final String label = step.label.toLowerCase();
    final Duration duration = Duration(seconds: step.seconds);

    if (label.contains('inhale')) {
      _radiusController.animateTo(1.0, duration: duration);
    } else if (label.contains('exhale')) {
      _radiusController.animateTo(0.0, duration: duration);
    } else {
      _radiusController.stop();
    }
  }

  void _pausePattern() {
    _stepTimer?.cancel();
    _radiusController.stop();
    setState(() => _isRunning = false);
  }

  void _tick() {
    if (!_hasValidPattern) {
      _pausePattern();
      return;
    }
    if (_remainingInStep > 1) {
      setState(() => _remainingInStep -= 1);
      return;
    }

    final bool isLastStep = _stepIndex == _pattern.steps.length - 1;
    if (isLastStep) {
      final bool isLastCycle = _currentCycle >= _pattern.cycles - 1;
      if (isLastCycle) {
        unawaited(_completePattern());
        return;
      }
      setState(() {
        _currentCycle += 1;
        _stepIndex = 0;
        _remainingInStep = _pattern.steps.first.seconds;
      });
    } else {
      setState(() {
        _stepIndex += 1;
        _remainingInStep = _pattern.steps[_stepIndex].seconds;
      });
    }

    if (_isRunning) {
      _animateBreathStep();
    }
  }

  Future<void> _completePattern() async {
    _pausePattern();
    final DateTime completedAt = DateTime.now();
    setState(() {
      _currentCycle = _pattern.cycles;
      _remainingInStep = 0;
    });

    await _logSession(
      cyclesCompleted: _pattern.cycles,
      completedAt: completedAt,
    );

    if (!mounted) {
      return;
    }

    await showDialog<void>(
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
          'Your breathing session has been saved to your history.',
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
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
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
              Navigator.of(context).pop();
              _resetStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  Future<void> _logSession({
    required int cyclesCompleted,
    required DateTime completedAt,
  }) async {
    if (!_hasStartedSession || _hasLoggedSession) {
      return;
    }

    if (widget.userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to track your breathing history.'),
          ),
        );
      }
    }

    final DateTime startedAt = _sessionStart ?? completedAt;
    final int totalCycles = _pattern.cycles;
    final int safeCycles = max(0, min(cyclesCompleted, totalCycles));
    final int rawDuration = completedAt.difference(startedAt).inSeconds;
    final int durationSeconds = rawDuration <= 0 ? 1 : rawDuration;

    try {
      if (widget.userId.isEmpty) {
        throw Exception('missing-user');
      }
      setState(() => _isSaving = true);
      await _breathingService.logSession(
        userId: widget.userId,
        exerciseId: widget.exercise.exerciseId,
        cyclesCompleted: safeCycles,
        startedAt: startedAt,
        completedAt: completedAt,
        durationSeconds: durationSeconds,
      );
      _hasLoggedSession = true;
      _hasStartedSession = false;
      _sessionStart = null;
      if (widget.onSessionLogged != null) {
        try {
          await widget.onSessionLogged!();
        } catch (_) {
          // Ignore refresh failures; the list screen can retry later.
        }
      }
    } catch (error) {
      if (mounted && error.toString() != 'Exception: missing-user') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not save your breathing session. Please try again later.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasLoggedSession = true;
          _hasStartedSession = false;
        });
      }
      _sessionStart = null;
    }
  }

  bool get _isSessionInProgress {
    if (!_hasStartedSession) {
      return false;
    }
    if (_hasLoggedSession) {
      return false;
    }
    return true;
  }

  Future<bool> _handleExitRequest() async {
    if (!_isSessionInProgress) {
      return true;
    }

    _pausePattern();

    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit Session?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        content: const Text(
          'Your progress so far will be saved as incomplete.',
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: _textGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Exit',
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

    if (shouldExit == true) {
      await _logSession(
        cyclesCompleted: min(_currentCycle, _pattern.cycles),
        completedAt: DateTime.now(),
      );
      return true;
    }

    if (shouldExit == false && _hasValidPattern && !_isRunning) {
      // Let the user resume manually; keep state paused.
    }

    return false;
  }

  String _formattedCycleLabel() {
    if (!_hasValidPattern) {
      return 'No pattern available';
    }
    final int current = min(_currentCycle + 1, _pattern.cycles);
    return 'Cycle $current of ${_pattern.cycles}';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSteps = _hasValidPattern;
    final String primaryInstruction = hasSteps
        ? _currentStep.label.toUpperCase()
        : 'READY';
    final int secondsDisplay = hasSteps ? _remainingInStep : 0;
    final int totalSteps = hasSteps
        ? _pattern.steps.length * _pattern.cycles
        : 0;
    final int completedSteps = hasSteps
        ? (_currentCycle * _pattern.steps.length + _stepIndex)
        : 0;
    final double progress = totalSteps == 0
        ? 0
        : completedSteps / totalSteps;

    return WillPopScope(
      onWillPop: _handleExitRequest,
      child: Scaffold(
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: _textDark),
                        onPressed: () async {
                          final bool shouldExit = await _handleExitRequest();
                          if (shouldExit && mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          widget.exercise.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _textDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _resetStep,
                        child: Text(
                          'RESET',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                              SizedBox(
                                height: 300,
                                width: 300,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _radiusAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: 200 +
                                              (_radiusAnimation.value * 80),
                                          height: 200 +
                                              (_radiusAnimation.value * 80),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _accentColor.withOpacity(
                                              0.1 +
                                                  (_radiusAnimation.value *
                                                      0.2),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    AnimatedBuilder(
                                      animation: _radiusAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: 180 +
                                              (_radiusAnimation.value * 40),
                                          height: 180 +
                                              (_radiusAnimation.value * 40),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _surfaceWhite,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _accentColor
                                                    .withOpacity(0.2),
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
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    fontSize: 20,
                                                    color: _textDark,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  hasSteps
                                                      ? '${secondsDisplay}s'
                                                      : '--',
                                                  style: TextStyle(
                                                    fontFamily: 'Nunito',
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 42,
                                                    color: _accentColor,
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: _bgCream,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    _accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
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
                                        color:
                                            _primaryBrown.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              if (_isSaving)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: CircularProgressIndicator(),
                                ),
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
      ),
    );
  }
}