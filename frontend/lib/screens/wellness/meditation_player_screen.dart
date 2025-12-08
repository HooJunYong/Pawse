import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/meditation_progress_service.dart';
import 'meditation_screen.dart'; // Ensure this path is correct

// --- Theme Constants ---
const Color _bgCream = Color(0xFFF7F4F2);
const Color _surfaceWhite = Colors.white;
const Color _textDark = Color(0xFF3E2723);
const Color _textGrey = Color(0xFF8D6E63);
const Color _primaryBrown = Color(0xFF5D4037);
const Color _accentOrange = Color(0xFFFB923C);
const Color _errorRed = Color(0xFFEF4444);


class MeditationPlayerScreen extends StatefulWidget {
  const MeditationPlayerScreen({Key? key, required this.session, required this.userId})
      : super(key: key);

  final MeditationSession session;
  final String userId;

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _listenToPlayerStreams();
    _initializePlayer();
  }

  void _listenToPlayerStreams() {
    _positionSub = _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _duration = dur);
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (!mounted) return;
      final playing = playerState.playing;
      final completed =
          playerState.processingState == ProcessingState.completed;
      setState(() => _isPlaying = playing && !completed);
      if (completed) {
        _player.seek(Duration.zero);
        _player.pause(); // Pause after completion
        MeditationProgressService.markCompleted(
          userId: widget.userId,
          timestamp: DateTime.now(),
        );
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      // Load audio from asset
      final duration = await _player.setAsset(widget.session.assetPath);
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
          _isLoading = false;
          _errorMessage = null;
        });
      }
      // Optional: Auto-play on load
      // unawaited(_player.play()); 
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load audio track.';
        });
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_errorMessage != null || _isLoading) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seekRelative(int seconds) async {
    if (_errorMessage != null || _isLoading) return;
    final current = _position;
    final target = current + Duration(seconds: seconds);
    final minTarget = target < Duration.zero ? Duration.zero : target;
    final capped = _duration == Duration.zero || target <= _duration
        ? minTarget
        : _duration;
    await _player.seek(capped);
  }

  Future<void> _seekTo(double milliseconds) async {
    if (_errorMessage != null || _isLoading) return;
    await _player.seek(Duration(milliseconds: milliseconds.round()));
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate slider values safely
    final double sliderMax = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final double sliderValue = _position.inMilliseconds
        .clamp(0, sliderMax.toInt())
        .toDouble();

    // Using the session color for accent elements
    final Color activeColor = widget.session.color;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgCream, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- Custom AppBar ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down,
                          size: 32, color: _textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Now Playing",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _textGrey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 48), // Placeholder for symmetry
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Artwork / Icon ---
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: activeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            widget.session.icon,
                            size: 100,
                            color: activeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // --- Title & Description ---
                      Text(
                        widget.session.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.session.description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          color: _textGrey.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Controls Area ---
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(
                  children: [
                    // Error Message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: _errorRed, fontSize: 14),
                        ),
                      ),

                    // Progress Bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: activeColor,
                        inactiveTrackColor: activeColor.withOpacity(0.2),
                        thumbColor: activeColor,
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayColor: activeColor.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: sliderValue,
                        min: 0,
                        max: sliderMax,
                        onChanged:
                            _isLoading ? null : (val) => _seekTo(val),
                      ),
                    ),

                    // Time Labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _textGrey,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Playback Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rewind 15s
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.replay_10_rounded),
                          color: _textDark,
                          onPressed: _isLoading
                              ? null
                              : () => _seekRelative(-10),
                        ),
                        const SizedBox(width: 32),

                        // Play/Pause Button
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _primaryBrown,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryBrown.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Forward 15s
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.forward_10_rounded),
                          color: _textDark,
                          onPressed: _isLoading
                              ? null
                              : () => _seekRelative(10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}