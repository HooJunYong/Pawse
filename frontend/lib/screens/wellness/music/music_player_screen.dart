import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../models/music_models.dart';
import '../../../services/audio_manager.dart';

class MusicPlayerScreen extends StatefulWidget {
  final MusicTrack? track;
  final List<MusicTrack>? playlist;
  final int initialIndex;
  final bool attachToExistingSession;

  const MusicPlayerScreen({
    super.key,
    this.track,
    this.playlist,
    this.initialIndex = 0,
    this.attachToExistingSession = false,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioManager _audioManager = AudioManager.instance;

  StreamSubscription<MusicTrack?>? _trackSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  List<MusicTrack> _playlist = const <MusicTrack>[];
  MusicTrack? _currentTrack;

  @override
  void initState() {
    super.initState();
    _bindStreams();
    _initialiseQueue();
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  void _bindStreams() {
    _trackSub = _audioManager.currentTrackStream.listen((MusicTrack? track) {
      if (!mounted) return;
      setState(() {
        _currentTrack = track;
        _playlist = _audioManager.queue;
        if (track != null) {
          final int index = _resolveIndexForTrack(track);
          if (index != -1) {
            _currentIndex = index;
          }
        }
      });
    });

    _playerStateSub = _audioManager.playerStateStream.listen((PlayerState state) {
      if (!mounted) return;
      final bool completed = state.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = state.playing && !completed;
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        if (completed) {
          _position = Duration.zero;
        }
      });
    });

    _positionSub = _audioManager.positionStream.listen((Duration position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    _durationSub = _audioManager.durationStream.listen((Duration? duration) {
      if (!mounted || duration == null) return;
      setState(() => _duration = duration);
    });

    _currentTrack = _audioManager.currentTrack;
    _isPlaying = _audioManager.isPlaying;
    _position = _audioManager.position;
    _duration = _audioManager.duration ?? Duration.zero;
    _playlist = _audioManager.queue;
    if (_currentTrack != null) {
      final int index = _resolveIndexForTrack(_currentTrack!);
      if (index != -1) {
        _currentIndex = index;
      }
    }
  }

  int _resolveIndexForTrack(MusicTrack track) {
    return _playlist.indexWhere((MusicTrack element) => element.musicId == track.musicId);
  }

  Future<void> _initialiseQueue() async {
    if (widget.attachToExistingSession) {
      setState(() {
        _playlist = _audioManager.queue;
        _currentTrack = _audioManager.currentTrack;
        _isLoading = false;
        _errorMessage = (_playlist.isEmpty || _currentTrack == null)
            ? 'Nothing playing yet.'
            : null;
        if (_currentTrack != null) {
          final int index = _resolveIndexForTrack(_currentTrack!);
          if (index != -1) {
            _currentIndex = index;
          }
        }
      });
      return;
    }

    final List<MusicTrack> inputPlaylist;
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      inputPlaylist = widget.playlist!;
    } else if (widget.track != null) {
      inputPlaylist = <MusicTrack>[widget.track!];
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No track selected.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _audioManager.setPlaylist(
        inputPlaylist,
        initialIndex: widget.initialIndex,
      );
      final List<MusicTrack> updatedQueue = _audioManager.queue;
      if (updatedQueue.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Preview unavailable for this track.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _playlist = updatedQueue;
        _isLoading = false;
        _errorMessage = null;
        final int length = updatedQueue.length;
        int safeIndex = widget.initialIndex;
        if (safeIndex < 0) {
          safeIndex = 0;
        } else if (safeIndex >= length) {
          safeIndex = length - 1;
        }
        _currentIndex = safeIndex;
        _currentTrack = _audioManager.currentTrack;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to start playback right now.';
      });
    }
  }

  Future<void> _playNext() async {
    if (_playlist.isEmpty) return;
    await _audioManager.skipToNext();
  }

  Future<void> _playPrevious() async {
    if (_playlist.isEmpty) return;
    await _audioManager.skipToPrevious();
  }

  Future<void> _togglePlayPause() async {
    if (_isLoading || _errorMessage != null) {
      return;
    }
    await _audioManager.togglePlayPause();
  }

  Future<void> _seekRelative(int seconds) async {
    if (_isLoading || _errorMessage != null) {
      return;
    }
    final Duration target = _position + Duration(seconds: seconds);
    final Duration total = _duration != Duration.zero
        ? _duration
        : (_currentTrack != null
            ? Duration(seconds: _currentTrack!.durationSeconds)
            : Duration.zero);
    Duration clamped = target;
    if (clamped < Duration.zero) {
      clamped = Duration.zero;
    } else if (total != Duration.zero && clamped > total) {
      clamped = total;
    }
    await _audioManager.seek(clamped);
  }

  Future<void> _seekTo(double milliseconds) async {
    if (_isLoading || _errorMessage != null) {
      return;
    }
    await _audioManager
        .seek(Duration(milliseconds: milliseconds.round()));
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final MusicTrack? selectedTrack = _currentTrack ??
        (_playlist.isNotEmpty ? _playlist[_currentIndex] : null);
    final String title = selectedTrack?.title ?? 'Take a mindful pause';
    final String artist = selectedTrack?.artist ?? 'Press play to begin';
    final String? albumImage = selectedTrack?.albumImageUrl ?? selectedTrack?.thumbnailUrl;
    
    final Duration effectiveDuration = _duration != Duration.zero
      ? _duration
      : (selectedTrack != null && selectedTrack.durationSeconds > 0
        ? Duration(seconds: selectedTrack.durationSeconds)
        : Duration.zero);
    final double sliderMax = effectiveDuration.inMilliseconds > 0
      ? effectiveDuration.inMilliseconds.toDouble()
      : 1.0;
    final double sliderValue = _position.inMilliseconds
        .clamp(0, sliderMax.toInt())
        .toDouble();

    return Scaffold(
      body: Stack(
        children: [
          // Immersive Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF2C2C2C), // Fallback color
              child: albumImage != null && albumImage.isNotEmpty
                  ? Image.network(
                      albumImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    )
                  : null,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withOpacity(0.6), // Dark overlay
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Now Playing',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 30),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        // Mood Pill
                        if (selectedTrack?.moodCategory != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              selectedTrack!.moodCategory!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Hero Artwork
                        Hero(
                          tag: 'albumArt_${selectedTrack?.musicId}',
                          child: Container(
                            height: 320,
                            width: 320,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: albumImage != null && albumImage.isNotEmpty
                                  ? Image.network(
                                      albumImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildFallbackArt(),
                                    )
                                  : _buildFallbackArt(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // Title & Artist
                        Column(
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Progress Bar
                        Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(0.2),
                                thumbColor: Colors.white,
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    _duration == Duration.zero
                                        ? (selectedTrack?.durationLabel ?? '0:00')
                                        : _formatDuration(_duration),
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Shuffle (Visual only)
                            IconButton(
                              icon: Icon(Icons.shuffle, color: Colors.white.withOpacity(0.7)),
                              onPressed: () {}, 
                            ),
                            
                            // Previous
                            IconButton(
                              iconSize: 42,
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                color: _currentIndex > 0 ? Colors.white : Colors.white.withOpacity(0.3),
                              ),
                              onPressed: _currentIndex > 0 ? _playPrevious : null,
                            ),

                            // Play/Pause
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 40,
                                ),
                              ),
                            ),

                            // Next
                            IconButton(
                              iconSize: 42,
                              icon: Icon(
                                Icons.skip_next_rounded,
                                color: _currentIndex < _playlist.length - 1 ? Colors.white : Colors.white.withOpacity(0.3),
                              ),
                              onPressed: _currentIndex < _playlist.length - 1 ? _playNext : null,
                            ),

                            // Repeat (Visual only)
                            IconButton(
                              icon: Icon(Icons.repeat, color: Colors.white.withOpacity(0.7)),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackArt() {
    return Container(
      color: const Color(0xFF424242),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
      ),
    );
  }
}
