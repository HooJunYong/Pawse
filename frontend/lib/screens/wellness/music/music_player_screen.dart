import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../../models/music_models.dart';
import '../../../providers/audio_player_provider.dart';

class MusicPlayerScreen extends StatelessWidget {
  final MusicTrack? track;
  final List<MusicTrack>? playlist;
  final int initialIndex;
  final bool attachToExistingSession;
  final String? userId;

  const MusicPlayerScreen({
    super.key,
    this.track,
    this.playlist,
    this.initialIndex = 0,
    this.attachToExistingSession = false,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerProvider(),
      child: _MusicPlayerView(
        track: track,
        playlist: playlist,
        initialIndex: initialIndex,
        attachToExistingSession: attachToExistingSession,
        userId: userId,
      ),
    );
  }
}

class _MusicPlayerView extends StatefulWidget {
  final MusicTrack? track;
  final List<MusicTrack>? playlist;
  final int initialIndex;
  final bool attachToExistingSession;
  final String? userId;

  const _MusicPlayerView({
    this.track,
    this.playlist,
    this.initialIndex = 0,
    this.attachToExistingSession = false,
    this.userId,
  });

  @override
  State<_MusicPlayerView> createState() => _MusicPlayerViewState();
}

class _MusicPlayerViewState extends State<_MusicPlayerView> {
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialiseQueue();
    });
  }

  Future<void> _initialiseQueue() async {
    final provider = context.read<AudioPlayerProvider>();

    if (widget.attachToExistingSession) {
      setState(() {
        _isInitializing = false;
        _errorMessage = (provider.playlist.isEmpty && provider.currentTrack == null)
            ? 'Nothing playing yet.'
            : null;
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
        _isInitializing = false;
        _errorMessage = 'No track selected.';
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      await provider.setPlaylist(
        inputPlaylist,
        initialIndex: widget.initialIndex,
      );
      
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Unable to start playback right now.';
      });
    }
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, player, child) {
        final MusicTrack? selectedTrack = player.currentTrack;
        final String title = selectedTrack?.title ?? 'Take a mindful pause';
        final String artist = selectedTrack?.artist ?? 'Press play to begin';
        final String? albumImage = selectedTrack?.albumImageUrl ?? selectedTrack?.thumbnailUrl;
        
        final Duration effectiveDuration = player.duration != Duration.zero
          ? player.duration
          : (selectedTrack != null && selectedTrack.durationSeconds > 0
            ? Duration(seconds: selectedTrack.durationSeconds)
            : Duration.zero);
        final double sliderMax = effectiveDuration.inMilliseconds > 0
          ? effectiveDuration.inMilliseconds.toDouble()
          : 1.0;
        final double sliderValue = player.position.inMilliseconds
            .clamp(0, sliderMax.toInt())
            .toDouble();

        final bool hasPlaylist = player.playlist.isNotEmpty;
        final int currentIndex = player.playlist.indexWhere((t) => t.musicId == selectedTrack?.musicId);
        final bool hasNext = currentIndex < player.playlist.length - 1;
        final bool hasPrevious = currentIndex > 0;

        return Scaffold(
          body: Stack(
            children: [
              // Immersive Background
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF2C2C2C),
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
                    color: Colors.black.withOpacity(0.6),
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
                              tag: 'albumArt_${selectedTrack?.musicId ?? "none"}',
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Placeholder to balance the heart icon
                                  const SizedBox(width: 48),
                                  Expanded(
                                    child: Column(
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
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      selectedTrack?.isLiked == true ? Icons.favorite : Icons.favorite_border,
                                      color: selectedTrack?.isLiked == true ? Colors.red : Colors.white,
                                    ),
                                    onPressed: (widget.userId != null && selectedTrack != null)
                                        ? () => player.toggleLike(widget.userId!)
                                        : null,
                                  ),
                                ],
                              ),
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
                                    onChanged: (_isInitializing || _errorMessage != null)
                                        ? null
                                        : (value) => player.seek(Duration(milliseconds: value.round())),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(player.position),
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      Text(
                                        player.duration == Duration.zero
                                            ? (selectedTrack?.durationLabel ?? '0:00')
                                            : _formatDuration(player.duration),
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
                                // Shuffle
                                IconButton(
                                  icon: Icon(
                                    Icons.shuffle,
                                    color: player.isShuffleEnabled ? Colors.greenAccent : Colors.white.withOpacity(0.7),
                                  ),
                                  onPressed: hasPlaylist ? player.toggleShuffle : null,
                                ),
                                
                                // Previous
                                IconButton(
                                  iconSize: 42,
                                  icon: Icon(
                                    Icons.skip_previous_rounded,
                                    color: hasPlaylist ? Colors.white : Colors.white.withOpacity(0.3),
                                  ),
                                  onPressed: hasPlaylist ? player.skipToPrevious : null,
                                ),

                                // Play/Pause
                                GestureDetector(
                                  onTap: player.togglePlayPause,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Icon(
                                      player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                                    color: hasPlaylist ? Colors.white : Colors.white.withOpacity(0.3),
                                  ),
                                  onPressed: hasPlaylist ? player.skipToNext : null,
                                ),

                                // Repeat
                                IconButton(
                                  icon: Icon(
                                    _getRepeatIcon(player.loopMode),
                                    color: player.loopMode != LoopMode.off ? Colors.greenAccent : Colors.white.withOpacity(0.7),
                                  ),
                                  onPressed: hasPlaylist ? player.cycleRepeatMode : null,
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
      },
    );
  }

  IconData _getRepeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.one:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat;
      case LoopMode.off:
        return Icons.repeat;
    }
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