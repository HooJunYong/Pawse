import 'package:flutter/material.dart';

import '../../../models/music_models.dart';
import '../../../services/audio_manager.dart';
import '../../../services/music_api_service.dart';
import 'create_playlist_screen.dart';
import 'music_player_screen.dart';
import 'playlist_details_screen.dart';

class MusicHomeScreen extends StatefulWidget {
  final String userId;

  const MusicHomeScreen({super.key, required this.userId});

  @override
  State<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends State<MusicHomeScreen> with WidgetsBindingObserver {
  final MusicApiService _musicApi = const MusicApiService();
  List<MoodTherapyRecommendation> _moodTherapyPlaylists =
      const <MoodTherapyRecommendation>[];
  List<UserPlaylist> _playlists = const <UserPlaylist>[];
  UserPlaylist? _currentMoodPlaylist;
  MusicTrack? _currentTrack;
  bool _isLoadingMoodTherapy = true;
  bool _isLoadingPlaylists = true;
  bool _openingMoodPlaylist = false;
  String? _activeMoodPlaylistId;
  String? _moodError;
  String? _playlistError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchMoodTherapyPlaylists();
    _fetchPlaylists();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh playlists when app comes back to foreground
    // This catches favorites updates from the music player
    if (state == AppLifecycleState.resumed) {
      _fetchPlaylists(showLoader: false);
    }
  }

