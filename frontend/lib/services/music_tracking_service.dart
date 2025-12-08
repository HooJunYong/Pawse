import 'dart:async';
import '../models/music_models.dart';
import 'audio_manager.dart';
import 'music_api_service.dart';

class MusicTrackingService {
  MusicTrackingService._internal();
  static final MusicTrackingService _instance = MusicTrackingService._internal();
  static MusicTrackingService get instance => _instance;

  String? _userId;
  StreamSubscription? _subscription;
  final MusicApiService _musicApi = const MusicApiService();

  /// Initialize the tracking service with the current user ID.
  /// This should be called when the user logs in or enters the main app.
  void initialize(String userId) {
    // If already initialized for this user, do nothing
    if (_userId == userId) return;
    
    _userId = userId;
    _subscription?.cancel();
    
    // Listen to track changes from the global AudioManager
    _subscription = AudioManager.instance.currentTrackStream.listen((track) {
      if (track != null && _userId != null) {
        _trackPlay(track.musicId, _userId!);
      }
    });
  }
  
  Future<void> _trackPlay(String musicId, String userId) async {
    try {
      await _musicApi.recordPlay(musicId, userId);
    } catch (e) {
      // Silently fail for tracking errors to not disrupt playback
      print('Error tracking music play: $e');
    }
  }
  
  void dispose() {
    _subscription?.cancel();
    _userId = null;
  }
}