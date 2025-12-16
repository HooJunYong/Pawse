import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../utils/helpers.dart';
import 'controllers/mood_tracking_controller.dart';
import 'widgets/mood_calendar_card.dart';
import 'widgets/mood_chart_card.dart';
import 'widgets/mood_details_dialog.dart';
import 'widgets/mood_dialogs.dart';

class MoodTrackingScreen extends StatefulWidget {
  final String userId;

  const MoodTrackingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  int _currentIndex = 2;
  late MoodTrackingController _controller;
  final GlobalKey _chartKey = GlobalKey();

  // Colors
  static const Color _bgColor = Color(0xFFF7F4F2);
  static const Color _textBrown = Color(0xFF5D2D05);

  @override
  void initState() {
    super.initState();
    _controller = MoodTrackingController(userId: widget.userId);
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main Scrollable Content
            Positioned.fill(
              bottom: 80,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Header Title
                      const Text(
                        "Calendar",
                        style: TextStyle(
                          color: _textBrown,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Calendar Card
                      MoodCalendarCard(
                        controller: _controller,
                        onDayTapped: _handleDayTapped,
                      ),

                      const SizedBox(height: 25),

                      // Mood Chart Card
                      MoodChartCard(
                        controller: _controller,
                        chartKey: _chartKey,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavBar(
                userId: widget.userId,
                selectedIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle day cell tap - show appropriate dialog
  void _handleDayTapped(DateTime date, Map<String, dynamic>? moodEntry) {
    if (moodEntry != null) {
      _showMoodDetailsDialog(date, moodEntry);
    } else {
      _showMoodSubmitDialog(date);
    }
  }

  /// Show mood details dialog with option to edit
  void _showMoodDetailsDialog(DateTime date, Map<String, dynamic> moodEntry) {
    MoodDetailsDialog.show(
      context: context,
      date: date,
      moodEntry: moodEntry,
      onEdit: () => _showMoodEditDialog(date, moodEntry),
    );
  }

  /// Show mood edit dialog
  void _showMoodEditDialog(DateTime date, Map<String, dynamic> moodEntry) {
    MoodEditDialog.show(
      context: context,
      date: date,
      moodEntry: moodEntry,
      onSave: _handleMoodUpdate,
    );
  }

  /// Show mood submit dialog for new entries
  void _showMoodSubmitDialog(DateTime date) {
    MoodSubmitDialog.show(
      context: context,
      date: date,
      onSubmit: _handleMoodSubmit,
    );
  }

  /// Handle mood submission
  Future<void> _handleMoodSubmit(DateTime date, String moodLevel, String note) async {
    Helpers.showLoadingDialog(context);

    final result = await _controller.submitMood(
      date: date,
      moodLevel: moodLevel,
      note: note.isEmpty ? null : note,
    );

    if (mounted) {
      Helpers.closeLoadingDialog(context);

      if (result.isSuccess) {
        Helpers.showSuccessSnackbar(context, result.message);
      } else {
        Helpers.showErrorSnackbar(context, result.message);
      }
    }
  }

  /// Handle mood update
  Future<void> _handleMoodUpdate(String moodId, String moodLevel, String note) async {
    Helpers.showLoadingDialog(context);

    final result = await _controller.updateMood(
      moodId: moodId,
      moodLevel: moodLevel,
      note: note.isEmpty ? null : note,
    );

    if (mounted) {
      Helpers.closeLoadingDialog(context);

      if (result.isSuccess) {
        Helpers.showSuccessSnackbar(context, result.message);
      } else {
        Helpers.showErrorSnackbar(context, result.message);
      }
    }
  }
}
