import 'package:flutter/material.dart';
import '../../../utils/helpers.dart';

/// Individual day cell widget for the mood calendar
class MoodDayCell extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic>? moodEntry;
  final bool isFuture;
  final bool isToday;
  final VoidCallback? onTap;

  // Colors
  static const Color _greyCircle = Color(0xFFD9D9D9);
  static const Color _veryHappyMood = Color(0xFF9BB168);
  static const Color _happyMood = Color(0xFFFFCE5C);
  static const Color _neutralMood = Color(0xFFC0A091);
  static const Color _sadMood = Color(0xFFED7E1C);
  static const Color _awfulMood = Color(0xFFA694F5);

  const MoodDayCell({
    Key? key,
    required this.date,
    this.moodEntry,
    required this.isFuture,
    required this.isToday,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget content = _buildContent();

    return GestureDetector(
      onTap: isFuture ? null : onTap,
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
            "${date.day}",
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

  Widget _buildContent() {
    if (moodEntry != null) {
      return _buildMoodContent();
    } else if (isFuture) {
      return _buildFutureContent();
    } else {
      return _buildEmptyContent();
    }
  }

  Widget _buildMoodContent() {
    final String moodLevel = moodEntry!['mood_level'] as String;
    final String? assetPath = MoodConstants.dbValueToAsset[moodLevel];

    if (assetPath != null) {
      return Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackMoodIcon(moodLevel);
              },
            ),
          ),
        ),
      );
    } else {
      return _buildFallbackMoodIcon(moodLevel);
    }
  }

  Widget _buildFallbackMoodIcon(String moodLevel) {
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
  }

  Widget _buildFutureContent() {
    return Container(
      decoration: BoxDecoration(
        color: _greyCircle.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Container(
      decoration: BoxDecoration(
        color: _greyCircle.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.add, color: Colors.black54, size: 18),
      ),
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
