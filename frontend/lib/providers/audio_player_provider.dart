import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/music_models.dart';
import '../services/audio_manager.dart';
import '../services/music_api_service.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioManager _audioManager = AudioManager.instance;
  final MusicApiService _musicApi = const MusicApiService();

  StreamSubscription<MusicTrack?>? _trackSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<bool>? _shuffleSub;
  StreamSubscription<LoopMode>? _loopSub;

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
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _shuffleSub?.cancel();
    _loopSub?.cancel();
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
    
    final String musicId = _currentTrack!.musicId;
    final bool oldState = _currentTrack!.isLiked;
    final bool newState = !oldState;
    
    // Optimistic update
    _currentTrack = _currentTrack!.copyWith(isLiked: newState);
    
    // Update in playlist as well
    _playlist = _playlist.map((t) {
      if (t.musicId == musicId) {
        return t.copyWith(isLiked: newState);
      }
      return t;
    }).toList();
    
    notifyListeners();
    
    try {
      final bool serverState = await _musicApi.toggleLike(musicId, userId);
      if (serverState != newState) {
        // Revert if server disagrees
        _currentTrack = _currentTrack!.copyWith(isLiked: serverState);
        _playlist = _playlist.map((t) {
          if (t.musicId == musicId) {
            return t.copyWith(isLiked: serverState);
          }
          return t;
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      // Revert on error
      _currentTrack = _currentTrack!.copyWith(isLiked: oldState);
      _playlist = _playlist.map((t) {
        if (t.musicId == musicId) {
          return t.copyWith(isLiked: oldState);
        }
        return t;
      }).toList();
      notifyListeners();
      rethrow;
    }
  }
}
