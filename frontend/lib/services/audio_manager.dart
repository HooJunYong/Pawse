import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../models/music_models.dart';

class AudioManager {
  AudioManager._internal() {
    _player = AudioPlayer();
    _playingStream = _player.playerStateStream
        .map((PlayerState state) =>
            state.playing && state.processingState != ProcessingState.completed)
        .distinct()
        .asBroadcastStream();
    _currentTrackStream = _player.sequenceStateStream
        .map((SequenceState? sequenceState) {
          final dynamic tag = sequenceState?.currentSource?.tag;
          return tag is MusicTrack ? tag : null;
        })
        .distinct()
        .asBroadcastStream();

    _player.playerStateStream.listen((PlayerState state) {
      if (state.processingState == ProcessingState.completed) {
        if (_player.hasNext) {
          unawaited(_player.seekToNext());
        } else {
          unawaited(_player.seek(Duration.zero));
          unawaited(_player.pause());
        }
      }
    });
  }

  static final AudioManager _instance = AudioManager._internal();

  factory AudioManager() => _instance;

  static AudioManager get instance => _instance;

  late final AudioPlayer _player;
  ConcatenatingAudioSource? _playlistSource;
  List<MusicTrack> _playlist = const <MusicTrack>[];

  late final Stream<MusicTrack?> _currentTrackStream;
  late final Stream<bool> _playingStream;

  Stream<MusicTrack?> get currentTrackStream => _currentTrackStream;

  Stream<bool> get playingStream => _playingStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  MusicTrack? get currentTrack {
    final dynamic tag = _player.sequenceState?.currentSource?.tag;
    return tag is MusicTrack ? tag : null;
  }

  bool get isPlaying => _player.playing;

  Duration get position => _player.position;

  Duration? get duration => _player.duration;

  List<MusicTrack> get queue => List<MusicTrack>.unmodifiable(_playlist);

  Future<void> setPlaylist(
    List<MusicTrack> tracks, {
    int initialIndex = 0,
    bool autoPlay = true,
  }) async {
    final List<MusicTrack> playableTracks = tracks
        .where((MusicTrack track) =>
            track.audioUrl != null && track.audioUrl!.trim().isNotEmpty)
        .toList(growable: false);

    if (playableTracks.isEmpty) {
      _playlist = const <MusicTrack>[];
      await _player.stop();
      return;
    }

    await _player.stop();

    _playlist = playableTracks;
    final List<AudioSource> sources = playableTracks
        .map((MusicTrack track) =>
            AudioSource.uri(Uri.parse(track.audioUrl!), tag: track))
        .toList(growable: false);

    _playlistSource = ConcatenatingAudioSource(children: sources);

    int index = initialIndex;
    if (index < 0) {
      index = 0;
    }
    if (index >= _playlist.length) {
      index = _playlist.length - 1;
    }

    await _player.setAudioSource(
      _playlistSource!,
      initialIndex: index,
      preload: true,
    );

    if (autoPlay) {
      await _player.play();
    }
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> seekToIndex(int index) async {
    if (_playlist.isEmpty) return;
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> stop() => _player.stop();
}
