import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../services/activity_service.dart';
import '../../../services/profile_service.dart';

class ActivityController extends ChangeNotifier {
  final String userId;

  bool _isLoading = true;
  String? _errorMessage;
  String _userFirstName = 'Friend';
  String _userInitials = 'U';
  ImageProvider? _userAvatarImage;
  String _rankName = "Bronze";
  int _currentPoints = 0;
  int _nextRankPoints = 0;
  int _pointsNeeded = 0;
  double _progressPercentage = 0.0;
  List<Map<String, dynamic>> _activities = [];
  int _completedCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userFirstName => _userFirstName;
  String get userInitials => _userInitials;
  ImageProvider? get userAvatarImage => _userAvatarImage;
  String get rankName => _rankName;
  int get currentPoints => _currentPoints;
  int get nextRankPoints => _nextRankPoints;
  int get pointsNeeded => _pointsNeeded;
  double get progressPercentage => _progressPercentage;
  List<Map<String, dynamic>> get activities => _activities;
  int get completedCount => _completedCount;

  ActivityController({required this.userId});

  Future<void> loadActivityData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load user profile
      await _loadUserProfile();

      // Load rank progress
      final rankProgress = await ActivityService.getRankProgress(userId);
      if (rankProgress != null) {
        _rankName = rankProgress['current_rank_name'] ?? 'Bronze';
        _currentPoints = rankProgress['lifetime_points'] ?? 0;
        _nextRankPoints = rankProgress['next_rank_min_points'] ?? 0;
        _pointsNeeded = rankProgress['points_needed'] ?? 0;
        _progressPercentage = (rankProgress['progress_percentage'] ?? 0).toDouble();
      }

      // Load daily activities
      final activitiesData = await ActivityService.getDailyActivities(userId);
      if (activitiesData != null) {
        _activities = List<Map<String, dynamic>>.from(activitiesData['activities'] ?? []);
        _completedCount = activitiesData['completed_count'] ?? 0;
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load activity data: $e';
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ProfileService.getProfile(userId);
      if (response.statusCode != 200) {
        return;
      }
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final String firstName = _extractFirstName(decoded['full_name']);
        final String initials = _extractInitials(
          decoded['initials'],
          decoded['full_name'],
        );
        final ImageProvider? avatar = _resolveProfileAvatar(
          decoded['avatar_base64']?.toString(),
          decoded['avatar_url']?.toString(),
        );

        _userFirstName = firstName.isNotEmpty ? firstName : 'Friend';
        _userInitials = initials.isNotEmpty ? initials : 'U';
        _userAvatarImage = avatar;
      }
    } catch (_) {
      // Silently ignore profile load failures; keep friendly fallback.
    }
  }

  String _extractFirstName(dynamic fullNameValue) {
    if (fullNameValue is! String) {
      return '';
    }
    final String trimmed = fullNameValue.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '';
    }
    final String first = parts.first.trim();
    if (first.isEmpty) {
      return '';
    }
    if (first.length == 1) {
      return first.toUpperCase();
    }
    return first[0].toUpperCase() + first.substring(1);
  }

  String _extractInitials(dynamic initialsValue, dynamic fullNameValue) {
    if (initialsValue is String && initialsValue.trim().isNotEmpty) {
      final trimmed = initialsValue.trim();
      return trimmed.length > 2
          ? trimmed.substring(0, 2).toUpperCase()
          : trimmed.toUpperCase();
    }
    if (fullNameValue is! String) {
      return '';
    }
    final parts = fullNameValue
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    final firstInitial = parts[0][0].toUpperCase();
    final secondInitial = parts[1][0].toUpperCase();
    return '$firstInitial$secondInitial';
  }

  ImageProvider? _resolveProfileAvatar(String? base64Value, String? urlValue) {
    final ImageProvider? fromBase64 = _decodeAvatarBase64(base64Value);
    if (fromBase64 != null) {
      return fromBase64;
    }

    final String? trimmedUrl = urlValue?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return null;
    }
    if (_isDataUri(trimmedUrl)) {
      final bytes = _decodeDataUri(trimmedUrl);
      return bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null;
    }
    return NetworkImage(trimmedUrl);
  }

  ImageProvider? _decodeAvatarBase64(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_isDataUri(trimmed)) {
      final bytes = _decodeDataUri(trimmed);
      return bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null;
    }
    try {
      final bytes = base64Decode(trimmed);
      return bytes.isNotEmpty ? MemoryImage(bytes) : null;
    } catch (_) {
      return null;
    }
  }

  bool _isDataUri(String? value) {
    if (value == null) {
      return false;
    }
    final lower = value.toLowerCase();
    return lower.startsWith('data:image/');
  }

  Uint8List? _decodeDataUri(String dataUri) {
    final separator = dataUri.indexOf(',');
    if (separator == -1 || separator == dataUri.length - 1) {
      return null;
    }
    final payload = dataUri.substring(separator + 1).trim();
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}
