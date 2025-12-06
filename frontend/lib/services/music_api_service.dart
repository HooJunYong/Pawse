import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/music_models.dart';
import 'api_service.dart';

class MusicApiService {
  const MusicApiService();

  Future<List<MusicTrack>> getRecommendations({
    required MoodType mood,
    int limit = 10,
    String? market,
  }) async {
    final queryParameters = <String, String>{
      'mood': mood.apiValue,
      'limit': limit.toString(),
      if (market != null && market.isNotEmpty) 'market': market,
    };
    final endpoint = _buildEndpoint('/music/recommendations', queryParameters);
    final response = await ApiService.get(endpoint);
    _throwIfFailed(response.statusCode, response.body);
    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((dynamic item) => MusicTrack.fromJson(_normalizeMap(item)))
        .toList(growable: false);
  }

  Future<List<MusicAlbum>> getAlbumRecommendations({
    required MoodType mood,
    int albumLimit = 3,
    int minTracks = 5,
    int maxTracks = 8,
    String? market,
  }) async {
    final queryParameters = <String, String>{
      'mood': mood.apiValue,
      'album_limit': albumLimit.toString(),
      'min_tracks': minTracks.toString(),
      'max_tracks': maxTracks.toString(),
      if (market != null && market.isNotEmpty) 'market': market,
    };
    final endpoint =
        _buildEndpoint('/music/recommendations/albums', queryParameters);
    final response = await ApiService.get(endpoint);
    _throwIfFailed(response.statusCode, response.body);
    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((dynamic item) => MusicAlbum.fromJson(_normalizeMap(item)))
        .toList(growable: false);
  }

  Future<List<MoodOption>> getMoodOptions() async {
    final response = await ApiService.get('/music/moods');
    _throwIfFailed(response.statusCode, response.body);
    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((dynamic item) => MoodOption.fromJson(_normalizeMap(item)))
        .toList(growable: false);
  }

  Future<List<MoodTherapyRecommendation>> getMoodPlaylists(String userId) async {
    final endpoint = _buildEndpoint('/music/mood-playlists', {
      'user_id': userId,
    });
    final response = await ApiService.get(endpoint);
    _throwIfFailed(response.statusCode, response.body);
    if (response.body.isEmpty) {
      return const [];
    }
    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((dynamic item) => MoodTherapyRecommendation.fromJson(
              _normalizeMap(item),
              userId: userId,
            ))
        .toList(growable: false);
  }

  Future<List<MusicTrack>> searchTracks({
    required String query,
    int limit = 10,
    String? market,
  }) async {
    if (query.trim().isEmpty) {
      return const [];
    }
    final queryParameters = <String, String>{
      'query': query,
      'limit': limit.toString(),
      if (market != null && market.isNotEmpty) 'market': market,
    };
    final endpoint = _buildEndpoint('/music/search', queryParameters);
    final response = await ApiService.get(endpoint);
    _throwIfFailed(response.statusCode, response.body);
    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((dynamic item) => MusicTrack.fromJson(_normalizeMap(item)))
        .toList(growable: false);
  }

  Future<List<UserPlaylist>> listPlaylists(String userId) async {
    final endpoint = _buildEndpoint('/music/playlists', {
      'user_id': userId,
    });
    final response = await ApiService.get(endpoint);
    _throwIfFailed(response.statusCode, response.body);
    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((dynamic item) => UserPlaylist.fromJson(_normalizeMap(item)))
        .toList(growable: false);
  }

  Future<UserPlaylist> getPlaylist(String playlistId) async {
    final response = await ApiService.get('/music/playlists/$playlistId');
    _throwIfFailed(response.statusCode, response.body);
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserPlaylist.fromJson(body);
  }

