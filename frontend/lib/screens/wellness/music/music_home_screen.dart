import 'package:flutter/material.dart';

import '../../../models/music_models.dart';
import 'create_playlist_screen.dart';
import 'music_player_screen.dart';
import 'playlist_details_screen.dart';

class MusicHomeScreen extends StatelessWidget {
  const MusicHomeScreen({super.key});

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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildMoodSection(),
                    const SizedBox(height: 24),
                    _buildPlaylistsSection(context),
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
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
    final moods = [
      MoodCategory(id: '1', title: 'Calm', color: const Color(0xFFFFE082), icon: Icons.cloud),
      MoodCategory(id: '2', title: 'Focus', color: const Color(0xFFFFAB91), icon: Icons.book),
      MoodCategory(id: '3', title: 'Empower', color: const Color(0xFFFFCC80), icon: Icons.bolt),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Based On Your Mood',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF422006),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final mood = moods[index];
              return Container(
                width: 100,
                decoration: BoxDecoration(
                  color: mood.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mood.icon, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      mood.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSection(BuildContext context) {
    final playlists = [
      Playlist(
        id: '1',
        title: 'Monday Motivation',
        creator: 'Sarah',
        coverUrl: 'assets/images/playlist_cover_1.png', // Placeholder
        songs: [],
      ),
      Playlist(
        id: '2',
        title: 'Hopeful Vibes',
        creator: 'You',
        coverUrl: 'assets/images/playlist_cover_2.png', // Placeholder
        songs: [],
      ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Playlists',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF422006),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFFF8A65)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreatePlaylistScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...playlists.map((playlist) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaylistDetailsScreen(playlist: playlist)),
              );
            },
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF422006),
                        ),
                      ),
                      Text(
                        '${playlist.songs.length + 8} Songs', // Dummy count
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: const Color(0xFF422006).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
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
