import 'package:flutter/material.dart';

/// Supported moods exposed by the backend recommendation endpoint.
enum MoodType {
  veryHappy,
  happy,
  neutral,
  sad,
  awful,
}

extension MoodTypeX on MoodType {
  /// API expects snake-case labels with a space separator.
  String get apiValue {
    switch (this) {
      case MoodType.veryHappy:
        return 'very happy';
      case MoodType.happy:
        return 'happy';
      case MoodType.neutral:
        return 'neutral';
      case MoodType.sad:
        return 'sad';
      case MoodType.awful:
        return 'awful';
    }
  }

  String get label {
    switch (this) {
      case MoodType.veryHappy:
        return 'Very Happy';
      case MoodType.happy:
        return 'Happy';
      case MoodType.neutral:
        return 'Neutral';
      case MoodType.sad:
        return 'Sad';
      case MoodType.awful:
        return 'Awful';
    }
  }
}

/// UI helper used by the home screen to render mood cards.
class MoodOption {
  final MoodType mood;
  final String title;
  final String icon;
  final Color color;

  const MoodOption({
    required this.mood,
    required this.title,
    required this.icon,
    required this.color,
  });

  factory MoodOption.fromJson(Map<String, dynamic> json) {
    final String rawColor = (json['color'] as String? ?? '').trim();
    return MoodOption(
      mood: _moodFromValue(json['mood'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? 'music_note',
      color: _colorFromHex(rawColor.isEmpty ? '#FFE082' : rawColor),
    );
  }

  IconData get iconData => _iconLookup[icon] ?? Icons.music_note;
}

class MusicTrack {
  final String musicId;
  final String title;
  final String artist;
  final int durationSeconds;
  final String? thumbnailUrl;
  final String? albumImageUrl;
  final String? moodCategory;
  final bool isLiked;
  final int playCount;
  final DateTime addedAt;

  const MusicTrack({
    required this.musicId,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.addedAt,
    this.thumbnailUrl,
    this.albumImageUrl,
    this.moodCategory,
    this.isLiked = false,
    this.playCount = 0,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      musicId: json['music_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds'] as int
          : int.tryParse('${json['duration_seconds']}') ?? 0,
      addedAt: DateTime.tryParse(json['added_at'] as String? ?? '') ?? DateTime.now().toUtc(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      albumImageUrl: json['album_image_url'] as String?,
      moodCategory: json['mood_category'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
      playCount: json['play_count'] is int
          ? json['play_count'] as int
          : int.tryParse('${json['play_count']}') ?? 0,
    );
  }

  Map<String, dynamic> toPlaylistSongPayload() {
    return {
      'music_id': musicId,
      'title': title,
      'artist': artist,
      'duration_seconds': durationSeconds,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (albumImageUrl != null) 'album_image_url': albumImageUrl,
      if (moodCategory != null) 'mood_category': moodCategory,
      'is_liked': isLiked,
    };
  }

  String get durationLabel => _formatDuration(durationSeconds);
}

class MusicAlbum {
  final String albumId;
  final String albumTitle;
  final String? albumImageUrl;
  final List<MusicTrack> tracks;

  const MusicAlbum({
    required this.albumId,
    required this.albumTitle,
    required this.albumImageUrl,
    required this.tracks,
  });

  factory MusicAlbum.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTracks = json['tracks'] as List<dynamic>? ?? const [];
    return MusicAlbum(
      albumId: json['album_id'] as String? ?? '',
      albumTitle: json['album_title'] as String? ?? '',
      albumImageUrl: json['album_image_url'] as String?,
      tracks: rawTracks
          .map((dynamic item) => MusicTrack.fromJson(
                (item is Map<String, dynamic>)
                    ? item
                    : Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }

  int get trackCount => tracks.length;
}

class PlaylistSong {
  final String musicId;
  final String title;
  final String artist;
  final int durationSeconds;
  final String? thumbnailUrl;
  final String? albumImageUrl;
  final String? moodCategory;
  final bool isLiked;

  const PlaylistSong({
    required this.musicId,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    this.thumbnailUrl,
    this.albumImageUrl,
    this.moodCategory,
    this.isLiked = false,
  });

  factory PlaylistSong.fromJson(Map<String, dynamic> json) {
    return PlaylistSong(
      musicId: json['music_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds'] as int
          : int.tryParse('${json['duration_seconds']}') ?? 0,
      thumbnailUrl: json['thumbnail_url'] as String?,
      albumImageUrl: json['album_image_url'] as String?,
      moodCategory: json['mood_category'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'music_id': musicId,
      'title': title,
      'artist': artist,
      'duration_seconds': durationSeconds,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (albumImageUrl != null) 'album_image_url': albumImageUrl,
      if (moodCategory != null) 'mood_category': moodCategory,
      'is_liked': isLiked,
    };
  }

  String get durationLabel => _formatDuration(durationSeconds);

  PlaylistSong copyWith({
    bool? isLiked,
  }) {
    return PlaylistSong(
      musicId: musicId,
      title: title,
      artist: artist,
      durationSeconds: durationSeconds,
      thumbnailUrl: thumbnailUrl,
      albumImageUrl: albumImageUrl,
      moodCategory: moodCategory,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class UserPlaylist {
  final String id;
  final String playlistName;
  final String userId;
  final List<String> customTags;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlaylistSong> songs;

  const UserPlaylist({
    required this.id,
    required this.playlistName,
    required this.userId,
    required this.customTags,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    required this.songs,
  });

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawSongs = json['songs'] as List<dynamic>?;
    return UserPlaylist(
      id: json['user_playlist_id'] as String? ?? json['id'] as String? ?? '',
      playlistName: json['playlist_name'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      customTags: (json['custom_tags'] as List<dynamic>? ?? const [])
          .map((dynamic e) => e.toString())
          .toList(growable: false),
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now().toUtc(),
      songs: rawSongs == null
          ? const []
          : rawSongs
              .map((dynamic song) => PlaylistSong.fromJson(
                    (song is Map<String, dynamic>)
                        ? song
                        : Map<String, dynamic>.from(song as Map),
                  ))
              .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_playlist_id': id,
      'playlist_name': playlistName,
      'user_id': userId,
      'custom_tags': customTags,
      'is_public': isPublic,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'songs': songs.map((song) => song.toJson()).toList(growable: false),
    };
  }

  UserPlaylist copyWith({
    String? playlistName,
    List<String>? customTags,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlaylistSong>? songs,
  }) {
    return UserPlaylist(
      id: id,
      playlistName: playlistName ?? this.playlistName,
      userId: userId,
      customTags: customTags ?? this.customTags,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songs: songs ?? this.songs,
    );
  }

  int get songCount => songs.length;
}

String _formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) {
    return '0:00';
  }
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
}

MoodType _moodFromValue(String value) {
  return MoodType.values.firstWhere(
    (mood) => mood.apiValue == value || mood.name == value,
    orElse: () => MoodType.happy,
  );
}

Color _colorFromHex(String hex) {
  var cleaned = hex.replaceAll('#', '').toUpperCase();
  if (cleaned.length == 6) {
    cleaned = 'FF$cleaned';
  }
  final int colorInt = int.tryParse(cleaned, radix: 16) ?? 0xFFFFE082;
  return Color(colorInt);
}

const Map<String, IconData> _iconLookup = <String, IconData>{
  'cloud': Icons.cloud,
  'book': Icons.book,
  'bolt': Icons.bolt,
  'spa': Icons.spa,
  'self_improvement': Icons.self_improvement,
  'music_note': Icons.music_note,
};
