# Mood Nudge Feature Implementation

## Overview
The Mood Nudge feature provides intelligent, scheduled local notifications that check in on users 10 minutes after they log their mood in the journaling screen. This feature enhances user retention and provides personalized care based on emotional state.

## Architecture

### Backend Components

1. **Mood Nudge Service** (`backend/app/services/mood_nudge_service.py`)
   - Stores 10 curated prompts for each of 5 mood types
   - Provides random nudge selection for each mood
   - Initializes mood nudges in MongoDB on startup

2. **Mood Nudge Routes** (`backend/app/routes/mood_nudge_routes.py`)
   - `GET /mood-nudges/{mood}` - Get all nudges for a mood
   - `GET /mood-nudges/{mood}/random` - Get a random nudge
   - `POST /mood-nudges/initialize` - Initialize/update database

3. **Mood Nudge Schemas** (`backend/app/models/mood_nudge_schemas.py`)
   - `MoodNudge` - Single nudge prompt model
   - `MoodNudgeResponse` - Response with list of nudges

4. **Database**
   - Collection: `mood_nudges`
   - Stores prompts organized by mood type

### Frontend Components

1. **Local Notification Service** (`frontend/lib/services/local_notification_service.dart`)
   - Initializes `flutter_local_notifications` plugin
   - Handles Android and iOS notification settings
   - Schedules notifications with timezone support
   - Manages notification permissions

2. **Mood Nudge Service** (`frontend/lib/services/mood_nudge_service.dart`)
   - Schedules 10-minute delayed notifications
   - Cancels previous nudges when new mood is logged
   - Stores offline fallback nudges
   - Manages user preferences for nudges

3. **Journaling Screen Integration** (`frontend/lib/screens/wellness/journaling_screen.dart`)
   - Added mood selector UI with 5 mood options
   - Integrated mood nudge scheduling on entry save
   - Shows confirmation message when nudge is scheduled
   - Stores mood in journal entry's `emotionalTags` field

## Mood Types and Prompts

### 1. Very Happy (😄)
10 prompts focused on:
- Anchoring positive moments
- Sharing joy with others
- Tackling challenging tasks while energized
- Gratitude practices
- Physical celebration

### 2. Happy (🙂)
10 prompts focused on:
- Savoring calm moments
- Light physical activity
- Mindful practices
- Goal review
- Social connection

### 3. Neutral (😐)
10 prompts focused on:
- Body awareness
- Breaking routine
- Setting small intentions
- Sensory stimulation
- Breathing techniques

### 4. Sad (😢)
10 prompts focused on:
- Self-compassion
- Low-effort self-care
- Emotional expression
- Gentle movement
- Rest and comfort

### 5. Awful (😫)
10 prompts focused on:
- Crisis grounding techniques
- Immediate relief strategies
- Support seeking
- Environment adjustment
- Hope and perspective

## User Flow

1. **User Opens Journaling Screen**
   - Sees today's prompt
   - Writes journal entry
   - Selects current mood (optional)

2. **User Saves Entry**
   - Mood is saved in `emotionalTags`
   - 10-minute notification is scheduled
   - Confirmation message appears
   - Previous nudge is cancelled if exists

3. **10 Minutes Later**
   - Phone displays local notification
   - Title and message based on mood
   - User can tap to open app
   - Notification persists until dismissed

## Setup Instructions

### Backend Setup
1. Install dependencies (already in requirements.txt)
2. Server automatically initializes mood nudges on startup
3. Test endpoint: `GET /mood-nudges/happy/random`

### Frontend Setup

1. **Install Dependencies**
   ```bash
   cd frontend
   flutter pub get
   ```

2. **Android Configuration**
   Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   
   <application ...>
       <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
       <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
           <intent-filter>
               <action android:name="android.intent.action.BOOT_COMPLETED"/>
               <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
           </intent-filter>
       </receiver>
   </application>
   ```

3. **iOS Configuration**
   iOS permissions are requested automatically at runtime.
   No additional configuration needed.

4. **Run the App**
   ```bash
   flutter run
   ```

## Testing

### Test Mood Nudge (Frontend)
1. Open journaling screen
2. Write an entry
3. Select a mood (e.g., "Sad")
4. Save entry
5. Wait 10 minutes
6. Notification should appear

### Test Backend API
```bash
# Get random nudge for sad mood
curl http://localhost:8000/mood-nudges/sad/random

# Get all nudges for happy mood
curl http://localhost:8000/mood-nudges/happy

# Initialize/update nudges
curl -X POST http://localhost:8000/mood-nudges/initialize
```

## Configuration

### Enable/Disable Nudges
Users can enable/disable mood nudges in notification settings:
```dart
final nudgeService = MoodNudgeService();
await nudgeService.setNudgesEnabled(false); // Disable
```

### Adjust Delay Time
Currently set to 10 minutes. To change, modify in `mood_nudge_service.dart`:
```dart
delay: const Duration(minutes: 10), // Change this
```

## Database Schema

### Notification Settings
```json
{
  "user_id": "string",
  "mood_nudges_enabled": true,
  ...
}
```

### Mood Nudges Collection
```json
{
  "mood": "sad",
  "nudges": [
    {
      "title": "Permission to Feel",
      "message": "It's okay to feel this way...",
      "action": "open_journal"
    }
  ]
}
```

## Future Enhancements

1. **Smart Timing**: Adjust delay based on mood severity
2. **Nudge History**: Track which nudges were most effective
3. **API Integration**: Fetch nudges from backend instead of using offline fallback
4. **Action Handlers**: Deep link to specific screens based on nudge action
5. **Customization**: Allow users to add their own nudges
6. **Analytics**: Track nudge engagement and effectiveness

## Dependencies Added

### Backend
- No new dependencies (uses existing MongoDB, FastAPI)

### Frontend
- `flutter_local_notifications: ^17.2.3`
- `timezone: ^0.9.4`

## Notes

- Notifications work even when app is closed
- Android 13+ requires runtime notification permission
- iOS requires user consent for notifications
- Nudges are cancelled if user logs a new mood before 10 minutes
- Offline fallback ensures nudges work without backend connection