  Widget _buildPlaylistsSection(BuildContext context) {
    Widget content;
    if (_isLoadingPlaylists) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_playlistError != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _playlistError!,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: const Color(0xFF422006).withOpacity(0.7),
            ),
          ),
          TextButton(
            onPressed: _fetchPlaylists,
            child: const Text('Retry'),
          ),
        ],
      );
    } else if (_playlists.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your first playlist to save tracks you love.',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: const Color(0xFF422006).withOpacity(0.7),
            ),
          ),
        ],
      );
    } else {
      content = Column(
        children: _playlists
            .map(
              (playlist) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _openPlaylist(context, playlist),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: playlist.playlistName.toLowerCase() == 'favorites'
                                ? Colors.red.withOpacity(0.15)
                                : playlist.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            playlist.playlistName.toLowerCase() == 'favorites'
                                ? Icons.favorite
                                : iconDataFromString(playlist.icon),
                            color: playlist.playlistName.toLowerCase() == 'favorites'
                                ? Colors.red
                                : Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.playlistName,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF422006),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${playlist.songCount} song${playlist.songCount == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: const Color(0xFF422006).withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF422006)),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your playlists',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF422006),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFFF8A65)),
              onPressed: _createPlaylist,
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildHeader(context),
                            const SizedBox(height: 24),
                            _buildMoodSection(),
                            const SizedBox(height: 24),
                            _buildPlaylistsSection(context),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MiniPlayer(
                    userId: widget.userId,
                    onReturn: () => _fetchPlaylists(showLoader: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool canGoBack = Navigator.of(context).canPop();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canGoBack) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF422006)),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                'Find the right vibe',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF422006),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF422006)),
              onPressed: _openSearch,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a mood to explore a curated playlist instantly.',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: const Color(0xFF422006).withOpacity(0.7),
          ),
        ),
        if (_currentMoodPlaylist != null) ...[
          const SizedBox(height: 12),
          Text(
            'Latest mix: ${_currentMoodPlaylist!.playlistName}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: const Color(0xFF422006).withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMoodSection() {
    Widget content;
    if (_isLoadingMoodTherapy) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_moodError != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _moodError!,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: const Color(0xFF422006).withOpacity(0.7),
            ),
          ),
          TextButton(
            onPressed: () => _fetchMoodTherapyPlaylists(showLoader: true),
            child: const Text('Retry'),
          ),
        ],
      );
    } else if (_moodTherapyPlaylists.isEmpty) {
      content = Center(
        child: Text(
          'No therapy mixes are ready right now.',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: const Color(0xFF422006).withOpacity(0.7),
          ),
        ),
      );
    } else {
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _moodTherapyPlaylists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final MoodTherapyRecommendation recommendation =
              _moodTherapyPlaylists[index];
          final Color cardColor = recommendation.color;
          final IconData cardIcon = iconDataFromString(recommendation.icon);
          final bool isSelected =
              _activeMoodPlaylistId == recommendation.id;
          final bool isProcessing =
              _openingMoodPlaylist && isSelected;

          return GestureDetector(
            onTap: isProcessing
                ? null
                : () => _openMoodTherapyPlaylist(recommendation),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cardColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              cardIcon,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          if (isProcessing)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 124,
                  child: Text(
                    recommendation.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF422006).withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Based on your mood',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 170, child: content),
      ],
    );
  }

  Future<void> _fetchMoodTherapyPlaylists({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoadingMoodTherapy = true;
        _moodError = null;
      });
    } else {
      setState(() {
        _moodError = null;
      });
    }
    try {
      final List<MoodTherapyRecommendation> recommendations =
          await _musicApi.getMoodPlaylists(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _moodTherapyPlaylists = recommendations.length <= 3
            ? recommendations
            : recommendations.take(3).toList(growable: false);
        _isLoadingMoodTherapy = false;
        if (_currentMoodPlaylist == null && recommendations.isNotEmpty) {
          final UserPlaylist playlist = recommendations.first.playlist;
          _currentMoodPlaylist = playlist;
          if (playlist.songs.isNotEmpty) {
            _currentTrack = _playlistSongToTrack(playlist.songs.first);
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _moodError = error.toString();
        _isLoadingMoodTherapy = false;
        _moodTherapyPlaylists = const <MoodTherapyRecommendation>[];
      });
    }
  }

  Future<void> _fetchPlaylists({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoadingPlaylists = true;
        _playlistError = null;
      });
    } else {
      setState(() {
        _playlistError = null;
      });
    }
    try {
      final List<UserPlaylist> playlists =
          await _musicApi.listPlaylists(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _playlists = playlists;
        _isLoadingPlaylists = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _playlistError = error.toString();
        _isLoadingPlaylists = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _openingMoodPlaylist = false;
      _activeMoodPlaylistId = null;
    });
    await Future.wait<void>([
      _fetchMoodTherapyPlaylists(showLoader: false),
      _fetchPlaylists(showLoader: false),
    ]);
  }

  Future<void> _openMoodTherapyPlaylist(
    MoodTherapyRecommendation recommendation,
  ) async {
    if (_openingMoodPlaylist && _activeMoodPlaylistId == recommendation.id) {
      return;
    }

    setState(() {
      _openingMoodPlaylist = true;
      _activeMoodPlaylistId = recommendation.id;
      _moodError = null;
      _currentMoodPlaylist = recommendation.playlist;
      if (recommendation.playlist.songs.isNotEmpty) {
        _currentTrack =
            _playlistSongToTrack(recommendation.playlist.songs.first);
      }
    });

    final String? coverImageUrl =
        _resolveMoodCoverImage(const <MusicAlbum>[], recommendation.playlist);

    try {
      final Map<String, dynamic>? result =
          await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistDetailsScreen(
            playlist: recommendation.playlist,
            userId: widget.userId,
            isReadOnly: true,
            coverImageUrl: coverImageUrl,
          ),
        ),
      );

      if (!mounted || result == null) {
        return;
      }

      final UserPlaylist? updated = result['playlist'] as UserPlaylist?;
      if (updated != null) {
        setState(() {
          _currentMoodPlaylist = updated;
          if (updated.songs.isNotEmpty) {
            _currentTrack = _playlistSongToTrack(updated.songs.first);
          }
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Unable to open playlist: $error');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _openingMoodPlaylist = false;
        _activeMoodPlaylistId = null;
      });
    }
  }

  String? _resolveMoodCoverImage(List<MusicAlbum> albums, UserPlaylist playlist) {
    for (final album in albums) {
      final String? image = album.albumImageUrl;
      if (image != null && image.isNotEmpty) {
        return image;
      }
    }
    for (final song in playlist.songs) {
      final String? image = song.albumImageUrl ?? song.thumbnailUrl;
      if (image != null && image.isNotEmpty) {
        return image;
      }
    }
    return null;
  }

  MusicTrack _playlistSongToTrack(PlaylistSong song) {
    return MusicTrack(
      musicId: song.musicId,
      title: song.title,
      artist: song.artist,
      durationSeconds: song.durationSeconds,
      addedAt: DateTime.now().toUtc(),
      thumbnailUrl: song.thumbnailUrl,
      albumImageUrl: song.albumImageUrl,
      audioUrl: song.audioUrl,
      moodCategory: song.moodCategory,
      isLiked: song.isLiked,
      playCount: 0,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _openSearch() async {
    final MusicTrack? track = await showSearch<MusicTrack?>(
      context: context,
      delegate: _MusicSearchDelegate(_musicApi, widget.userId),
    );
    if (track == null || !mounted) {
      return;
    }
    await _openTrack(track);
  }

  Future<void> _createPlaylist() async {
    final UserPlaylist? playlist = await Navigator.push<UserPlaylist?>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlaylistScreen(userId: widget.userId),
      ),
    );
    if (playlist != null && mounted) {
      setState(() {
        _playlists = [
          playlist,
          ..._playlists.where((item) => item.id != playlist.id),
        ];
      });
    }
  }

  Future<void> _openPlaylist(BuildContext context, UserPlaylist playlist) async {
    final Map<String, dynamic>? result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailsScreen(
          playlist: playlist,
          userId: widget.userId,
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    final String? action = result['action'] as String?;
    if (action == 'deleted') {
      final String? playlistId = result['playlistId'] as String?;
      if (playlistId != null) {
        setState(() {
          _playlists = _playlists.where((item) => item.id != playlistId).toList(growable: false);
        });
      }
      return;
    }
    if (action == 'updated') {
      final UserPlaylist? updated = result['playlist'] as UserPlaylist?;
      if (updated != null) {
        setState(() {
          _playlists = _playlists.map((item) => item.id == updated.id ? updated : item).toList(growable: false);
        });
      }
    }
  }

  Future<void> _openTrack(MusicTrack track) async {
    setState(() {
      _currentTrack = track;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerScreen(
          track: track,
          userId: widget.userId,
          onLikeToggled: () {
            // Refresh playlists in real-time when favorite is toggled
            _fetchPlaylists(showLoader: false);
          },
        ),
      ),
    );
    if (mounted) {
      _fetchPlaylists(showLoader: false);
    }
  }
}
class _MiniPlayer extends StatelessWidget {
  final String userId;
  final VoidCallback? onReturn;

