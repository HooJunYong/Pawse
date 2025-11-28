import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/mood_entry.dart';
import '../../../services/mood_service.dart';

/// Controller for mood tracking business logic and state management
/// Follows the Controller pattern in N-tier architecture
class MoodTrackingController extends ChangeNotifier {
  final String userId;

  // Calendar state
  DateTime _displayedMonth;
  Map<String, MoodEntry> _moodData = {};
  bool _isLoading = false;

  // Chart state
  bool _isWeeklyChart = true;
  DateTime _chartWeekStart;
  DateTime _chartMonthStart;
  List<WeeklyChartDataPoint> _weeklyChartData = [];
  MonthlyMoodStats _monthlyMoodStats = MonthlyMoodStats.empty();
  bool _isChartLoading = false;

  // Error state
  String? _errorMessage;

  MoodTrackingController({required this.userId})
      : _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1),
        _chartWeekStart = _calculateWeekStart(DateTime.now()),
        _chartMonthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Getters
  DateTime get displayedMonth => _displayedMonth;
  Map<String, MoodEntry> get moodData => _moodData;
  bool get isLoading => _isLoading;
  bool get isWeeklyChart => _isWeeklyChart;
  DateTime get chartWeekStart => _chartWeekStart;
  DateTime get chartMonthStart => _chartMonthStart;
  List<WeeklyChartDataPoint> get weeklyChartData => _weeklyChartData;
  MonthlyMoodStats get monthlyMoodStats => _monthlyMoodStats;
  bool get isChartLoading => _isChartLoading;
  String? get errorMessage => _errorMessage;

  /// Calculate the Monday of the week for a given date
  static DateTime _calculateWeekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Initialize the controller and load data
  Future<void> initialize() async {
    await Future.wait([
      loadMoodDataForMonth(),
      loadChartData(),
    ]);
  }

  /// Load mood data for the currently displayed month
  Future<void> loadMoodDataForMonth() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startDate = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
      final endDate = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);

      final response = await MoodService.getMoodByRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.statusCode == 200) {
        final List<dynamic> moods = jsonDecode(response.body);
        final Map<String, MoodEntry> moodMap = {};

        for (var mood in moods) {
          final entry = MoodEntry.fromJson(mood);
          final dateKey = mood['date'] as String;
          moodMap[dateKey] = entry;
        }

        _moodData = moodMap;
      } else {
        _errorMessage = 'Failed to load mood data';
      }
    } catch (e) {
      debugPrint('Error loading mood data: $e');
      _errorMessage = 'Error loading mood data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate to previous month in calendar
  void goToPreviousMonth() {
    _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    notifyListeners();
    loadMoodDataForMonth();
  }

  /// Navigate to next month in calendar
  void goToNextMonth() {
    _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    notifyListeners();
    loadMoodDataForMonth();
  }

  /// Get formatted month-year string for display
  String getMonthYearString() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}';
  }

  /// Load chart data based on current chart type
  Future<void> loadChartData() async {
    if (_isWeeklyChart) {
      await loadWeeklyChartData();
    } else {
      await loadMonthlyChartData();
    }
  }

  /// Load weekly chart data
  Future<void> loadWeeklyChartData() async {
    _isChartLoading = true;
    notifyListeners();

    try {
      final weekEnd = _chartWeekStart.add(const Duration(days: 6));

      final response = await MoodService.getMoodByRange(
        userId: userId,
        startDate: _chartWeekStart,
        endDate: weekEnd,
      );

      if (response.statusCode == 200) {
        final List<dynamic> moods = jsonDecode(response.body);
        final List<WeeklyChartDataPoint> weekData = [];

        for (int i = 0; i < 7; i++) {
          final date = _chartWeekStart.add(Duration(days: i));
          final dateKey = _formatDateKey(date);

          final moodEntry = moods.firstWhere(
            (m) => m['date'] == dateKey,
            orElse: () => null,
          );

          weekData.add(WeeklyChartDataPoint(
            date: date,
            day: date.day,
            moodLevel: moodEntry?['mood_level'],
          ));
        }

        _weeklyChartData = weekData;
      }
    } catch (e) {
      debugPrint('Error loading weekly chart data: $e');
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }

  /// Load monthly chart data
  Future<void> loadMonthlyChartData() async {
    _isChartLoading = true;
    notifyListeners();

    try {
      final monthEnd = DateTime(_chartMonthStart.year, _chartMonthStart.month + 1, 0);

      final response = await MoodService.getMoodByRange(
        userId: userId,
        startDate: _chartMonthStart,
        endDate: monthEnd,
      );

      if (response.statusCode == 200) {
        final List<dynamic> moods = jsonDecode(response.body);
        _monthlyMoodStats = MonthlyMoodStats.fromMoodList(moods);
      }
    } catch (e) {
      debugPrint('Error loading monthly chart data: $e');
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }

  /// Toggle between weekly and monthly chart
  void setWeeklyChart(bool isWeekly) {
    if (_isWeeklyChart != isWeekly) {
      _isWeeklyChart = isWeekly;
      notifyListeners();
      loadChartData();
    }
  }

  /// Navigate to previous week in chart
  void goToPreviousWeek() {
    _chartWeekStart = _chartWeekStart.subtract(const Duration(days: 7));
    notifyListeners();
    loadWeeklyChartData();
  }

  /// Navigate to next week in chart
  void goToNextWeek() {
    _chartWeekStart = _chartWeekStart.add(const Duration(days: 7));
    notifyListeners();
    loadWeeklyChartData();
  }

  /// Navigate to previous month in chart
  void goToPreviousChartMonth() {
    _chartMonthStart = DateTime(_chartMonthStart.year, _chartMonthStart.month - 1, 1);
    notifyListeners();
    loadMonthlyChartData();
  }

  /// Navigate to next month in chart
  void goToNextChartMonth() {
    _chartMonthStart = DateTime(_chartMonthStart.year, _chartMonthStart.month + 1, 1);
    notifyListeners();
    loadMonthlyChartData();
  }

  /// Get formatted week range string for display
  String getWeekRangeString() {
    final weekEnd = _chartWeekStart.add(const Duration(days: 6));
    return '${_chartWeekStart.day}/${_chartWeekStart.month} - ${weekEnd.day}/${weekEnd.month}, ${_chartWeekStart.year}';
  }

  /// Get formatted month string for chart display
  String getChartMonthString() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_chartMonthStart.month - 1]} ${_chartMonthStart.year}';
  }

  /// Submit a new mood entry
  Future<MoodOperationResult> submitMood({
    required DateTime date,
    required String moodLevel,
    String? note,
  }) async {
    try {
      final response = await MoodService.submitMood(
        userId: userId,
        moodLevel: moodLevel,
        note: note,
        date: date,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final moodEntry = responseData['mood'] ?? responseData;

        // Update calendar data
        final dateKey = _formatDateKey(date);
        _moodData[dateKey] = MoodEntry.fromJson(moodEntry);

        // Refresh chart data to reflect the new mood entry
        await _refreshChartData();

        notifyListeners();
        return MoodOperationResult.success('Mood logged successfully!');
      } else {
        final errorData = jsonDecode(response.body);
        return MoodOperationResult.failure(
          errorData['detail'] ?? 'Failed to submit mood',
        );
      }
    } catch (e) {
      debugPrint('Error submitting mood: $e');
      return MoodOperationResult.failure('Network error. Please try again.');
    }
  }

  /// Update an existing mood entry
  Future<MoodOperationResult> updateMood({
    required String moodId,
    String? moodLevel,
    String? note,
  }) async {
    try {
      final response = await MoodService.updateMood(
        moodId: moodId,
        userId: userId,
        moodLevel: moodLevel,
        note: note,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedMood = responseData['mood'] ?? responseData;

        // Update calendar data
        if (updatedMood['date'] != null) {
          final date = DateTime.parse(updatedMood['date']);
          final dateKey = _formatDateKey(date);
          _moodData[dateKey] = MoodEntry.fromJson(updatedMood);
        }

        // Refresh chart data to reflect the updated mood entry
        await _refreshChartData();

        notifyListeners();
        return MoodOperationResult.success('Mood updated successfully!');
      } else {
        final errorData = jsonDecode(response.body);
        return MoodOperationResult.failure(
          errorData['detail'] ?? 'Failed to update mood',
        );
      }
    } catch (e) {
      debugPrint('Error updating mood: $e');
      return MoodOperationResult.failure('Network error. Please try again.');
    }
  }

  /// Refresh chart data after mood changes
  Future<void> _refreshChartData() async {
    if (_isWeeklyChart) {
      await loadWeeklyChartData();
    } else {
      await loadMonthlyChartData();
    }
  }

  /// Get mood entry for a specific date
  MoodEntry? getMoodForDate(DateTime date) {
    final dateKey = _formatDateKey(date);
    return _moodData[dateKey];
  }

  /// Format date to YYYY-MM-DD string
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if a date is in the future
  bool isFutureDate(DateTime date) {
    final today = DateTime.now();
    return date.isAfter(DateTime(today.year, today.month, today.day));
  }

  /// Check if a date is today
  bool isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }
}

/// Result class for mood submit/update operations
class MoodOperationResult {
  final bool isSuccess;
  final String message;

  const MoodOperationResult._({required this.isSuccess, required this.message});

  factory MoodOperationResult.success(String message) =>
      MoodOperationResult._(isSuccess: true, message: message);

  factory MoodOperationResult.failure(String message) =>
      MoodOperationResult._(isSuccess: false, message: message);
}
