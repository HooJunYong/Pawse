import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'api_service.dart';

/// Text-to-Speech Service
/// Handles TTS generation requests and audio playback
class TTSService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  /// Check if audio is currently playing
  static bool get isPlaying => _isPlaying;

  /// Generate and play TTS audio for a companion's message
  /// 
  /// [text] - The text to convert to speech
  /// [companionId] - The companion ID to get voice settings from
  /// 
  /// Returns true if successful, false otherwise
  static Future<bool> generateAndPlayAudio({
    required String text,
    required String companionId,
  }) async {
    try {
      // Request TTS generation from backend
      final response = await ApiService.post(
        '/api/tts/generate',
        {
          'text': text,
          'companion_id': companionId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioUrl = data['audio_url'];
        
        // Construct full audio URL
        final fullAudioUrl = '${ApiService.baseUrl}$audioUrl';
        
        // Play the audio
        await playAudio(fullAudioUrl);
        return true;
      } else {
        print('Failed to generate TTS: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error in generateAndPlayAudio: $e');
      return false;
    }
  }

  /// Play audio from URL
  static Future<void> playAudio(String audioUrl) async {
    try {
      _isPlaying = true;
      
      // Set audio source
      await _audioPlayer.setUrl(audioUrl);
      
      // Play audio
      await _audioPlayer.play();
      
      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
      });
      
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
    }
  }

  /// Stop currently playing audio
  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Pause currently playing audio
  static Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  /// Resume paused audio
  static Future<void> resumeAudio() async {
    try {
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  /// Dispose audio player
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isPlaying = false;
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }

  /// Get available voices/tones from backend
  static Future<Map<String, dynamic>?> getAvailableVoices() async {
    try {
      final response = await ApiService.get('/api/tts/voices');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Failed to get voices: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting voices: $e');
      return null;
    }
  }
}
