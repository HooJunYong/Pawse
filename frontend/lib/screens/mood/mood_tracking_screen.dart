import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/mood_service.dart';
import '../../utils/helpers.dart';

class MoodTrackingScreen extends StatefulWidget {
  final String userId;

  const MoodTrackingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  int _currentIndex = 2; // Default to Calendar tab based on image

  // Define Colors from Design
  final Color _bgColor = const Color(0xFFF7F4F2);
  final Color _textBrown = const Color(0xFF5D2D05);
  final Color _orangeColor = const Color(0xFFF38025);
  final Color _greyCircle = const Color(0xFFD9D9D9);
  final Color _greenMood = const Color(0xFF9CCCA5);
  final Color _purpleMood = const Color(0xFF9088D4);
  final Color _sadMood = const Color(0xFFE67C24);

  // Calendar state
  late DateTime _displayedMonth;
  Map<String, Map<String, dynamic>> _moodData = {}; // Key: "YYYY-MM-DD", Value: mood entry
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadMoodDataForMonth();
  }

  Future<void> _loadMoodDataForMonth() async {
    setState(() => _isLoading = true);

    try {
      final startDate = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
      final endDate = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);

      final response = await MoodService.getMoodByRange(
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.statusCode == 200) {
        final List<dynamic> moods = jsonDecode(response.body);
        final Map<String, Map<String, dynamic>> moodMap = {};

        for (var mood in moods) {
          final date = mood['date'] as String;
          moodMap[date] = {
            'mood_id': mood['mood_id'],
            'mood_level': mood['mood_level'],
            'note': mood['note'],
          };
        }

        setState(() {
          _moodData = moodMap;
        });
      }
    } catch (e) {
      debugPrint('Error loading mood data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
    _loadMoodDataForMonth();
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
    _loadMoodDataForMonth();
  }

  String _getMonthYearString() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        bottom: false, // Let the stack handle the bottom area
        child: Stack(
          children: [
            // Main Scrollable Content
            Positioned.fill(
              bottom: 80, // Leave space for BottomNavBar
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Header Title
                      Text(
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
                      _buildCalendarCard(),
                      
                      const SizedBox(height: 25),
                      
                      // Mood Chart Card
                      _buildMoodChartCard(),

                      const SizedBox(height: 40), // Bottom padding
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

  Widget _buildCalendarCard() {
    // Calculate calendar grid
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate what day of week the month starts on (1 = Monday, 7 = Sunday)
    int startWeekday = firstDayOfMonth.weekday; // 1 = Monday
    
    // Calculate total cells needed (including empty cells at start)
    int totalCells = startWeekday - 1 + daysInMonth;
    // Round up to nearest multiple of 7
    int rows = (totalCells / 7).ceil();
    int gridItemCount = rows * 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // Month Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                onPressed: _goToPreviousMonth,
              ),
              Text(
                _getMonthYearString(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black87),
                onPressed: _goToNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Days of Week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                .map((day) => SizedBox(
                      width: 35,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 15),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            // Calendar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridItemCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 4,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                // Calculate day from index
                int day = index - (startWeekday - 2);
                
                // Empty cells before month starts or after month ends
                if (index < startWeekday - 1 || day > daysInMonth) {
                  return const SizedBox();
                }
                
                return _buildDayCell(day);
              },
            ),
          
          const SizedBox(height: 15),
          Text(
            "Tap mood to see more details",
            style: TextStyle(color: Colors.black87, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day) {
    final today = DateTime.now();
    final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
    final dateKey = '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    
    final bool isFuture = cellDate.isAfter(DateTime(today.year, today.month, today.day));
    final bool isToday = cellDate.year == today.year && 
                         cellDate.month == today.month && 
                         cellDate.day == today.day;
    
    // Get mood data for this date
    final moodEntry = _moodData[dateKey];
    final bool hasMood = moodEntry != null;
    
    Widget content;
    
    if (hasMood) {
      // Display mood emoji from asset
      final String moodLevel = moodEntry['mood_level'] as String;
      final String? assetPath = MoodConstants.dbValueToAsset[moodLevel];
      
      if (assetPath != null) {
        content = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(2), // Add small padding inside the circle
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain, // Changed from cover to contain
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _getMoodColor(moodLevel),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getMoodIcon(moodLevel),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      } else {
        content = Container(
          decoration: BoxDecoration(
            color: _getMoodColor(moodLevel),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _getMoodIcon(moodLevel),
              color: Colors.white,
              size: 18,
            ),
          ),
        );
      }
    } else if (isFuture) {
      // Future date - just grey circle, no plus, not clickable
      content = Container(
        decoration: BoxDecoration(
          color: _greyCircle.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      );
    } else {
      // Past or current date without mood - grey circle with plus
      content = Container(
        decoration: BoxDecoration(
          color: _greyCircle.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Center(child: Icon(Icons.add, color: Colors.black54, size: 18)),
      );
    }

    return GestureDetector(
      onTap: isFuture ? null : () => _onDayCellTapped(cellDate, moodEntry),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: content,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$day",
            style: TextStyle(
              color: isFuture ? Colors.grey[400] : Colors.grey[600],
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(String moodLevel) {
    switch (moodLevel) {
      case 'very happy':
        return _greenMood;
      case 'happy':
        return const Color(0xFF8BC34A);
      case 'neutral':
        return const Color(0xFFFFB74D);
      case 'sad':
        return _sadMood;
      case 'awful':
        return _purpleMood;
      default:
        return _greyCircle;
    }
  }

  IconData _getMoodIcon(String moodLevel) {
    switch (moodLevel) {
      case 'very happy':
        return Icons.sentiment_very_satisfied;
      case 'happy':
        return Icons.sentiment_satisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'awful':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  void _onDayCellTapped(DateTime date, Map<String, dynamic>? moodEntry) {
    if (moodEntry != null) {
      _showMoodDetailsDialog(date, moodEntry);
    } else {
      _showMoodSubmitDialog(date);
    }
  }

  void _showMoodDetailsDialog(DateTime date, Map<String, dynamic> moodEntry) {
    final String moodLevel = moodEntry['mood_level'] as String;
    final String? note = moodEntry['note'] as String?;
    final String? assetPath = MoodConstants.dbValueToAsset[moodLevel];
    final String moodId = moodEntry['mood_id'] as String;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Helpers.formatDate(date.toIso8601String()),
              style: TextStyle(
                color: _textBrown,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: _orangeColor),
              onPressed: () {
                Navigator.pop(context);
                _showMoodEditDialog(date, moodEntry);
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mood emoji
            if (assetPath != null)
              Image.asset(
                assetPath,
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _getMoodIcon(moodLevel),
                    size: 80,
                    color: _getMoodColor(moodLevel),
                  );
                },
              )
            else
              Icon(
                _getMoodIcon(moodLevel),
                size: 80,
                color: _getMoodColor(moodLevel),
              ),
            const SizedBox(height: 10),
            Text(
              moodLevel.toUpperCase(),
              style: TextStyle(
                color: _textBrown,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            if (note != null && note.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Note:",
                      style: TextStyle(
                        color: _textBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      note,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Text(
                "No note recorded",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: _orangeColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodEditDialog(DateTime date, Map<String, dynamic> moodEntry) {
    String selectedMood = moodEntry['mood_level'] as String;
    final TextEditingController noteController = TextEditingController(
      text: moodEntry['note'] as String? ?? '',
    );
    final String moodId = moodEntry['mood_id'] as String;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: _bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Mood",
            style: TextStyle(
              color: _textBrown,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
                const SizedBox(height: 15),
                Text(
                  Helpers.formatDate(date.toIso8601String()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),
                // Mood selection
                Center(
                  child: Text(
                    "How are you feeling?",
                    style: TextStyle(
                      color: _textBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildMoodSelector(selectedMood, (mood) {
                  setDialogState(() => selectedMood = mood);
                }),
                const SizedBox(height: 20),
                // Note input
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Add a note (optional)",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await _updateMood(moodId, selectedMood, noteController.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoodSubmitDialog(DateTime date) {
    String? selectedMood;
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: _bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mood Check-in",
                  style: TextStyle(
                    color: _textBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    Helpers.formatDate(date.toIso8601String()),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                // Mood selection
                Center(
                  child: Text(
                    "How are you feeling?",
                    style: TextStyle(
                      color: _textBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildMoodSelector(selectedMood, (mood) {
                  setDialogState(() => selectedMood = mood);
                }),
                const SizedBox(height: 20),
                // Note input
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Add a note (optional)",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: selectedMood == null
                          ? null
                          : () async {
                              await _submitMood(date, selectedMood!, noteController.text);
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orangeColor,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: selectedMood == null ? Colors.grey[500] : Colors.white,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildMoodSelector(String? selectedMood, Function(String) onSelect) {
    final moods = [
      {'level': 'very happy', 'asset': MoodConstants.assetVeryHappy},
      {'level': 'happy', 'asset': MoodConstants.assetHappy},
      {'level': 'neutral', 'asset': MoodConstants.assetNeutral},
      {'level': 'sad', 'asset': MoodConstants.assetSad},
      {'level': 'awful', 'asset': MoodConstants.assetAwful},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.map((mood) {
        final isSelected = selectedMood == mood['level'];
        return GestureDetector(
          onTap: () => onSelect(mood['level']!),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: _orangeColor, width: 2)
                  : null,
              color: isSelected ? _orangeColor.withOpacity(0.1) : null,
            ),
            child: Image.asset(
              mood['asset']!,
              width: 38,
              height: 38,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  _getMoodIcon(mood['level']!),
                  size: 40,
                  color: _getMoodColor(mood['level']!),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitMood(DateTime date, String moodLevel, String note) async {
    try {
      Helpers.showLoadingDialog(context);
      
      final response = await MoodService.submitMood(
        userId: widget.userId,
        moodLevel: moodLevel,
        note: note.isEmpty ? null : note,
        date: date,
      );
      
      Helpers.closeLoadingDialog(context);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showSuccessSnackbar(context, 'Mood saved successfully!');
        _loadMoodDataForMonth();
      } else {
        final error = jsonDecode(response.body);
        Helpers.showErrorSnackbar(context, error['detail'] ?? 'Failed to save mood');
      }
    } catch (e) {
      Helpers.closeLoadingDialog(context);
      Helpers.showErrorSnackbar(context, 'Error saving mood: $e');
    }
  }

  Future<void> _updateMood(String moodId, String moodLevel, String note) async {
    try {
      Helpers.showLoadingDialog(context);
      
      final response = await MoodService.updateMood(
        moodId: moodId,
        userId: widget.userId,
        moodLevel: moodLevel,
        note: note.isEmpty ? null : note,
      );
      
      Helpers.closeLoadingDialog(context);
      
      if (response.statusCode == 200) {
        Helpers.showSuccessSnackbar(context, 'Mood updated successfully!');
        _loadMoodDataForMonth();
      } else {
        final error = jsonDecode(response.body);
        Helpers.showErrorSnackbar(context, error['detail'] ?? 'Failed to update mood');
      }
    } catch (e) {
      Helpers.closeLoadingDialog(context);
      Helpers.showErrorSnackbar(context, 'Error updating mood: $e');
    }
  }

  // New helper method for Assets
  Widget _buildAssetEmoji(String path) {
    return SizedBox(
      height: 24,
      width: 24,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        // Optional: If your images are just the face and you need to handle error/loading:
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error_outline, size: 24, color: Colors.grey);
        },
      ),
    );
  }

  Widget _buildMoodChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mood Chart",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Icon(Icons.download_rounded, color: Colors.black87),
            ],
          ),
          const SizedBox(height: 20),

          // Toggle Switch
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _orangeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Weekly",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Monthly",
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Date Range
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back_ios, size: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  "11/8 - 17-8, 2025",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Y Axis (Emojis)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildAssetEmoji('assets/images/mood_very_happy.png'),
                   const SizedBox(height: 15),
                   _buildAssetEmoji('assets/images/mood_happy.png'),
                   const SizedBox(height: 15),
                   _buildAssetEmoji('assets/images/mood_neutral.png'),
                   const SizedBox(height: 15),
                   _buildAssetEmoji('assets/images/mood_sad.png'),
                   const SizedBox(height: 15),
                   _buildAssetEmoji('assets/images/mood_awful.png'),
                   const SizedBox(height: 20), // Spacer for X axis labels
                ],
              ),
              const SizedBox(width: 15),
              // Graph
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 220, // Height of the chart area
                      width: double.infinity,
                      child: CustomPaint(
                        painter: ChartPainter(
                          orangeColor: _orangeColor,
                          bgColor: const Color(0xFFFFDAB9), // Light peach
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // X Axis Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ["11", "12", "13", "14", "15", "16", "17"]
                          .map((e) => Text(e, style: const TextStyle(fontSize: 12)))
                          .toList(),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter to replicate the exact curve in the image without external packages
class ChartPainter extends CustomPainter {
  final Color orangeColor;
  final Color bgColor;

  ChartPainter({required this.orangeColor, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // Calculate X positions for 7 days
    final stepX = w / 6; 
    
    // Y Positions corresponding to the Emojis column roughly
    // 0 = Top, H = Bottom
    // Points based on image:
    // Day 11: Sad (approx 75% down)
    // Day 12: Sad (approx 75% down)
    // Day 13: Very Sad (approx 95% down)
    
    final ySad = h * 0.72;
    final yVerySad = h * 0.95;

    final p1 = Offset(0, ySad); // Day 11
    final p2 = Offset(stepX, ySad); // Day 12
    final p3 = Offset(stepX * 2, yVerySad); // Day 13
    
    // Paint for the Fill
    final paintFill = Paint()
      ..color = orangeColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Define the Path
    final path = Path();
    path.moveTo(0, 0); // Top left corner of chart area fill
    path.lineTo(w, 0); // Top right
    path.lineTo(w, h); // Bottom right
    path.lineTo(stepX * 2, h); // Bottom at Day 13 x-coord
    path.lineTo(stepX * 2, yVerySad); // Up to Day 13 point
    path.lineTo(stepX, ySad); // Back to Day 12 point
    path.lineTo(0, ySad); // Back to Day 11 point
    path.close();

    // In the image, the fill seems to cover the WHOLE background except below the line
    // Or it's a fill below the line?
    // Looking closely at the image: The fill is solid peach/orange filling the area *above* the line.
    
    // Let's draw the blocky background rect first
    final bgPaint = Paint()..color = bgColor;
    // Actually, looking at the image "Mood Chart", it's a solid rectangle of light orange, 
    // but likely the data line is drawn on top.
    
    // Let's replicate the image exactly:
    // It's a large light orange rectangle.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), 
      bgPaint
    );

    // Draw the Line connecting the dots
    final linePaint = Paint()
      ..color = orangeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(p1.dx, p1.dy);
    linePath.lineTo(p2.dx, p2.dy);
    linePath.lineTo(p3.dx, p3.dy);
    
    canvas.drawPath(linePath, linePaint);

    // Draw the Dots
    _drawDot(canvas, p1);
    _drawDot(canvas, p2);
    _drawDot(canvas, p3);
  }

  void _drawDot(Canvas canvas, Offset center) {
    final whitePaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 6, whitePaint);
    canvas.drawCircle(center, 6, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}