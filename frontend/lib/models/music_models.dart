import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String duration;
  final bool isLiked;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.duration,
    this.isLiked = false,
  });
}

class Playlist {
  final String id;
  final String title;
  final String creator;
  final String coverUrl;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.title,
    required this.creator,
    required this.coverUrl,
    required this.songs,
  });
}

class MoodCategory {
  final String id;
  final String title;
  final Color color;
  final IconData icon;

  MoodCategory({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
  });
}