  const _MiniPlayer({required this.userId, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final AudioManager audioManager = AudioManager.instance;
    return StreamBuilder<MusicTrack?>(
      stream: audioManager.currentTrackStream,
      initialData: audioManager.currentTrack,
      builder: (BuildContext context, AsyncSnapshot<MusicTrack?> trackSnapshot) {
        final MusicTrack? track = trackSnapshot.data;
        return StreamBuilder<bool>(
          stream: audioManager.playingStream,
          initialData: audioManager.isPlaying,
          builder: (BuildContext context, AsyncSnapshot<bool> playingSnapshot) {
            final bool isPlaying = playingSnapshot.data ?? false;
            return StreamBuilder<Duration?>(
              stream: audioManager.durationStream,
              initialData: audioManager.duration,
              builder: (
                BuildContext context,
                AsyncSnapshot<Duration?> durationSnapshot,
              ) {
                final Duration totalDuration = durationSnapshot.data ??
                    (track != null && track.durationSeconds > 0
                        ? Duration(seconds: track.durationSeconds)
                        : Duration.zero);
                return StreamBuilder<Duration>(
                  stream: audioManager.positionStream,
                  initialData: audioManager.position,
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<Duration> positionSnapshot,
                  ) {
                    final Duration position =
                        positionSnapshot.data ?? Duration.zero;
                    final double progress = totalDuration.inMilliseconds > 0
                        ? (position.inMilliseconds /
                                totalDuration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0;

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Material(
                    color: Colors.white,
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(32),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: track == null
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      MusicPlayerScreen(
                                    attachToExistingSession: true,
                                    userId: userId,
                                  ),
                                ),
                              );
                              onReturn?.call();
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (track?.albumImageUrl != null && track!.albumImageUrl!.isNotEmpty) ||
                                         (track?.thumbnailUrl != null && track!.thumbnailUrl!.isNotEmpty)
                                      ? Image.network(
                                          track.albumImageUrl ?? track.thumbnailUrl!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFCC80),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.music_note,
                                                color: Color(0xFF422006),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFCC80),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              track?.title
                                                      .substring(0, 1)
                                                      .toUpperCase() ??
                                                  '♪',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF422006),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        track?.title ??
                                            'Nothing playing yet',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF422006),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        track?.artist ??
                                            'Tap play to start listening',
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  iconSize: 32,
                                  splashRadius: 24,
                                  color: const Color(0xFF422006),
                                  onPressed: track == null
                                      ? null
                                      : () => audioManager.togglePlayPause(),
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                value: track == null ? 0 : progress,
                                backgroundColor: const Color(0xFFFFE0B2),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF422006),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MusicSearchDelegate extends SearchDelegate<MusicTrack?> {
  final MusicApiService musicApi;
  final String userId;

  _MusicSearchDelegate(this.musicApi, this.userId);

  @override
  String get searchFieldLabel => 'Search tracks';

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) {
      return null;
    }
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _SearchResults(
      query: query.trim(),
      musicApi: musicApi,
      onSelected: (track) => close(context, track),
      userId: userId,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return _TopTracks(
        musicApi: musicApi,
        onSelected: (track) => close(context, track),
        userId: userId,
      );
    }
    return _SearchResults(
      query: query.trim(),
      musicApi: musicApi,
      onSelected: (track) => close(context, track),
      userId: userId,
    );
  }
}

class _TopTracks extends StatelessWidget {
  final MusicApiService musicApi;
  final ValueChanged<MusicTrack> onSelected;
  final String userId;

  const _TopTracks({
    required this.musicApi,
    required this.onSelected,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MusicTrack>>(
      future: musicApi.getTopTracks(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Fail silently or show a simple message
          return const Center(
            child: Text('Search for songs or artists to get started.'),
          );
        }
        final List<MusicTrack> results = snapshot.data ?? const <MusicTrack>[];
        if (results.isEmpty) {
          return const Center(
            child: Text('Search for songs or artists to get started.'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Top Songs',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF422006),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final track = results[index];
                  return ListTile(
                    leading: _ArtworkPreview(url: track.thumbnailUrl ?? track.albumImageUrl),
                    title: Text(track.title),
                    subtitle: Text(track.artist),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MusicPlayerScreen(
                            playlist: results,
                            initialIndex: index,
                            userId: userId,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchResults extends StatelessWidget {
  final String query;
  final MusicApiService musicApi;
  final ValueChanged<MusicTrack> onSelected;
  final String userId;

  const _SearchResults({
    required this.query,
    required this.musicApi,
    required this.onSelected,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const SizedBox.shrink();
    }
    if (normalizedQuery.length < 2) {
      return const Center(
        child: Text('Type at least 2 characters to search.'),
      );
    }
    return FutureBuilder<List<MusicTrack>>(
      future: musicApi.searchTracks(query: normalizedQuery, limit: 25),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Search failed: ${snapshot.error}'),
          );
        }
        final List<MusicTrack> results = snapshot.data ?? const <MusicTrack>[];
        if (results.isEmpty) {
          return const Center(child: Text('No matches found.'));
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final track = results[index];
            return ListTile(
              leading: _ArtworkPreview(url: track.thumbnailUrl ?? track.albumImageUrl),
              title: Text(track.title),
              subtitle: Text(track.artist),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MusicPlayerScreen(
                      playlist: results,
                      initialIndex: index,
                      userId: userId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ArtworkPreview extends StatelessWidget {
  final String? url;

  const _ArtworkPreview({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE0B2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Color(0xFF5D4037)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0B2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: Color(0xFF5D4037)),
        ),
      ),
    );
  }
}
