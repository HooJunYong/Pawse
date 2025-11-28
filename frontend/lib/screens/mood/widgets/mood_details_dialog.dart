import 'package:flutter/material.dart';
import '../../../utils/helpers.dart';

/// Dialog widget for displaying mood details
class MoodDetailsDialog extends StatelessWidget {
  final DateTime date;
  final String moodLevel;
  final String? note;
  final String moodId;
  final VoidCallback onEdit;

  // Colors
  static const Color _bgColor = Color(0xFFF7F4F2);
  static const Color _textBrown = Color(0xFF5D2D05);
  static const Color _orangeColor = Color(0xFFF38025);
  static const Color _veryHappyMood = Color(0xFF9BB168);
  static const Color _happyMood = Color(0xFFFFCE5C);
  static const Color _neutralMood = Color(0xFFC0A091);
  static const Color _sadMood = Color(0xFFED7E1C);
  static const Color _awfulMood = Color(0xFFA694F5);
  static const Color _greyCircle = Color(0xFFD9D9D9);

  const MoodDetailsDialog({
    Key? key,
    required this.date,
    required this.moodLevel,
    this.note,
    required this.moodId,
    required this.onEdit,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required DateTime date,
    required Map<String, dynamic> moodEntry,
    required VoidCallback onEdit,
  }) {
    showDialog(
      context: context,
      builder: (context) => MoodDetailsDialog(
        date: date,
        moodLevel: moodEntry['mood_level'] as String,
        note: moodEntry['note'] as String?,
        moodId: moodEntry['mood_id'] as String,
        onEdit: () {
          Navigator.pop(context);
          onEdit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? assetPath = MoodConstants.dbValueToAsset[moodLevel];

    return AlertDialog(
      backgroundColor: _bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatDate(date.toIso8601String()),
            style: const TextStyle(
              color: _textBrown,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: _orangeColor),
            onPressed: onEdit,
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
            style: const TextStyle(
              color: _textBrown,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (note != null && note!.isNotEmpty) ...[
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
                  const Text(
                    "Note:",
                    style: TextStyle(
                      color: _textBrown,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    note!,
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
          child: const Text(
            "Close",
            style: TextStyle(color: _orangeColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
