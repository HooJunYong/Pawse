import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/music_models.dart';
import '../../../services/audio_manager.dart';
import '../../../services/favorites_manager.dart';
import '../../../services/music_api_service.dart';
import 'add_music_screen.dart';
import 'music_player_screen.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final UserPlaylist playlist;
  final String userId;
  final bool isReadOnly;
  final String? coverImageUrl;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlist,
    required this.userId,
    this.isReadOnly = false,
    this.coverImageUrl,
  });

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  final MusicApiService _musicApi = const MusicApiService();
  final FavoritesManager _favoritesManager = FavoritesManager.instance;
  StreamSubscription<Map<String, bool>>? _favoritesSub;
  UserPlaylist? _playlist;
  final Set<String> _pendingRemoval = <String>{};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _playlist = _syncPlaylistFavorites(widget.playlist);
    
    // Listen for favorite changes
    _favoritesSub = _favoritesManager.favoritesStream.listen((_) async {
      if (mounted && _playlist != null) {
        // If this is the Favorites playlist, refresh from backend to get newly added songs
        if (_playlist!.isFavorite || _playlist!.playlistName.toLowerCase() == 'favorites') {
          await _refreshPlaylistFromBackend();
        } else {
          // For other playlists, just sync the isLiked flags
          setState(() {
            _playlist = _syncPlaylistFavorites(_playlist!);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    super.dispose();
  }

  /// Sync playlist songs with current favorite states
  UserPlaylist _syncPlaylistFavorites(UserPlaylist playlist) {
    // If this is the Favorites playlist, filter out unliked songs
    if (playlist.isFavorite || playlist.playlistName.toLowerCase() == 'favorites') {
      final likedSongs = playlist.songs.where((song) {
        return _favoritesManager.isFavorite(song.musicId);
      }).map((song) {
        return song.copyWith(isLiked: true);
      }).toList();
      
      return playlist.copyWith(songs: likedSongs);
    }
    
    // For other playlists, just update the isLiked flag without removing songs
    final syncedSongs = playlist.songs.map((song) {
      final isLiked = _favoritesManager.isFavorite(song.musicId);
      return song.copyWith(isLiked: isLiked);
    }).toList();
    
    return playlist.copyWith(songs: syncedSongs);
  }

  @override
  Widget build(BuildContext context) {
    final UserPlaylist playlist = _playlist ?? widget.playlist;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'action': 'updated',
          'playlist': _playlist ?? widget.playlist,
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4F2),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              children: [
                _buildAppBar(context, playlist),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshPlaylist,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildHeader(playlist),
                        const SizedBox(height: 24),
                        _buildControls(context, playlist),
                        const SizedBox(height: 24),
                        if (playlist.songs.isEmpty)
                          _EmptyState(onAddSongs: () => _openAddMusic(context, playlist))
                        else
                          ...playlist.songs.map((song) => _SongTile(
                                song: song,
                                onPlay: () => _openPlayer(song),
                                onRemove: () => _removeSong(song),
                                isRemoving: _pendingRemoval.contains(song.musicId),
                                showRemove: !widget.isReadOnly,
                              )),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _MiniPlayer(
                  track: playlist.songs.isEmpty ? null : playlist.songs.first,
                  userId: widget.userId,
                ),
              ],
            ),
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
              onPressed: () => Navigator.pop(context, {
                'action': 'updated',
                'playlist': _playlist ?? widget.playlist,
              }),
            ),
            const Expanded(
              child: Text(
                'Playlists',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF422006),
                ),
              ),
            ),
            if (!widget.isReadOnly && !playlist.isFavorite && playlist.playlistName != 'Favorites')
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Color(0xFF422006)),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, playlist);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete playlist'),
                  ),
                ],
              )
            else
              const SizedBox(width: 48), // Placeholder to balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserPlaylist playlist) {
    final PlaylistSong? firstSong = playlist.songs.isNotEmpty ? playlist.songs.first : null;
    final String? coverUrl = () {
      final String? explicit = widget.coverImageUrl;
      if (explicit != null && explicit.isNotEmpty) {
        return explicit;
      }
      if (firstSong?.albumImageUrl != null && firstSong!.albumImageUrl!.isNotEmpty) {
        return firstSong.albumImageUrl;
      }
      if (firstSong?.thumbnailUrl != null && firstSong!.thumbnailUrl!.isNotEmpty) {
        return firstSong.thumbnailUrl;
      }
      return null;
    }();

    Widget _buildArtwork() {
      // Use playlist icon/color instead of cover image
      final bool isFavorites = playlist.playlistName.toLowerCase() == 'favorites';
      final Color bgColor = isFavorites ? Colors.red : playlist.color;
      final IconData icon = isFavorites 
          ? Icons.favorite 
          : iconDataFromString(playlist.icon);

      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, size: 80, color: Colors.white),
      );
    }

    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildArtwork(),
        ),
        const SizedBox(height: 20),
        Text(
          playlist.playlistName,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isReadOnly
              ? '${playlist.songCount} song${playlist.songCount == 1 ? '' : 's'}'
              : 'Created by you • ${playlist.songCount} song${playlist.songCount == 1 ? '' : 's'}',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: const Color(0xFF422006).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, UserPlaylist playlist) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: playlist.songs.isEmpty ? null : () => _openPlayer(playlist.songs.first),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (!widget.isReadOnly) ...[
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFFFF8A65)),
            onPressed: () => _openAddMusic(context, playlist),
          ),
        ],
      ],
    );
  }

  Future<void> _openAddMusic(BuildContext context, UserPlaylist playlist) async {
    final UserPlaylist? updated = await Navigator.push<UserPlaylist?>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMusicScreen(
          playlist: playlist,
          userId: widget.userId,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _playlist = updated;
      });
    }
  }

  Future<void> _removeSong(PlaylistSong song) async {
    setState(() {
      _pendingRemoval.add(song.musicId);
    });
    try {
      final UserPlaylist updated = await _musicApi.removeSongFromPlaylist(
        playlistId: (_playlist ?? widget.playlist).id,
        musicId: song.musicId,
      );
      
      // If removing from Favorites playlist, refresh FavoritesManager to update heart icons
      final currentPlaylist = _playlist ?? widget.playlist;
      if (currentPlaylist.isFavorite || currentPlaylist.playlistName.toLowerCase() == 'favorites') {
        await FavoritesManager.instance.loadFavorites(widget.userId, forceRefresh: true);
      }
      
      if (!mounted) {
        return;
      }
      setState(() {
        _playlist = updated;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove song: $error')),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingRemoval.remove(song.musicId);
      });
    }
  }

  Future<void> _openPlayer(PlaylistSong song) async {
    final UserPlaylist currentPlaylist = _playlist ?? widget.playlist;
    final List<MusicTrack> tracks = currentPlaylist.songs.map((s) => MusicTrack(
      musicId: s.musicId,
      title: s.title,
      artist: s.artist,
      durationSeconds: s.durationSeconds,
      addedAt: DateTime.now().toUtc(),
      thumbnailUrl: s.thumbnailUrl,
      albumImageUrl: s.albumImageUrl,
      audioUrl: s.audioUrl,
      moodCategory: s.moodCategory,
      isLiked: s.isLiked,
    )).toList();

    final int index = tracks.indexWhere((t) => t.musicId == song.musicId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerScreen(
          track: index != -1 ? tracks[index] : null,
          playlist: tracks,
          initialIndex: index != -1 ? index : 0,
          userId: widget.userId,
          playlistName: widget.playlist.playlistName,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserPlaylist playlist) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete playlist?',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        content: Text(
          '"${playlist.playlistName}" will be permanently removed.',
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Color(0xFF422006),
          ),
        ),
        backgroundColor: const Color(0xFFF7F4F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Color(0xFF422006),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _musicApi.deletePlaylist(playlist.id);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, {
        'action': 'deleted',
        'playlistId': playlist.id,
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete playlist: $error')),
      );
    }
  }

  Future<void> _refreshPlaylist() async {
    if (widget.isReadOnly) return;
    if (_isRefreshing) {
      return;
    }
    setState(() {
      _isRefreshing = true;
    });
    try {
      final UserPlaylist refreshed = await _musicApi.getPlaylist((_playlist ?? widget.playlist).id);
      if (!mounted) {
        return;
      }
      setState(() {
        _playlist = refreshed;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to refresh playlist: $error')),
        );
      }
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  /// Refresh playlist from backend (used for Favorites playlist real-time updates)
  Future<void> _refreshPlaylistFromBackend() async {
    if (_isRefreshing) return;
    
    try {
      final UserPlaylist refreshed = await _musicApi.getPlaylist((_playlist ?? widget.playlist).id);
      if (!mounted) {
        return;
      }
      setState(() {
        _playlist = refreshed;
      });
    } catch (error) {
      // Silently fail - user can manually refresh if needed
      if (mounted) {
        setState(() {
          _playlist = _syncPlaylistFavorites(_playlist!);
        });
      }
    }
  }
}

class _SongTile extends StatelessWidget {
  final PlaylistSong song;
  final VoidCallback onPlay;
  final VoidCallback onRemove;
  final bool isRemoving;
  final bool showRemove;

  const _SongTile({
    required this.song,
    required this.onPlay,
    required this.onRemove,
    required this.isRemoving,
    this.showRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onPlay,
        child: Container(
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
              _ArtworkPreview(url: song.thumbnailUrl ?? song.albumImageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF422006),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: const Color(0xFF422006).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (showRemove)
                if (isRemoving)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Color(0xFFEF5350)),
                    onPressed: onRemove,
                  ),
            ],
          ),
        ),
      ),
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

class _MiniPlayer extends StatelessWidget {
  final PlaylistSong? track;
  final String userId;

  const _MiniPlayer({this.track, required this.userId});

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
                    final Duration position = positionSnapshot.data ?? Duration.zero;
                    final double progress = totalDuration.inMilliseconds > 0
                        ? (position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
                        : 0;

                    if (track == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Material(
                        color: Colors.white,
                        elevation: 6,
                        shadowColor: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(32),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => MusicPlayerScreen(
                                  attachToExistingSession: true,
                                  userId: userId,
                                ),
                              ),
                            );
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
                                      child: (track.albumImageUrl != null && track.albumImageUrl!.isNotEmpty) ||
                                             (track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty)
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
                                                  track.title.substring(0, 1).toUpperCase(),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            track.title,
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
                                            track.artist,
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
                                      onPressed: () => audioManager.togglePlayPause(),
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
                                    value: progress,
                                    backgroundColor: const Color(0xFFFFE0B2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddSongs;

  const _EmptyState({required this.onAddSongs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'No songs yet',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Use the add button to search Spotify and fill this playlist with songs you love.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: const Color(0xFF422006).withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onAddSongs,
          icon: const Icon(Icons.add),
          label: const Text('Add songs'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5D4037),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }
}
