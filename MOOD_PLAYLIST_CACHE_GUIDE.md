# Mood-Based Playlist Caching System

## Overview
The music home screen now intelligently caches mood-based playlists and only refreshes them when the user's mood actually changes. This prevents unnecessary API calls and provides a faster, more consistent experience.

## How It Works

### 1. **Mood Change Detection**
- The system tracks the user's last mood in SharedPreferences using the key `last_mood`
- When the user visits the music home screen, it checks if the mood has changed since the last playlist generation
- Playlists are only regenerated when a mood change is detected

### 2. **Caching Strategy**
- **First Load**: Attempts to load cached playlists instantly, then checks if mood changed in the background
- **App Resume**: Automatically checks if mood changed while app was in background
- **Pull to Refresh**: Checks for mood changes and regenerates playlists if needed
- **Error Recovery**: Retry button checks for mood changes before fetching new playlists

### 3. **Consistent Playlist Icons**
The backend generates playlists with random icons and colors from these sets:

**Icons:**
- 🎵 Musical Note (`Icons.music_note`)
- 📻 Radio (`Icons.radio`)
- 🎸 Album (`Icons.album`)

**Colors:**
- 🟡 Yellow (`Color(0xFFFFEB3B)`)
- 🔵 Blue (`Color(0xFF2196F3)`)
- 🟣 Purple (`Color(0xFF9C27B0)`)

**Example**: If user's mood is "happy", they might get:
1. "Uplifting Vibes" - Yellow album icon
2. "Energy Boost" - Blue radio icon  
3. "Feel Good Hits" - Purple music note icon

These icons and colors remain consistent until the mood changes.

## Integration with Mood Tracking

### When Saving a New Mood
After saving a mood entry, call the notification method to trigger playlist refresh:

```dart
import 'package:pawse/screens/wellness/music/music_home_screen.dart';

// After successfully saving mood
await saveMoodToBackend(userId, moodType, notes);

// Notify music system that mood changed
await MusicHomeScreen.notifyMoodChanged();

// Optional: Show feedback to user
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Music recommendations updated for your mood!')),
);
```

### Example: Mood Tracking Screen Integration

```dart
Future<void> _submitMood(String moodType) async {
  try {
    // Save mood to backend
    final response = await ApiService.post(
      '/mood/save',
      body: {
        'user_id': widget.userId,
        'mood': moodType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (response.statusCode == 200) {
      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_mood', moodType);
      
      // Notify music system
      await MusicHomeScreen.notifyMoodChanged();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mood saved! Music updated.')),
        );
      }
    }
  } catch (e) {
    // Handle error
  }
}
```

## User Experience Flow

### Scenario 1: First Time Opening Music Screen
1. **User opens music screen** → Shows loading indicator
2. **Fetches mood from backend** → "Happy" mood detected
3. **Generates 3 playlists** → Yellow album, Blue radio, Purple music note
4. **Caches playlists** → Stored locally with mood "happy"
5. **User returns later** → Same playlists appear instantly (no loading)

### Scenario 2: Mood Changes
1. **User updates mood** → Changes from "Happy" to "Sad"
2. **Saves mood entry** → Backend updated, `last_mood` set to "sad"
3. **User opens music screen** → Detects mood change from "happy" to "sad"
4. **Regenerates playlists** → New playlists for "Sad" mood
5. **Updates cache** → New playlists stored with mood "sad"

### Scenario 3: No Mood Change
1. **User opens music screen** → Loads cached playlists instantly
2. **Background check** → Confirms mood still "happy"
3. **No API call** → Shows existing playlists immediately
4. **User pulls to refresh** → Checks mood, no change detected
5. **Playlists unchanged** → Same icons and colors displayed

## SharedPreferences Keys

- `last_mood`: Current user mood (saved by mood tracking screens)
- `music_last_mood_{userId}`: Last mood used to generate playlists
- `music_mood_playlists_{userId}`: Cached playlist data (future enhancement)
- `music_mood_changed_flag`: Timestamp of last mood change notification

## Benefits

✅ **Faster Loading**: Cached playlists appear instantly  
✅ **Consistent UI**: Same playlist icons/colors until mood changes  
✅ **Reduced API Calls**: Only fetch when mood actually changes  
✅ **Better UX**: No flickering or unexpected playlist changes  
✅ **Offline Ready**: Can show cached playlists even when offline  

## Backend Behavior

The backend (`/music/mood-playlists` endpoint):
1. Reads user's latest mood from `mood_tracking` collection
2. Selects therapy blueprints based on mood
3. Searches iTunes for relevant tracks
4. Assigns random icons and colors to each playlist
5. Returns 3 curated playlists

The frontend now only calls this endpoint when mood changes are detected.

## Testing

### Test Mood Change Detection
1. Open music home screen → Note the 3 playlists and their icons
2. Go to mood tracking screen → Change mood from "Happy" to "Sad"
3. Return to music home screen → Should show different playlists
4. Close and reopen music screen → Should show same "Sad" mood playlists

### Test Caching
1. Open music home screen → Wait for playlists to load
2. Close and reopen screen → Should load instantly
3. Enable airplane mode → Playlists should still appear
4. Pull to refresh → Should handle offline gracefully

### Test Lifecycle
1. Open music home screen → Note current playlists
2. Put app in background → Change mood in another app instance
3. Bring app to foreground → Should detect mood change and refresh

## Future Enhancements

🔮 **Planned Features:**
- Full playlist JSON caching (currently just mood value is cached)
- Offline playlist generation from local database
- Mood history-based recommendations
- Time-of-day based playlist adjustments
- Smooth transitions when mood changes (fade in/out animation)

---

**Last Updated**: December 8, 2025  
**Status**: ✅ Implemented and Ready for Testing
