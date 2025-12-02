import 'package:flutter/material.dart';

import '../../../models/music_models.dart';

class MusicPlayerScreen extends StatelessWidget {
  final MusicTrack? track;

  const MusicPlayerScreen({super.key, this.track});

  @override
  Widget build(BuildContext context) {
    final MusicTrack? selectedTrack = track;
    final String title = selectedTrack?.title ?? 'Take a mindful pause';
    final String artist = selectedTrack?.artist ?? 'Press play to begin';
    final String totalDuration = selectedTrack?.durationLabel ?? '0:00';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF422006)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Now Playing',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Color(0xFF422006),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF422006)),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 375),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AlbumArt(selectedTrack: selectedTrack),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF422006),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Progress Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF5D4037),
                      inactiveTrackColor: const Color(0xFF5D4037).withOpacity(0.2),
                      thumbColor: const Color(0xFF5D4037),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: 0.3,
                      onChanged: (value) {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('0:00', style: TextStyle(fontFamily: 'Nunito', fontSize: 12)),
                        Text(totalDuration, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle, color: Colors.grey),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 36, color: Color(0xFF422006)),
                    onPressed: () {},
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5D4037).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.pause, color: Colors.white, size: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 36, color: Color(0xFF422006)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final MusicTrack? selectedTrack;

  const _AlbumArt({required this.selectedTrack});

  @override
  Widget build(BuildContext context) {
    final String? albumImage = selectedTrack?.albumImageUrl ?? selectedTrack?.thumbnailUrl;
    final Widget fallback = Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFFFCC80),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Icon(Icons.music_note, size: 120, color: Colors.white),
    );

    if (albumImage == null || albumImage.isEmpty) {
      return fallback;
    }

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        albumImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
