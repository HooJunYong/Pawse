import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../models/music_models.dart';

class MusicPlayerScreen extends StatefulWidget {
  final MusicTrack? track;

  const MusicPlayerScreen({super.key, this.track});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _errorMessage;

  MusicTrack? get _track => widget.track;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _listenToPlayerStreams();
    _initialisePlayer();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _listenToPlayerStreams() {
    _positionSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      setState(() => _duration = duration);
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (!mounted) return;
      final bool completed =
          playerState.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = playerState.playing && !completed;
        if (completed) {
          _position = Duration.zero;
        }
      });
      if (completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  Future<void> _initialisePlayer() async {
    final String? url = _track?.audioUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Preview unavailable for this track.';
        });
      }
      return;
    }

    try {
      final Duration? duration = await _player.setUrl(url);
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = duration ?? Duration.zero;
        _isLoading = false;
        _errorMessage = null;
      });
      await _player.play();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to stream this preview right now.';
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading || _errorMessage != null) {
      return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seekRelative(int seconds) async {
    if (_isLoading || _errorMessage != null) {
      return;
    }
    final Duration target = _position + Duration(seconds: seconds);
    final Duration clamped;
    if (target < Duration.zero) {
      clamped = Duration.zero;
    } else if (_duration != Duration.zero && target > _duration) {
      clamped = _duration;
    } else {
      clamped = target;
    }
    await _player.seek(clamped);
  }

  Future<void> _seekTo(double milliseconds) async {
    if (_isLoading || _errorMessage != null) {
      return;
    }
    await _player.seek(Duration(milliseconds: milliseconds.round()));
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final MusicTrack? selectedTrack = _track;
    final String title = selectedTrack?.title ?? 'Take a mindful pause';
    final String artist = selectedTrack?.artist ?? 'Press play to begin';
    final double sliderMax = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final double sliderValue = _position.inMilliseconds
        .clamp(0, sliderMax.toInt())
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF422006)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Color(0xFF422006),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF422006)),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 375),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AlbumArt(selectedTrack: selectedTrack),
              const SizedBox(height: 40),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF422006),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF5D4037),
                  inactiveTrackColor: const Color(0xFF5D4037).withOpacity(0.2),
                  thumbColor: const Color(0xFF5D4037),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: sliderValue,
                  max: sliderMax,
                  onChanged: (_isLoading || _errorMessage != null)
                      ? null
                      : (value) => _seekTo(value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 12),
                    ),
                    Text(
                      _duration == Duration.zero
                          ? (selectedTrack?.durationLabel ?? '0:00')
                          : _formatDuration(_duration),
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Color(0xFF422006)),
                    onPressed: () => _seekRelative(-10),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 36, color: Color(0xFF422006)),
                    onPressed: () => _seekRelative(-30),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D4037).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 36, color: Color(0xFF422006)),
                    onPressed: () => _seekRelative(30),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Color(0xFF422006)),
                    onPressed: () => _seekRelative(10),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Color(0xFF5D4037),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final MusicTrack? selectedTrack;

  const _AlbumArt({required this.selectedTrack});

  @override
  Widget build(BuildContext context) {
    final String? albumImage = selectedTrack?.albumImageUrl ?? selectedTrack?.thumbnailUrl;
    final Widget fallback = Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC80),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Icon(Icons.music_note, size: 120, color: Colors.white),
    );

    if (albumImage == null || albumImage.isEmpty) {
      return fallback;
    }

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        albumImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
