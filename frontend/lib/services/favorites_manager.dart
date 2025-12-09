import 'dart:async';

import '../models/music_models.dart';
import 'music_api_service.dart';

/// Singleton service to manage favorite songs state across the app
/// Provides real-time updates when favorites are toggled
class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  static FavoritesManager get instance => _instance;

  final MusicApiService _musicApi = const MusicApiService();
  final StreamController<Map<String, bool>> _favoritesController =
      StreamController<Map<String, bool>>.broadcast();
  
  final Map<String, bool> _favoriteStates = {};
  String? _currentUserId;
  UserPlaylist? _favoritesPlaylist;

  /// Stream of favorite states (musicId -> isLiked)
  Stream<Map<String, bool>> get favoritesStream => _favoritesController.stream;

  /// Get current favorite state for a track
  bool isFavorite(String musicId) {
    return _favoriteStates[musicId] ?? false;
  }

  /// Get current favorites playlist
  UserPlaylist? get favoritesPlaylist => _favoritesPlaylist;

  /// Initialize favorites for a user
  Future<void> loadFavorites(String userId) async {
    if (_currentUserId == userId && _favoriteStates.isNotEmpty) {
      return; // Already loaded for this user
    }

    _currentUserId = userId;
    _favoriteStates.clear();

    try {
      // Get all playlists to find the favorites playlist
      final playlists = await _musicApi.listPlaylists(userId);
      _favoritesPlaylist = playlists.firstWhere(
        (p) => p.isFavorite,
        orElse: () => throw Exception('No favorites playlist found'),
      );

      // Load all favorited song IDs
      for (final song in _favoritesPlaylist!.songs) {
        _favoriteStates[song.musicId] = true;
      }

      _notifyListeners();
    } catch (e) {
      // Create favorites playlist if it doesn't exist
      try {
        _favoritesPlaylist = await _musicApi.createPlaylist(
          userId: userId,
          name: 'Favorites',
          icon: 'favorite',
          isPublic: false,
        );
        
        // Mark as favorite playlist
        _favoritesPlaylist = await _musicApi.updatePlaylist(
          playlistId: _favoritesPlaylist!.id,
          isFavorite: true,
        );
        
        _notifyListeners();
      } catch (createError) {
        // Silent fail - app can still function
      }
    }
  }

  /// Toggle favorite state for a track
  Future<bool> toggleFavorite(String musicId, MusicTrack track, String userId) async {
    final bool currentState = _favoriteStates[musicId] ?? false;
    final bool newState = !currentState;

    // Optimistic update
    _favoriteStates[musicId] = newState;
    _notifyListeners();

    try {
      // Call backend API
      final bool serverState = await _musicApi.toggleLike(musicId, userId);

      // Ensure favorites playlist exists
      if (_favoritesPlaylist == null) {
        await loadFavorites(userId);
      }

      if (_favoritesPlaylist != null) {
        if (serverState) {
          // Add to favorites playlist
          _favoritesPlaylist = await _musicApi.addSongToPlaylist(
            playlistId: _favoritesPlaylist!.id,
            track: track,
          );
        } else {
          // Remove from favorites playlist
          _favoritesPlaylist = await _musicApi.removeSongFromPlaylist(
            playlistId: _favoritesPlaylist!.id,
            musicId: musicId,
          );
        }
      }

      // Update state with server response
      _favoriteStates[musicId] = serverState;
      _notifyListeners();

      return serverState;
    } catch (e) {
      // Revert on error
      _favoriteStates[musicId] = currentState;
      _notifyListeners();
      rethrow;
    }
  }

  /// Update favorite state without toggling (used when loading tracks)
  void updateFavoriteState(String musicId, bool isLiked) {
    _favoriteStates[musicId] = isLiked;
    _notifyListeners();
  }

  /// Refresh favorites playlist from server
  Future<void> refreshFavoritesPlaylist(String userId) async {
    if (_favoritesPlaylist == null) {
      await loadFavorites(userId);
      return;
    }

    try {
      _favoritesPlaylist = await _musicApi.getPlaylist(_favoritesPlaylist!.id);
      
      // Update states from refreshed playlist
      _favoriteStates.clear();
      for (final song in _favoritesPlaylist!.songs) {
        _favoriteStates[song.musicId] = true;
      }
      
      _notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }

  void _notifyListeners() {
    _favoritesController.add(Map.from(_favoriteStates));
  }

  /// Clear all data (call on logout)
  void clear() {
    _favoriteStates.clear();
    _currentUserId = null;
    _favoritesPlaylist = null;
    _notifyListeners();
  }

  void dispose() {
    _favoritesController.close();
  }
}
