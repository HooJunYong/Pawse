import 'package:flutter/material.dart';

import '../../../models/music_models.dart';
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
  UserPlaylist? _playlist;
  final Set<String> _pendingRemoval = <String>{};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
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
                _MiniPlayer(track: playlist.songs.isEmpty ? null : playlist.songs.first),
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
            if (!widget.isReadOnly)
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
      if (coverUrl != null && coverUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF80CBC4),
              alignment: Alignment.center,
              child: const Icon(Icons.spa, size: 80, color: Colors.white),
            ),
          ),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF80CBC4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.spa, size: 80, color: Colors.white),
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
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserPlaylist playlist) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: Text('"${playlist.playlistName}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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

  const _MiniPlayer({this.track});

  @override
  Widget build(BuildContext context) {
    final PlaylistSong? song = track;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayerScreen(
              track: song == null
                  ? null
                  : MusicTrack(
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
                    ),
            ),
          ),
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
                  song?.title.substring(0, 1).toUpperCase() ?? '♪',
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
                    song?.title ?? 'Nothing playing yet',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF422006),
                    ),
                  ),
                  Text(
                    song?.artist ?? 'Tap to choose a track',
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
