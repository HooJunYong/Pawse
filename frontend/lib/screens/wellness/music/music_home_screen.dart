import 'package:flutter/material.dart';

import '../../../models/music_models.dart';
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

class _MusicHomeScreenState extends State<MusicHomeScreen> {
  final MusicApiService _musicApi = const MusicApiService();
  final List<MoodUiOption> _moodOptions = const [
    MoodUiOption(title: 'Calm', icon: Icons.cloud, color: Color(0xFFFFE082), mood: MoodType.happy),
    MoodUiOption(title: 'Focus', icon: Icons.book, color: Color(0xFFFFAB91), mood: MoodType.neutral),
    MoodUiOption(title: 'Empower', icon: Icons.bolt, color: Color(0xFFFFCC80), mood: MoodType.veryHappy),
  ];

  late MoodUiOption _selectedMood;
  late Future<List<MusicTrack>> _recommendationsFuture;
  List<UserPlaylist> _playlists = const <UserPlaylist>[];
  bool _isLoadingPlaylists = true;
  String? _playlistError;
  MusicTrack? _currentTrack;

  @override
  void initState() {
    super.initState();
    _selectedMood = _moodOptions.first;
    _recommendationsFuture = _musicApi.getRecommendations(mood: _selectedMood.mood, limit: 12);
    _fetchPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 375),
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildMoodSection(),
                      const SizedBox(height: 24),
                      _buildRecommendationsSection(),
                      const SizedBox(height: 24),
                      _buildPlaylistsSection(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _MiniPlayer(track: _currentTrack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF422006)),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Music',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF422006),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF422006)),
              onPressed: () async {
                final MusicTrack? track = await showSearch<MusicTrack?>(
                  context: context,
                  delegate: _MusicSearchDelegate(_musicApi),
                );
                if (track != null && mounted) {
                  setState(() {
                    _currentTrack = track;
                  });
                  if (!mounted) {
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MusicPlayerScreen(track: track)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
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
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _moodOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final option = _moodOptions[index];
              final bool isSelected = option.mood == _selectedMood.mood;
              return GestureDetector(
                onTap: () => _selectMood(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  decoration: BoxDecoration(
                    color: option.color,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: option.color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(option.icon, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended tracks (${_selectedMood.title.toLowerCase()})',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MusicTrack>>(
          future: _recommendationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unable to load recommendations right now.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: const Color(0xFF422006).withOpacity(0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _retryRecommendations(),
                    child: const Text('Try again'),
                  ),
                ],
              );
            }
            final List<MusicTrack> tracks = snapshot.data ?? const <MusicTrack>[];
            if (tracks.isEmpty) {
              return Text(
                'No tracks found. Try another mood.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: const Color(0xFF422006).withOpacity(0.7),
                ),
              );
            }
            return SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tracks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return _RecommendationCard(
                    track: track,
                    onPlay: () => _openTrack(track),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
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
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note, color: Color(0xFF4DB6AC)),
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
      final playlists = await _musicApi.listPlaylists(widget.userId);
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
    final Future<List<MusicTrack>> refreshedRecommendations =
        _musicApi.getRecommendations(mood: _selectedMood.mood, limit: 12);
    await Future.wait<dynamic>([
      refreshedRecommendations.then((tracks) {
        if (mounted) {
          setState(() {
            _recommendationsFuture = Future.value(tracks);
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _recommendationsFuture = Future.error(error);
          });
        }
      }),
      _fetchPlaylists(showLoader: false),
    ]);
  }

  void _selectMood(MoodUiOption option) {
    setState(() {
      _selectedMood = option;
      _recommendationsFuture = _musicApi.getRecommendations(mood: option.mood, limit: 12);
    });
  }

  void _retryRecommendations() {
    setState(() {
      _recommendationsFuture = _musicApi.getRecommendations(mood: _selectedMood.mood, limit: 12);
    });
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
      MaterialPageRoute(builder: (context) => MusicPlayerScreen(track: track)),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final MusicTrack track;
  final VoidCallback onPlay;

  const _RecommendationCard({required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        width: 150,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: (track.albumImageUrl ?? track.thumbnailUrl) != null
                    ? Image.network(
                        track.albumImageUrl ?? track.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFFE0B2),
                          child: const Icon(Icons.music_note, color: Color(0xFF5D4037)),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFFFE0B2),
                        child: const Icon(Icons.music_note, color: Color(0xFF5D4037)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF422006),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: const Color(0xFF422006).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final MusicTrack? track;

  const _MiniPlayer({this.track});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MusicPlayerScreen(track: track)),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC80),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  track?.title.substring(0, 1).toUpperCase() ?? '♪',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track?.title ?? 'Nothing playing yet',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF422006),
                    ),
                  ),
                  Text(
                    track?.artist ?? 'Tap a song to start listening',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Color(0xFF422006), size: 32),
          ],
        ),
      ),
    );
  }
}

class _MusicSearchDelegate extends SearchDelegate<MusicTrack?> {
  final MusicApiService musicApi;

  _MusicSearchDelegate(this.musicApi);

  @override
  String get searchFieldLabel => 'Search Spotify tracks';

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
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Search for songs or artists to get started.'),
      );
    }
    return _SearchResults(
      query: query.trim(),
      musicApi: musicApi,
      onSelected: (track) => close(context, track),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final String query;
  final MusicApiService musicApi;
  final ValueChanged<MusicTrack> onSelected;

  const _SearchResults({
    required this.query,
    required this.musicApi,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<MusicTrack>>(
      future: musicApi.searchTracks(query: query, limit: 25),
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
              onTap: () => onSelected(track),
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
