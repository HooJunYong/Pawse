import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/breathing_models.dart';
import '../../services/breathing_service.dart';
import 'breathing_player_screen.dart';

// --- Theme Constants ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _textDark = Color(0xFF3E2723);
const Color _textGrey = Color(0xFF8D6E63);
const Color _surfaceWhite = Colors.white;

// Accent palette fallbacks
const Color _orangeAccent = Color(0xFFFB923C);
const Color _blueAccent = Color(0xFF60A5FA);
const Color _greenAccent = Color(0xFF34D399);
const Color _bronzeAccent = Color(0xFFF59E0B);

// Soft shadow for cards
final List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: const Color(0xFF5D4037).withOpacity(0.06),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];

const Map<String, IconData> _iconLookup = {
  'crop_square_rounded': Icons.crop_square_rounded,
  'nightlight_round': Icons.nightlight_round,
  'air': Icons.air,
  'self_improvement': Icons.self_improvement,
};

class BreathingListScreen extends StatefulWidget {
  const BreathingListScreen({super.key, required this.userId});

  final String userId;

  @override
  State<BreathingListScreen> createState() => _BreathingListScreenState();
}

class _BreathingListScreenState extends State<BreathingListScreen> {
  final BreathingApiService _service = BreathingApiService();
  final List<Color> _fallbackColors = const <Color>[
    _orangeAccent,
    _blueAccent,
    _greenAccent,
    _bronzeAccent,
  ];

  List<BreathingExercise> _exercises = <BreathingExercise>[];
  List<BreathingSession> _sessions = <BreathingSession>[];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAllData());
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<BreathingExercise> exercises = await _service.getExercises();
      final List<BreathingSession> sessions = widget.userId.isNotEmpty
          ? await _service.getSessions(widget.userId)
          : <BreathingSession>[];
      if (!mounted) return;
      setState(() {
        _exercises = exercises;
        _sessions = sessions;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load breathing exercises right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshSessions() async {
    if (widget.userId.isEmpty) {
      return;
    }
    try {
      final List<BreathingSession> sessions =
          await _service.getSessions(widget.userId);
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
      });
    } catch (_) {
      // Fail silently or show small snackbar
    }
  }

  Color _resolveExerciseColor(BreathingExercise exercise, int index) {
    final dynamic hexValue = exercise.metadata?['color_hex'];
    if (hexValue is String) {
      final Color? parsed = _parseColor(hexValue);
      if (parsed != null) {
        return parsed;
      }
    }
    return _fallbackColors[index % _fallbackColors.length];
  }

  IconData _resolveExerciseIcon(BreathingExercise exercise) {
    final dynamic iconValue = exercise.metadata?['icon'];
    if (iconValue is String && _iconLookup.containsKey(iconValue)) {
      return _iconLookup[iconValue]!;
    }
    return Icons.self_improvement;
  }

  String _resolveDurationLabel(BreathingExercise exercise) {
    if (exercise.durationLabel != null && exercise.durationLabel!.isNotEmpty) {
      return exercise.durationLabel!;
    }
    final int seconds =
        exercise.durationSeconds ?? exercise.pattern.totalSeconds;
    if (seconds <= 0) {
      return '';
    }
    final int minutes = (seconds / 60).ceil();
    return minutes == 1 ? '1 min' : '$minutes min';
  }

  Future<void> _openExercise(
      BreathingExercise exercise, Color accentColor) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BreathingPlayerScreen(
          userId: widget.userId,
          exercise: exercise,
          accentColor: accentColor,
          onSessionLogged: _refreshSessions,
        ),
      ),
    );
    // Refresh history after returning from player
    if (mounted) {
      await _refreshSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Breathing',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _textDark,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _textDark));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: _textGrey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Nunito', color: _textGrey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _textDark,
      onRefresh: _loadAllData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          if (_exercises.isEmpty)
            _buildEmptyState()
          else
            ..._buildExerciseTiles(),
          
          const SizedBox(height: 32),
          
          // History Section Title
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              "Recent Sessions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
                color: _textDark,
              ),
            ),
          ),
          _buildHistorySection(),
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  List<Widget> _buildExerciseTiles() {
    final List<Widget> tiles = [];
    for (int index = 0; index < _exercises.length; index++) {
      final BreathingExercise exercise = _exercises[index];
      final Color accentColor = _resolveExerciseColor(exercise, index);
      final IconData icon = _resolveExerciseIcon(exercise);
      tiles.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BreathingExerciseTile(
            icon: icon,
            color: accentColor,
            title: exercise.name,
            subtitle: exercise.description,
            duration: _resolveDurationLabel(exercise),
            onTap: () => _openExercise(exercise, accentColor),
          ),
        ),
      );
    }
    return tiles;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: const [
          Icon(Icons.self_improvement, color: _textGrey, size: 48),
          SizedBox(height: 16),
          Text(
            'No exercises available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Nunito', color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: const Center(
          child: Text(
            'Start a guided exercise to track your progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: _textGrey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Sort sessions by date (newest first)
    final sortedSessions = List<BreathingSession>.from(_sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return Column(
      children: sortedSessions.map((session) {
        final exercise = _exercises.firstWhere(
          (e) => e.exerciseId == session.exerciseId,
          orElse: () => BreathingExercise(
            exerciseId: session.exerciseId,
            name: 'Breathing Exercise',
            description: '',
            pattern: BreathPattern(steps: [], cycles: 0),
          ),
        );
        return _BreathingHistoryCard(session: session, exercise: exercise);
      }).toList(),
    );
  }

  static Color? _parseColor(String hex) {
    final String cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return null;
  }
}

class BreathingExerciseTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String duration;
  final VoidCallback onTap;

  const BreathingExerciseTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.duration = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colored Icon Box
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (duration.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _bgCream,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                duration,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _textGrey,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: _textGrey.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Icon(Icons.play_circle_fill_rounded, 
                    color: _textDark, 
                    size: 28
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

class _BreathingHistoryCard extends StatelessWidget {
  const _BreathingHistoryCard({
    required this.session,
    required this.exercise,
  });

  final BreathingSession session;
  final BreathingExercise exercise;

  @override
  Widget build(BuildContext context) {
    final DateTime start = session.startedAt;
    final DateFormat dayFormat = DateFormat('d');
    final DateFormat monthFormat = DateFormat('MMM');
    final DateFormat timeFormat = DateFormat('h:mm a');

    // Calculate cycles if pattern exists
    final BreathPattern pattern = exercise.pattern;
    final bool hasPattern = pattern.cycles > 0 && pattern.steps.isNotEmpty;
    final int? totalCycles = hasPattern ? pattern.cycles : null;
    
    final bool isComplete =
        totalCycles != null && session.cyclesCompleted >= totalCycles;
    final String statusText = isComplete ? 'Completed' : 'Incomplete';
    final Color statusColor = isComplete ? _greenAccent : _orangeAccent;
    final String cyclesLabel = totalCycles != null
        ? '${session.cyclesCompleted}/${totalCycles} cycles'
        : '${session.cyclesCompleted} cycles';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
        border: Border.all(color: _textDark.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Calendar Leaf Date
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _bgCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _textDark.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayFormat.format(start),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthFormat.format(start).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(start),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: _textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cyclesLabel,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: _textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}