  Future<UserPlaylist> createPlaylist({
    required String userId,
    required String name,
    String? icon,
    Color? color,
    List<String> customTags = const [],
    bool isPublic = false,
  }) async {
    // Use provided icon/color or generate random ones
    final String finalIcon = icon ?? (generateRandomPlaylistAppearance()['icon'] as String);
    final Color finalColor = color ?? (generateRandomPlaylistAppearance()['color'] as Color);
    
    final payload = {
      'user_id': userId,
      'playlist_name': name,
      'custom_tags': customTags,
      'is_public': isPublic,
      'songs': <Map<String, dynamic>>[],
      'icon': finalIcon,
      'color': '#${finalColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'is_favorite': false,
    };
    final response = await ApiService.post('/music/playlists', payload);
    _throwIfFailed(response.statusCode, response.body);
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserPlaylist.fromJson(body);
  }

  Future<UserPlaylist> addSongToPlaylist({
    required String playlistId,
    required MusicTrack track,
  }) async {
    final response = await ApiService.post(
      '/music/playlists/$playlistId/songs',
      track.toPlaylistSongPayload(),
    );
    _throwIfFailed(response.statusCode, response.body);
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserPlaylist.fromJson(body);
  }

  Future<UserPlaylist> removeSongFromPlaylist({
    required String playlistId,
    required String musicId,
  }) async {
    final response = await ApiService.delete('/music/playlists/$playlistId/songs/$musicId');
    if (response.statusCode == 204 || response.body.isEmpty) {
      return getPlaylist(playlistId);
    }
    _throwIfFailed(response.statusCode, response.body);
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserPlaylist.fromJson(body);
  }

  Future<UserPlaylist> updatePlaylist({
    required String playlistId,
    String? playlistName,
    bool? isFavorite,
    String? icon,
    String? color,
  }) async {
    final payload = <String, dynamic>{};
    if (playlistName != null) payload['playlist_name'] = playlistName;
    if (isFavorite != null) payload['is_favorite'] = isFavorite;
    if (icon != null) payload['icon'] = icon;
    if (color != null) payload['color'] = color;
    
    final response = await ApiService.patch('/music/playlists/$playlistId', payload);
    _throwIfFailed(response.statusCode, response.body);
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserPlaylist.fromJson(body);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final response = await ApiService.delete('/music/playlists/$playlistId');
    if (response.statusCode != 204 && response.statusCode != 200) {
      _throwIfFailed(response.statusCode, response.body);
    }
  }

  Future<void> logListeningSession({
    required String userId,
    String? playlistId,
    String? userPlaylistId,
    DateTime? startedAt,
    DateTime? endedAt,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (userPlaylistId != null) 'user_playlist_id': userPlaylistId,
      if (startedAt != null) 'started_at': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt.toUtc().toIso8601String(),
    };
    final response = await ApiService.post('/music/sessions', payload);
    _throwIfFailed(response.statusCode, response.body);
  }

  Future<List<MusicTrack>> getTopTracks({int limit = 10}) async {
    final endpoint = _buildEndpoint('/music/top-songs', {'limit': limit.toString()});
    final response = await ApiService.get(endpoint);
    _throwIfFailed(response.statusCode, response.body);
    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((dynamic item) => MusicTrack.fromJson(_normalizeMap(item)))
        .toList(growable: false);
  }

  Future<bool> toggleLike(String musicId, String userId) async {
    final endpoint = _buildEndpoint('/music/$musicId/toggle-like', {'user_id': userId});
    final response = await ApiService.post(endpoint, {});
    _throwIfFailed(response.statusCode, response.body);
    return jsonDecode(response.body) as bool;
  }

  String _buildEndpoint(String base, Map<String, String> queryParameters) {
    if (queryParameters.isEmpty) {
      return base;
    }
    final query = Uri(queryParameters: queryParameters).query;
    return '$base?$query';
  }

  void _throwIfFailed(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    String message = 'Music API call failed with status $statusCode';
    if (body.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final String? detail = decoded['detail'] as String?;
          if (detail != null && detail.isNotEmpty) {
            message = detail;
          }
        }
      } catch (_) {
        message = '$message: $body';
      }
    }
    throw Exception(message);
  }

  Map<String, dynamic> _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry('$key', v));
    }
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }
}
