import 'package:flutter/material.dart';

import '../../../models/music_models.dart';
import 'music_player_screen.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailsScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    // Dummy songs for the playlist
    final songs = [
      Song(id: '1', title: 'Good Days', artist: 'SZA', albumArtUrl: '', duration: '3:20'),
      Song(id: '2', title: 'Lovely Day', artist: 'Bill Withers', albumArtUrl: '', duration: '4:15'),
      Song(id: '3', title: 'Walking on Sunshine', artist: 'Katrina & The Waves', albumArtUrl: '', duration: '3:58'),
      Song(id: '4', title: 'Someone Like You', artist: 'Adele', albumArtUrl: '', duration: '4:45', isLiked: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 375),
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildControls(),
                    const SizedBox(height: 24),
                    ...songs.map((song) => _buildSongItem(context, song)),
                  ],
                ),
              ),
              _buildMiniPlayer(context),
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
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Color(0xFF422006)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF80CBC4), // Teal color from image
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.spa, size: 80, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          playlist.title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Created by ${playlist.creator} • 12 Songs',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: const Color(0xFF422006).withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
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
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            icon: const Icon(Icons.shuffle, color: Color(0xFF5D4037)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSongItem(BuildContext context, Song song) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MusicPlayerScreen()),
          );
        },
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC80), // Placeholder color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    song.title[0],
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                  ),
                ),
              ),
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
              if (song.isLiked)
                const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20)
              else
                const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MusicPlayerScreen()),
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
              child: const Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Someone Like You',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF422006),
                    ),
                  ),
                  Text(
                    'Adele',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20),
            const SizedBox(width: 12),
            const Icon(Icons.pause_circle_filled, color: Color(0xFF422006), size: 32),
          ],
        ),
      ),
    );
  }
}
