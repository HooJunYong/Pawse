import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/music_models.dart';
import '../services/audio_manager.dart';
import '../services/favorites_manager.dart';
import '../services/music_api_service.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioManager _audioManager = AudioManager.instance;
  final MusicApiService _musicApi = const MusicApiService();
  final FavoritesManager _favoritesManager = FavoritesManager.instance;

  StreamSubscription<MusicTrack?>? _trackSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _shuffleSub;
  StreamSubscription<LoopMode>? _loopSub;
  StreamSubscription<Map<String, bool>>? _favoritesSub;

  MusicTrack? _currentTrack;
  bool _isPlaying = false;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<MusicTrack> _playlist = [];

  MusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;
  Duration get position => _position;
  Duration get duration => _duration;
  List<MusicTrack> get playlist => _playlist;

  AudioPlayerProvider() {
    _init();
  }

  void _init() {
    _currentTrack = _audioManager.currentTrack;
    _isPlaying = _audioManager.isPlaying;
    _isShuffleEnabled = _audioManager.isShuffleModeEnabled;
    _loopMode = _audioManager.loopMode;
    _position = _audioManager.position;
    _duration = _audioManager.duration ?? Duration.zero;
    _playlist = _audioManager.queue;

    _trackSub = _audioManager.currentTrackStream.listen((track) {
      _currentTrack = track;
      _playlist = _audioManager.queue;
      notifyListeners();
    });

    _playerStateSub = _audioManager.playerStateStream.listen((state) {
      final bool playing = state.playing &&
          state.processingState != ProcessingState.completed;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });

    _positionSub = _audioManager.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = _audioManager.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _shuffleSub = _audioManager.shuffleModeEnabledStream.listen((enabled) {
      _isShuffleEnabled = enabled;
      notifyListeners();
    });

    _loopSub = _audioManager.loopModeStream.listen((mode) {
      _loopMode = mode;
      notifyListeners();
    });

    // Listen to favorites changes
    _favoritesSub = _favoritesManager.favoritesStream.listen((favStates) {
      // Update current track if its favorite state changed
      if (_currentTrack != null) {
        final newLikedState = favStates[_currentTrack!.musicId] ?? false;
        if (_currentTrack!.isLiked != newLikedState) {
          _currentTrack = _currentTrack!.copyWith(isLiked: newLikedState);
          notifyListeners();
        }
      }
      
      // Update playlist tracks
      bool playlistChanged = false;
      final updatedPlaylist = _playlist.map((track) {
        final newLikedState = favStates[track.musicId] ?? false;
        if (track.isLiked != newLikedState) {
          playlistChanged = true;
          return track.copyWith(isLiked: newLikedState);
        }
        return track;
      }).toList();
      
      if (playlistChanged) {
        _playlist = updatedPlaylist;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _shuffleSub?.cancel();
    _loopSub?.cancel();
    _favoritesSub?.cancel();
    super.dispose();
  }

  Future<void> toggleShuffle() async {
    await _audioManager.setShuffleMode(!_isShuffleEnabled);
  }

  Future<void> togglePlayPause() async {
    await _audioManager.togglePlayPause();
  }

  Future<void> skipToNext() async {
    await _audioManager.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await _audioManager.skipToPrevious();
  }

  Future<void> cycleRepeatMode() async {
    final nextMode = _getNextLoopMode(_loopMode);
    await _audioManager.setLoopMode(nextMode);
  }

  LoopMode _getNextLoopMode(LoopMode current) {
    switch (current) {
      case LoopMode.off:
        return LoopMode.all;
      case LoopMode.all:
        return LoopMode.one;
      case LoopMode.one:
        return LoopMode.off;
    }
  }

  Future<void> seek(Duration position) async {
    await _audioManager.seek(position);
  }
  
  Future<void> setPlaylist(List<MusicTrack> tracks, {int initialIndex = 0}) async {
    await _audioManager.setPlaylist(tracks, initialIndex: initialIndex);
  }

  Future<void> toggleLike(String userId) async {
    if (_currentTrack == null) return;
    
    try {
      // Use FavoritesManager for centralized state management
      final newState = await _favoritesManager.toggleFavorite(
        _currentTrack!.musicId,
        _currentTrack!,
        userId,
      );
      
      // State will be updated via the favorites stream listener
      // No need to manually update here
    } catch (e) {
      rethrow;
    }
  }
}
