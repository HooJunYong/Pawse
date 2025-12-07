import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_notification_service.dart';

/// Mood types matching backend
enum MoodType {
  veryHappy,
  happy,
  neutral,
  sad,
  awful,
}

extension MoodTypeExtension on MoodType {
  String get apiValue {
    switch (this) {
      case MoodType.veryHappy:
        return 'very_happy';
      case MoodType.happy:
        return 'happy';
      case MoodType.neutral:
        return 'neutral';
      case MoodType.sad:
        return 'sad';
      case MoodType.awful:
        return 'awful';
    }
  }

  String get displayName {
    switch (this) {
      case MoodType.veryHappy:
        return 'Very Happy';
      case MoodType.happy:
        return 'Happy';
      case MoodType.neutral:
        return 'Neutral';
      case MoodType.sad:
        return 'Sad';
      case MoodType.awful:
        return 'Awful';
    }
  }
}

class MoodNudgeService {
  static final MoodNudgeService _instance = MoodNudgeService._internal();
  factory MoodNudgeService() => _instance;
  MoodNudgeService._internal();

  final LocalNotificationService _notificationService = LocalNotificationService();
  static const int _moodNudgeNotificationId = 1000;
  static const String _lastMoodKey = 'last_tracked_mood';
  static const String _nudgesEnabledKey = 'mood_nudges_enabled';

  // Predefined nudge messages for each mood (offline fallback)
  static const Map<String, List<Map<String, String>>> _offlineNudges = {
    'very_happy': [
      {
        'title': 'Anchor the Moment',
        'message':
            'You\'re glowing! 📸 Take a quick photo or write down one sentence about what made today great.'
      },
      {
        'title': 'Share the Joy',
        'message':
            'Happiness multiplies when shared. Send a text to a friend or family member just to say hello.'
      },
      {
        'title': 'Tackle the \'Big\' Task',
        'message':
            'Your energy is high right now. Is there a daunting task you\'ve been putting off?'
      },
    ],
    'happy': [
      {
        'title': 'Savor the Calm',
        'message':
            'Things are going well. Take a deep breath and just enjoy the absence of stress for a moment.'
      },
      {
        'title': 'Walk and Talk',
        'message':
            'Great day for a stroll. If you can, take a 10-minute walk outside to get some fresh air.'
      },
      {
        'title': 'Hydration Check',
        'message': 'Keep the good vibes flowing. Have you had a glass of water recently? 💧'
      },
    ],
    'neutral': [
      {
        'title': 'The Body Scan',
        'message':
            'Feeling \'meh\'? Do a quick body scan. Are your shoulders tense? Is your jaw clenched? Relax them.'
      },
      {
        'title': 'Change of Scenery',
        'message': 'Stagnation check. Stand up and move to a different room, or look out a window.'
      },
      {
        'title': 'Just Breathe',
        'message':
            'Try the 4-7-8 breathing technique. Inhale for 4, hold for 7, exhale for 8. It resets the nervous system.'
      },
    ],
    'sad': [
      {
        'title': 'Permission to Feel',
        'message': 'It\'s okay to feel this way. You don\'t need to \'fix\' it right this second. Just be.'
      },
      {
        'title': 'Comfort Mode',
        'message': 'Wrap yourself in a blanket, put on comfy socks, or make a warm drink.'
      },
      {
        'title': 'Journal the Heavy',
        'message': 'Get it out of your head. Write down what\'s hurting. You can tear the paper up afterwards.'
      },
    ],
    'awful': [
      {
        'title': '5-4-3-2-1 Grounding',
        'message':
            'Let\'s come back to the present. Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, and 1 you taste.'
      },
      {
        'title': 'Box Breathing',
        'message':
            'Focus only on your breath. Inhale 4 seconds, hold 4, exhale 4, hold 4. Repeat until your heart rate slows.'
      },
      {
        'title': 'Support Signal',
        'message':
            'You don\'t have to do this alone. Call a helpline or your emergency contact. Just hearing a voice can help.'
      },
    ],
  };

  /// Initialize the mood nudge service
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  /// Check if mood nudges are enabled
  Future<bool> areNudgesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_nudgesEnabledKey) ?? true; // Enabled by default
  }

  /// Enable or disable mood nudges
  Future<void> setNudgesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nudgesEnabledKey, enabled);
    
    if (!enabled) {
      // Cancel any pending nudges
      await _notificationService.cancelNotification(_moodNudgeNotificationId);
    }
  }

  /// Schedule a mood nudge to fire in 10 minutes
  Future<void> scheduleMoodNudge(MoodType mood) async {
    // Check if nudges are enabled
    final enabled = await areNudgesEnabled();
    if (!enabled) return;

    // Cancel any previously scheduled nudge
    await _notificationService.cancelNotification(_moodNudgeNotificationId);

    // Save the mood for reference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastMoodKey, mood.apiValue);

    // Get a random nudge for this mood (now fetches from API)
    final nudge = await _getRandomNudgeForMood(mood);

    // Schedule notification for 10 minutes from now
    await _notificationService.scheduleNotification(
      id: _moodNudgeNotificationId,
      title: nudge['title']!,
      body: nudge['message']!,
      delay: const Duration(minutes: 10),
      payload: 'mood_nudge:${mood.apiValue}',
    );
  }

  /// Get a random nudge for a specific mood
  /// Fetches from API, falls back to offline nudges if API fails
  Future<Map<String, String>> _getRandomNudgeForMood(MoodType mood) async {
    try {
      // Try to fetch from API first
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$apiUrl/mood-nudges/${mood.apiValue}/random'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'title': data['title'] ?? 'Check In',
          'message': data['message'] ?? 'Take a moment to notice how you\'re feeling.',
        };
      }
    } catch (e) {
      print('Error fetching mood nudge from API: $e');
      // Fall through to offline nudges
    }

    // Fallback to offline nudges
    final nudges = _offlineNudges[mood.apiValue] ?? [];
    if (nudges.isEmpty) {
      return {
        'title': 'Check In',
        'message': 'Take a moment to notice how you\'re feeling. You matter.',
      };
    }
    
    final random = Random();
    return nudges[random.nextInt(nudges.length)];
  }

  /// Cancel any scheduled mood nudge
  Future<void> cancelScheduledNudge() async {
    await _notificationService.cancelNotification(_moodNudgeNotificationId);
  }

  /// Send an immediate test nudge (for testing purposes)
  Future<void> sendTestNudge(MoodType mood) async {
    final nudge = await _getRandomNudgeForMood(mood);
    await _notificationService.showNotification(
      id: 999,
      title: '🧪 Test: ${nudge['title']!}',
      body: nudge['message']!,
      payload: 'test_mood_nudge:${mood.apiValue}',
    );
  }
}
