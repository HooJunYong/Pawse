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
  List<MoodOption> _moodOptions = const <MoodOption>[];
  bool _isLoadingMoods = true;
  String? _moodError;
  MoodOption? _selectedMood;
  Future<List<MusicAlbum>> _albumRecommendationsFuture =
      Future<List<MusicAlbum>>.value(const <MusicAlbum>[]);
  List<UserPlaylist> _playlists = const <UserPlaylist>[];
  bool _isLoadingPlaylists = true;
  String? _playlistError;
  MusicTrack? _currentTrack;

  @override
  void initState() {
    super.initState();
    _fetchMoodOptions();
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
    Widget content;
    if (_isLoadingMoods) {
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
            onPressed: () => _fetchMoodOptions(showLoader: true),
            child: const Text('Retry'),
          ),
        ],
      );
    } else if (_moodOptions.isEmpty) {
      content = Center(
        child: Text(
          'No moods available right now.',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: const Color(0xFF422006).withOpacity(0.7),
          ),
        ),
      );
    } else {
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _moodOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final option = _moodOptions[index];
          final bool isSelected = option.mood == _selectedMood?.mood;
          return GestureDetector(
            onTap: () => _selectMood(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              decoration: BoxDecoration(
                color: option.color,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
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
                  Icon(option.iconData, color: Colors.white, size: 32),
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
        SizedBox(height: 110, child: content),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    final String? moodTitle = _selectedMood?.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            moodTitle != null
              ? 'Recommended albums (${moodTitle.toLowerCase()})'
              : 'Recommended albums',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MusicAlbum>>(
          future: _albumRecommendationsFuture,
          builder: (context, snapshot) {
            if (_selectedMood == null) {
              if (_isLoadingMoods) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_moodError != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a mood to see recommendations.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: const Color(0xFF422006).withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _fetchMoodOptions(showLoader: true),
                      child: const Text('Reload moods'),
                    ),
                  ],
                );
              }
              return Text(
                'No moods found. Try refreshing.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: const Color(0xFF422006).withOpacity(0.7),
                ),
              );
            }
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
            final List<MusicAlbum> albums = snapshot.data ?? const <MusicAlbum>[];
            if (albums.isEmpty) {
              return Text(
                'No albums found. Try another mood.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: const Color(0xFF422006).withOpacity(0.7),
                ),
              );
            }
            return Column(
              children: albums
                  .map(
                    (album) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _AlbumCard(
                        album: album,
                        onTrackSelected: (track) => _openTrack(track),
                      ),
                    ),
                  )
                  .toList(growable: false),
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

  Future<void> _fetchMoodOptions({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoadingMoods = true;
        _moodError = null;
      });
    } else {
      setState(() {
        _moodError = null;
      });
    }
    try {
      final moods = await _musicApi.getMoodOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _moodOptions = moods;
        _isLoadingMoods = false;
        if (moods.isEmpty) {
          _selectedMood = null;
          _albumRecommendationsFuture =
              Future<List<MusicAlbum>>.value(const <MusicAlbum>[]);
          return;
        }
        final MoodOption? previous = _selectedMood;
        MoodOption active = moods.first;
        if (previous != null) {
          try {
            active = moods.firstWhere((option) => option.mood == previous.mood);
          } catch (_) {
            active = moods.first;
          }
        }
        _selectedMood = active;
        _albumRecommendationsFuture =
          _musicApi.getAlbumRecommendations(mood: active.mood, albumLimit: 3);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _moodError = error.toString();
        _isLoadingMoods = false;
        _selectedMood = null;
        _albumRecommendationsFuture =
            Future<List<MusicAlbum>>.value(const <MusicAlbum>[]);
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
    final Future<List<MusicAlbum>>? refreshedAlbums = _selectedMood == null
        ? null
        : _musicApi.getAlbumRecommendations(mood: _selectedMood!.mood, albumLimit: 3);
    await Future.wait<dynamic>([
      if (refreshedAlbums != null)
        refreshedAlbums.then((albums) {
          if (mounted) {
            setState(() {
              _albumRecommendationsFuture =
                  Future<List<MusicAlbum>>.value(albums);
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _albumRecommendationsFuture =
                  Future<List<MusicAlbum>>.error(error);
            });
          }
        }),
      _fetchMoodOptions(showLoader: false),
      _fetchPlaylists(showLoader: false),
    ]);
  }

  void _selectMood(MoodOption option) {
    setState(() {
      _selectedMood = option;
      _albumRecommendationsFuture =
          _musicApi.getAlbumRecommendations(mood: option.mood, albumLimit: 3);
    });
  }

  void _retryRecommendations() {
    final mood = _selectedMood;
    if (mood == null) {
      _fetchMoodOptions(showLoader: true);
      return;
    }
    setState(() {
      _albumRecommendationsFuture =
          _musicApi.getAlbumRecommendations(mood: mood.mood, albumLimit: 3);
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

class _AlbumCard extends StatelessWidget {
  final MusicAlbum album;
  final ValueChanged<MusicTrack> onTrackSelected;

  const _AlbumCard({required this.album, required this.onTrackSelected});

  @override
  Widget build(BuildContext context) {
    final List<Widget> trackWidgets = <Widget>[];
    for (final entry in album.tracks.asMap().entries) {
      final int index = entry.key;
      final MusicTrack track = entry.value;
      trackWidgets.add(
        InkWell(
          onTap: () => onTrackSelected(track),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF422006),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      const SizedBox(height: 2),
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
                const SizedBox(width: 12),
                Text(
                  track.durationLabel,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: const Color(0xFF422006).withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.play_arrow, color: Color(0xFF422006)),
              ],
            ),
          ),
        ),
      );
      if (index < album.tracks.length - 1) {
        trackWidgets.add(
          Divider(color: const Color(0xFF422006).withOpacity(0.1), height: 1),
        );
      }
    }

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: album.albumImageUrl != null && album.albumImageUrl!.isNotEmpty
                          ? Image.network(
                              album.albumImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFFFE0B2),
                                child: const Icon(Icons.album, color: Color(0xFF5D4037)),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFFFE0B2),
                              child: const Icon(Icons.album, color: Color(0xFF5D4037)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.albumTitle.isNotEmpty ? album.albumTitle : 'Mood Mix',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF422006),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${album.tracks.length} song${album.tracks.length == 1 ? '' : 's'}',
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
            const SizedBox(height: 12),
            ...trackWidgets,
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
  String get searchFieldLabel => 'Search Jamendo tracks';

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
