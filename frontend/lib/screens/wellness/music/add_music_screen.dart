import 'package:flutter/material.dart';

import '../../../models/music_models.dart';
import '../../../services/favorites_manager.dart';
import '../../../services/music_api_service.dart';

class AddMusicScreen extends StatefulWidget {
  final UserPlaylist playlist;
  final String userId;

  const AddMusicScreen({super.key, required this.playlist, required this.userId});

  @override
  State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
  final MusicApiService _musicApi = const MusicApiService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _pendingAdds = <String>{};

  UserPlaylist? _playlist;
  List<MusicTrack> _results = const <MusicTrack>[];
  bool _isSearching = false;
  String? _error;
  int _addedSongsCount = 0;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _loadTopSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserPlaylist currentPlaylist = _playlist ?? widget.playlist;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 375),
          child: Column(
            children: [
              _buildAppBar(context, currentPlaylist),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _performSearch,
                  onChanged: (value) {
                    setState(() {});
                    _onSearchChanged(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search songs or artists...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _error = null;
                              });
                              _loadTopSongs();
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildResults(currentPlaylist),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserPlaylist playlist) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF422006)),
              onPressed: () {
                // Show summary if songs were added
                if (_addedSongsCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_addedSongsCount song${_addedSongsCount == 1 ? '' : 's'} added to ${(_playlist ?? widget.playlist).playlistName}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                Navigator.pop(context, _playlist ?? widget.playlist);
              },
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Add Music',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF422006),
                    ),
                  ),
                  Text(
                    playlist.playlistName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: const Color(0xFF422006).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // Show summary if songs were added
                if (_addedSongsCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_addedSongsCount song${_addedSongsCount == 1 ? '' : 's'} added to ${(_playlist ?? widget.playlist).playlistName}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                Navigator.pop(context, _playlist ?? widget.playlist);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(UserPlaylist playlist) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Check if user typed only 1 character
    if (_searchController.text.trim().length == 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: const Color(0xFF422006).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Please enter at least 2 characters to search',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: const Color(0xFF422006).withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: Color(0xFF422006),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<Map<String, bool>>(
      stream: FavoritesManager.instance.favoritesStream,
      builder: (context, favSnapshot) {
        // Sync favorite states with FavoritesManager in real-time
        final syncedResults = _results.map((track) {
          final isLiked = FavoritesManager.instance.isFavorite(track.musicId);
          return track.copyWith(isLiked: isLiked);
        }).toList();
        
        return ListView.separated(
          itemCount: syncedResults.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final MusicTrack track = syncedResults[index];
        final bool alreadyAdded = playlist.songs.any((song) => song.musicId == track.musicId);
        final bool isLoading = _pendingAdds.contains(track.musicId);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _ArtworkPreview(url: track.thumbnailUrl ?? track.albumImageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF422006),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (track.isLiked == true)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.favorite,
                              size: 12,
                              color: Color(0xFFFF8A65),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            track.artist,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: const Color(0xFF422006).withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (alreadyAdded)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (isLoading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFFF8A65)),
                  onPressed: () => _addTrack(track),
                ),
            ],
          ),
        );
      },
    );
      },
    );
  }

  void _onSearchChanged(String query) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      _loadTopSongs();
      return;
    }
    if (trimmed.length >= 2) {
      _performSearch(trimmed);
    }
  }

  Future<void> _loadTopSongs() async {
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final List<MusicTrack> results = await _musicApi.getTopTracks(limit: 20);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Unable to load top songs: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      _loadTopSongs();
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final List<MusicTrack> results = await _musicApi.searchTracks(query: trimmed, limit: 20);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _addTrack(MusicTrack track) async {
    setState(() {
      _pendingAdds.add(track.musicId);
    });
    try {
      final UserPlaylist updated = await _musicApi.addSongToPlaylist(
        playlistId: (_playlist ?? widget.playlist).id,
        track: track,
      );
      
      // If added to Favorites playlist, refresh FavoritesManager
      if (updated.isFavorite || updated.playlistName.toLowerCase() == 'favorites') {
        await FavoritesManager.instance.loadFavorites(widget.userId);
      }
      
      // If added to Favorites playlist, refresh FavoritesManager
      if (updated.isFavorite || updated.playlistName.toLowerCase() == 'favorites') {
        await FavoritesManager.instance.loadFavorites(widget.userId, forceRefresh: true);
      }
      
      if (!mounted) {
        return;
      }
      setState(() {
        _playlist = updated;
        _addedSongsCount++;
      });
      if (!mounted) {
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to add song: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingAdds.remove(track.musicId);
      });
    }
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
