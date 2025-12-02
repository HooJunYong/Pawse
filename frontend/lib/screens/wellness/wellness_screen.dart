import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/breathing_models.dart';
import '../../models/journal_model.dart';
import '../../services/breathing_service.dart';
import '../../services/journal_service.dart';
import '../../services/meditation_progress_service.dart';
import '../../widgets/bottom_nav.dart';
import 'breathing_list_screen.dart';
import 'journaling_screen.dart';
import 'meditation_screen.dart';
import 'music/music_home_screen.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key, required this.userId});

  final String userId;

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  bool _isProgressLoading = false;
  String? _progressError;
  List<_ProgressStatus> _dailyProgress = const [];

  @override
  void initState() {
    super.initState();
    _loadDailyProgress();
  }

  @override
  Widget build(BuildContext context) {
    final _DailyRecommendation recommendation = _getDailyRecommendation(context);
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Wellness Activities',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: recommendation.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Recommendation",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(66, 32, 6, 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                recommendation.icon,
                                size: 18,
                                color: const Color.fromRGBO(66, 32, 6, 1),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                recommendation.activityLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  color: Color.fromRGBO(66, 32, 6, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          recommendation.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Nunito',
                            color: Color.fromRGBO(92, 64, 51, 1),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: recommendation.buttonColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 2,
                          ),
                          onPressed: recommendation.onStart,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start Now',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Explore Activities',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityCard(
                          'Journaling',
                          Icons.menu_book,
                          const Color.fromRGBO(251, 146, 60, 1),
                          () => _openJournaling(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActivityCard(
                          'Breathing',
                          Icons.air,
                          const Color.fromRGBO(251, 146, 60, 1),
                          () => _openBreathing(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityCard(
                          'Meditation',
                          Icons.self_improvement,
                          const Color.fromRGBO(251, 191, 36, 1),
                          () => _openMeditation(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActivityCard(
                          'Music',
                          Icons.music_note,
                          const Color.fromRGBO(236, 72, 153, 1),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MusicHomeScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        userId: widget.userId,
        selectedIndex: 4,
        onTap: (index) {},
      ),
    );
  }

  void _openJournaling(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalingScreen(userId: widget.userId),
      ),
    ).then((_) {
      if (!mounted) return;
      _loadDailyProgress();
    });
  }

  void _openBreathing(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreathingListScreen(userId: widget.userId),
      ),
    ).then((_) {
      if (!mounted) return;
      _loadDailyProgress();
    });
  }

  void _openMeditation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationScreen(userId: widget.userId),
      ),
    ).then((_) {
      if (!mounted) return;
      _loadDailyProgress();
    });
  }

  Widget _buildProgressSection() {
    if (_isProgressLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> items = [];

    if (_progressError != null) {
      items.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFFF97316)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _progressError!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      items.add(const SizedBox(height: 12));
    }

    if (_dailyProgress.isEmpty) {
      items.add(
        _buildProgressItem(
          'No activity yet',
          'Complete an activity to see it here.',
          false,
        ),
      );
    } else {
      for (var i = 0; i < _dailyProgress.length; i++) {
        final status = _dailyProgress[i];
        items.add(
          _buildProgressItem(
            status.title,
            _progressStatusLabel(status),
            status.completed,
          ),
        );
        if (i != _dailyProgress.length - 1) {
          items.add(const SizedBox(height: 12));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }

  String _progressStatusLabel(_ProgressStatus status) {
    if (!status.completed) {
      return 'Not completed yet';
    }
    return _formatCompletedLabel(status.completedAt);
  }

  String _formatCompletedLabel(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Completed';
    }
    final DateTime now = DateTime.now();
    final DateTime local = timestamp.toLocal();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    final DateTime startOfTimestampDay = DateTime(local.year, local.month, local.day);
    final DateFormat timeFormat = DateFormat('h:mm a');

    if (startOfTimestampDay == startOfToday) {
      return 'Today, ${timeFormat.format(local)}';
    }
    final DateTime startOfYesterday = startOfToday.subtract(const Duration(days: 1));
    if (startOfTimestampDay == startOfYesterday) {
      return 'Yesterday, ${timeFormat.format(local)}';
    }
    return DateFormat('MMM d, h:mm a').format(local);
  }

  Future<void> _loadDailyProgress() async {
    setState(() {
      _isProgressLoading = true;
      _progressError = null;
    });

    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    bool journalingCompleted = false;
    DateTime? journalingTime;

    bool breathingCompleted = false;
    DateTime? breathingTime;

    bool meditationCompleted = false;
    DateTime? meditationTime;

    String? error;

    try {
      final journalService = JournalService();
      final List<JournalEntry> entries = await journalService.getUserEntries(
        widget.userId,
        limit: 50,
      );
      for (final entry in entries) {
        final DateTime created = entry.createdAt.toLocal();
        if (_isWithinDay(created, startOfDay, endOfDay)) {
          journalingCompleted = true;
          if (journalingTime == null || created.isAfter(journalingTime!)) {
            journalingTime = created;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load journal progress: $e');
      error ??= 'Unable to retrieve complete progress data.';
    }

    try {
      final breathingService = BreathingApiService();
      final List<BreathingSession> sessions = await breathingService.getSessions(
        widget.userId,
        limit: 50,
      );
      for (final session in sessions) {
        final DateTime completed = session.completedAt.toLocal();
        if (_isWithinDay(completed, startOfDay, endOfDay) && session.cyclesCompleted > 0) {
          breathingCompleted = true;
          if (breathingTime == null || completed.isAfter(breathingTime!)) {
            breathingTime = completed;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load breathing progress: $e');
      error ??= 'Unable to retrieve complete progress data.';
    }

    try {
      meditationTime = await MeditationProgressService.getCompletionForDay(
        userId: widget.userId,
        date: now,
      );
      meditationCompleted = meditationTime != null;
    } catch (e) {
      debugPrint('Failed to load meditation progress: $e');
      error ??= 'Unable to retrieve complete progress data.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProgressLoading = false;
      _progressError = error;
      _dailyProgress = [
        _ProgressStatus(
          id: 'journaling',
          title: 'Journaling',
          completed: journalingCompleted,
          completedAt: journalingTime,
        ),
        _ProgressStatus(
          id: 'breathing',
          title: 'Breathing',
          completed: breathingCompleted,
          completedAt: breathingTime,
        ),
        _ProgressStatus(
          id: 'meditation',
          title: 'Meditation',
          completed: meditationCompleted,
          completedAt: meditationTime,
        ),
      ];
    });
  }

  bool _isWithinDay(DateTime timestamp, DateTime startOfDay, DateTime endOfDay) {
    final DateTime local = timestamp.toLocal();
    return !local.isBefore(startOfDay) && local.isBefore(endOfDay);
  }

  _DailyRecommendation _getDailyRecommendation(BuildContext context) {
    final List<_DailyRecommendation> options = [
      _DailyRecommendation(
        activityLabel: 'Gratitude Journaling',
        description: 'Write down three moments you appreciated today to cultivate a grateful mindset.',
        gradientColors: const [Color(0xFFFED7AA), Color(0xFFFEE6D4)],
        buttonColor: const Color.fromRGBO(66, 32, 6, 1),
        icon: Icons.menu_book_rounded,
        onStart: () => _openJournaling(context),
      ),
      _DailyRecommendation(
        activityLabel: 'Deep Breathing',
        description: 'Spend four minutes with box breathing—inhale, hold, exhale, and rest on a steady four-count.',
        gradientColors: const [Color(0xFFBBF7D0), Color(0xFFD1FAE5)],
        buttonColor: const Color(0xFF047857),
        icon: Icons.air,
        onStart: () => _openBreathing(context),
      ),
      _DailyRecommendation(
        activityLabel: 'Guided Meditation',
        description: 'Take a mindful pause with a gentle body-scan meditation to release lingering tension.',
        gradientColors: const [Color(0xFFC7D2FE), Color(0xFFE0E7FF)],
        buttonColor: const Color(0xFF4338CA),
        icon: Icons.self_improvement,
        onStart: () => _openMeditation(context),
      ),
      _DailyRecommendation(
        activityLabel: 'Mindful Music Break',
        description: 'Choose a soothing playlist and notice one instrument at a time as you listen without distractions.',
        gradientColors: const [Color(0xFFFBCFE8), Color(0xFFFCE7F3)],
        buttonColor: const Color(0xFFBE185D),
        icon: Icons.music_note,
        onStart: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MusicHomeScreen(),
            ),
          );
        },
      ),
    ];

    final DateTime today = DateTime.now().toUtc();
    final int daySeed =
        DateTime.utc(today.year, today.month, today.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    final int index = daySeed % options.length;
    return options[index];
  }

  Widget _buildActivityCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, String time, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(107, 114, 128, 1),
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color.fromRGBO(34, 197, 94, 1),
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(34, 197, 94, 1),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DailyRecommendation {
  const _DailyRecommendation({
    required this.activityLabel,
    required this.description,
    required this.gradientColors,
    required this.buttonColor,
    required this.icon,
    required this.onStart,
  });

  final String activityLabel;
  final String description;
  final List<Color> gradientColors;
  final Color buttonColor;
  final IconData icon;
  final VoidCallback onStart;
}

class _ProgressStatus {
  const _ProgressStatus({
    required this.id,
    required this.title,
    required this.completed,
    this.completedAt,
  });

  final String id;
  final String title;
  final bool completed;
  final DateTime? completedAt;
}
