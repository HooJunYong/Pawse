# Journal Feature Implementation

## Overview
Implemented a complete journaling feature with random mental health prompts, data persistence, and past entries viewing.

## Backend Implementation

### Database Schema
**Table:** `journal_entry`
- `entry_id` (string, PK): Unique identifier (auto-generated from MongoDB _id)
- `user_id` (string, FK): References USER.user_id
- `title` (string, max 255): Journal title
- `content` (text): Journal content
- `prompt_type` (enum): reflection, gratitude, expressive
- `emotional_tags` (json): Array of emotion-related tags
- `created_at` (datetime): Creation timestamp
- `updated_at` (datetime): Last update timestamp

### Files Created

1. **backend/app/models/journal_schemas.py**
   - Pydantic models for request/response validation
   - `JournalEntryCreate`: Creating new entries
   - `JournalEntryUpdate`: Updating existing entries
   - `JournalEntryResponse`: API response format
   - `PromptResponse`: Random prompt response
   - `PromptType`: Enum for prompt types

2. **backend/app/services/journal_service.py**
   - `JournalService` class with MongoDB operations
   - 15 curated mental health prompts (5 per type)
   - Methods:
     - `get_random_prompt()`: Returns random prompt with type
     - `create_entry()`: Save new journal entry
     - `get_entry()`: Get specific entry by ID
     - `get_user_entries()`: List all user entries (with pagination)
     - `update_entry()`: Update existing entry
     - `delete_entry()`: Delete entry

3. **backend/app/routes/journal_routes.py**
   - REST API endpoints:
     - `GET /journal/prompt`: Get random daily prompt
     - `POST /journal/entry/{user_id}`: Create new entry
     - `GET /journal/entries/{user_id}`: Get all user entries
     - `GET /journal/entry/{entry_id}/{user_id}`: Get specific entry
     - `PUT /journal/entry/{entry_id}/{user_id}`: Update entry
     - `DELETE /journal/entry/{entry_id}/{user_id}`: Delete entry

4. **backend/app/main.py** (updated)
   - Registered journal router with FastAPI app

## Frontend Implementation

### Files Created

1. **frontend/lib/models/journal_model.dart**
   - `JournalPrompt`: Model for daily prompts
   - `JournalEntry`: Model for saved entries
   - `CreateJournalEntry`: Model for creating new entries
   - JSON serialization/deserialization methods

2. **frontend/lib/services/journal_service.dart**
   - `JournalService` class for API communication
   - Methods matching backend endpoints
   - Error handling for network requests

3. **frontend/lib/screens/wellness/journaling_screen.dart**
   - Complete UI matching the provided design
   - Features:
     - Display random daily prompt
     - Large text area for journaling
     - Save entry button with loading state
     - Past entries section showing last 10 entries
     - Date formatting for entries
     - Prompt type badges
     - Content preview (150 chars) for past entries

### Files Updated

1. **frontend/lib/screens/wellness/wellness_screen.dart**
   - Added import for `JournalingScreen`
   - Updated "Start Now" button to navigate to journaling
   - Updated Journaling activity card to navigate to journaling

## Features

### Mental Health Prompts
- **Gratitude prompts**: Focus on appreciation and positive aspects
- **Reflection prompts**: Encourage self-assessment and learning
- **Expressive prompts**: Allow emotional expression and creativity

### User Experience
- Clean, minimalist design matching app theme
- Random prompt on each visit to keep journaling fresh
- Easy-to-use text input with no character limit
- Immediate feedback on save success/failure
- Past entries for reflection and progress tracking
- Responsive to different screen sizes (375px width container)

### Data Management
- Secure user-specific entries
- Automatic timestamp tracking
- Soft pagination for large entry lists
- Optional emotional tagging for future analytics

## Color Scheme
- Background: `#F7F4F2` (warm beige)
- Primary text: `#42200A` (dark brown)
- Secondary text: `#5C4033` (medium brown)
- Accent: `#F97316` (orange)
- Success: `#22C55E` (green)
- Card background: White with subtle shadow

## Next Steps (Optional Enhancements)
1. Add emotional tag selection UI
2. Implement entry editing functionality
3. Add search/filter for past entries
4. Create statistics/insights dashboard
5. Add export functionality (PDF/text)
6. Implement streak tracking for daily journaling
7. Add prompts customization by user preferences
