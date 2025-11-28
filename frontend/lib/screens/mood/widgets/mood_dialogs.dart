import 'package:flutter/material.dart';
import '../../../utils/helpers.dart';

/// Dialog widget for editing an existing mood entry
class MoodEditDialog extends StatefulWidget {
  final DateTime date;
  final String initialMoodLevel;
  final String? initialNote;
  final String moodId;
  final Future<void> Function(String moodId, String moodLevel, String note) onSave;

  const MoodEditDialog({
    Key? key,
    required this.date,
    required this.initialMoodLevel,
    this.initialNote,
    required this.moodId,
    required this.onSave,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required DateTime date,
    required Map<String, dynamic> moodEntry,
    required Future<void> Function(String moodId, String moodLevel, String note) onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) => MoodEditDialog(
        date: date,
        initialMoodLevel: moodEntry['mood_level'] as String,
        initialNote: moodEntry['note'] as String?,
        moodId: moodEntry['mood_id'] as String,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MoodEditDialog> createState() => _MoodEditDialogState();
}

class _MoodEditDialogState extends State<MoodEditDialog> {
  // Colors
  static const Color _bgColor = Color(0xFFF7F4F2);
  static const Color _textBrown = Color(0xFF5D2D05);
  static const Color _orangeColor = Color(0xFFF38025);

  late String _selectedMood;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMoodLevel;
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
            const Text(
              "Edit Mood",
              style: TextStyle(
                color: _textBrown,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              Helpers.formatDate(widget.date.toIso8601String()),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Center(
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
            MoodSelector(
              selectedMood: _selectedMood,
              onSelect: (mood) => setState(() => _selectedMood = mood),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
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
                    await widget.onSave(
                      widget.moodId,
                      _selectedMood,
                      _noteController.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog widget for submitting a new mood entry
class MoodSubmitDialog extends StatefulWidget {
  final DateTime date;
  final Future<void> Function(DateTime date, String moodLevel, String note) onSubmit;

  const MoodSubmitDialog({
    Key? key,
    required this.date,
    required this.onSubmit,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required DateTime date,
    required Future<void> Function(DateTime date, String moodLevel, String note) onSubmit,
  }) {
    showDialog(
      context: context,
      builder: (context) => MoodSubmitDialog(
        date: date,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<MoodSubmitDialog> createState() => _MoodSubmitDialogState();
}

class _MoodSubmitDialogState extends State<MoodSubmitDialog> {
  // Colors
  static const Color _bgColor = Color(0xFFF7F4F2);
  static const Color _textBrown = Color(0xFF5D2D05);
  static const Color _orangeColor = Color(0xFFF38025);

  String? _selectedMood;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
            const Text(
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
                Helpers.formatDate(widget.date.toIso8601String()),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
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
            MoodSelector(
              selectedMood: _selectedMood,
              onSelect: (mood) => setState(() => _selectedMood = mood),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
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
                  onPressed: _selectedMood == null
                      ? null
                      : () async {
                          await widget.onSubmit(
                            widget.date,
                            _selectedMood!,
                            _noteController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
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
                      color: _selectedMood == null ? Colors.grey[500] : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable mood selector widget
class MoodSelector extends StatelessWidget {
  final String? selectedMood;
  final Function(String) onSelect;

  // Colors
  static const Color _orangeColor = Color(0xFFF38025);
  static const Color _veryHappyMood = Color(0xFF9BB168);
  static const Color _happyMood = Color(0xFFFFCE5C);
  static const Color _neutralMood = Color(0xFFC0A091);
  static const Color _sadMood = Color(0xFFED7E1C);
  static const Color _awfulMood = Color(0xFFA694F5);
  static const Color _greyCircle = Color(0xFFD9D9D9);

  const MoodSelector({
    Key? key,
    required this.selectedMood,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

  Color _getMoodColor(String moodLevel) {
    switch (moodLevel) {
      case 'very happy':
        return _veryHappyMood;
      case 'happy':
        return _happyMood;
      case 'neutral':
        return _neutralMood;
      case 'sad':
        return _sadMood;
      case 'awful':
        return _awfulMood;
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
}
