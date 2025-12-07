# Therapist Schedule Management - Feature Update

## Overview
Enhanced the therapist dashboard and schedule management system to support date-specific availability scheduling, upcoming schedule visibility, and availability editing/deletion.

## New Features

### 1. Dashboard Enhancements

#### Welcome Message
- Dashboard displays therapist's name: "Welcome back, Dr. FirstName"
- Loads dynamically from `therapist_profile` collection

#### Upcoming Scheduled Days Section
- Shows next 5 days with scheduled availability (after today)
- Displays date, day name, and time slots
- Each time slot has edit and delete buttons
- Only shows days that have availability scheduled

### 2. Date-Specific Availability

#### Database Schema Changes
- Added `availability_date` field to `therapist_availability` collection
- Supports two types of availability:
  - **Recurring**: `availability_date = null` - applies to all matching weekdays
  - **Date-specific**: `availability_date = "YYYY-MM-DD"` - applies only to that specific date

#### Set Availability Screen
- When setting availability for a specific day, it saves the exact date
- "Apply to all {day}s" checkbox allows recurring availability (not yet fully implemented)
- Automatically saves the selected date when setting availability

### 3. Edit/Delete Availability

#### Edit Functionality
- Click edit icon on any availability slot in dashboard
- Modal dialog allows changing start and end times
- Updates via PUT `/therapist/availability/{availability_id}`
- Reloads dashboard after successful edit

#### Delete Functionality
- Click delete icon on any availability slot
- Confirmation dialog before deletion
- Removes via DELETE `/therapist/availability/{availability_id}`
- Reloads dashboard after successful deletion

### 4. Manage Schedule Screen Enhancements

#### Calendar Day View
- Clicking a day shows both:
  - **Sessions**: Booked therapy sessions with clients
  - **Available Time Slots**: Open availability for that day
- Availability slots shown with orange background and "Available" badge
- Distinguishes between booked sessions (white) and available slots (orange tint)

#### Availability Query Logic
- For each date, checks for:
  1. Specific date availability (`availability_date` matches)
  2. Recurring availability (matching `day_of_week` with `availability_date = null`)
- Priority given to date-specific over recurring

## Backend API Changes

### New/Updated Endpoints

#### 1. Updated: POST `/therapist/availability`
```json
{
  "user_id": "string",
  "day_of_week": "monday",
  "slots": [
    {
      "start_time": "09:00 AM",
      "end_time": "12:00 PM"
    }
  ],
  "is_available": true,
  "availability_date": "2025-11-22"  // NEW: Optional specific date
}
```

#### 2. Updated: GET `/therapist/schedule/{user_id}?date=YYYY-MM-DD`
Response now includes availability slots:
```json
{
  "date": "2025-11-22",
  "sessions": [...],
  "availability_slots": [  // NEW
    {
      "availability_id": "uuid",
      "start_time": "09:00 AM",
      "end_time": "12:00 PM",
      "day_of_week": "friday",
      "availability_date": "2025-11-22"
    }
  ]
}
```

#### 3. Updated: GET `/therapist/dashboard/{user_id}`
Response now includes upcoming availability:
```json
{
  "therapist_name": "Dr. FirstName",
  "today_appointments": [...],
  "total_today": 2,
  "upcoming_availability": [  // NEW
    {
      "date": "2025-11-22",
      "day_name": "Friday",
      "slots": [
        {
          "availability_id": "uuid",
          "start_time": "09:00 AM",
          "end_time": "12:00 PM"
        }
      ]
    }
  ]
}
```

#### 4. NEW: PUT `/therapist/availability/{availability_id}?user_id={user_id}`
Edit existing availability slot:
```json
{
  "start_time": "10:00 AM",
  "end_time": "01:00 PM"
}
```

### Backend Service Functions

#### New Functions in `schedule_service.py`:

1. **`get_upcoming_availability(user_id, days=5)`**
   - Returns next N days with scheduled availability
   - Queries both date-specific and recurring availability
   - Only includes days that have at least one slot

2. **`edit_availability_slot(availability_id, user_id, payload)`**
   - Updates start_time and end_time for a specific slot
   - Validates times and ensures start < end
   - Updates `updated_at` timestamp

#### Updated Functions:

1. **`set_therapist_availability(payload)`**
   - Now handles optional `availability_date` parameter
   - Deletes existing slots matching both day_of_week AND date
   - Stores `availability_date` in database

2. **`get_therapist_schedule(user_id, date)`**
   - Now returns availability_slots in addition to sessions
   - Uses `$or` query to find both date-specific and recurring availability

3. **`get_therapist_dashboard(user_id)`**
   - Calls `get_upcoming_availability()` for next 5 days
   - Includes upcoming_availability in response

## Database Collection Structure

### therapist_availability
```javascript
{
  "availability_id": "uuid",
  "user_id": "string",
  "day_of_week": "monday|tuesday|...",
  "start_time": "HH:MM AM/PM",
  "end_time": "HH:MM AM/PM",
  "is_available": true,
  "availability_date": "YYYY-MM-DD" | null,  // NEW FIELD
  "created_at": datetime,
  "updated_at": datetime
}
```

### Query Patterns

**Get availability for specific date:**
```javascript
db.therapist_availability.find({
  "$or": [
    {"user_id": "...", "availability_date": "2025-11-22"},  // Specific
    {"user_id": "...", "day_of_week": "friday", "availability_date": null}  // Recurring
  ]
})
```

**Get upcoming availability (next 5 days):**
```javascript
// For each day, check if has specific OR recurring availability
// Only return days with at least one slot
```

## Frontend Components

### TherapistDashboard Updates

#### New State Variables:
- `_upcomingAvailability`: List of upcoming scheduled days

#### New Methods:
- `_buildAvailabilityCard()`: Renders upcoming availability card
- `_editAvailabilitySlot()`: Shows edit dialog and updates slot
- `_deleteAvailabilitySlot()`: Shows confirmation and deletes slot

#### UI Changes:
- Added "Upcoming Scheduled Days" section below Quick Actions
- Each day card shows date, day name, and time slots with edit/delete icons

### ManageScheduleScreen Updates

#### New State Variables:
- `_availabilitySlots`: List of availability slots for selected date

#### UI Changes:
- Added "Available Time Slots" section after sessions
- Orange-tinted cards for availability (vs white for sessions)
- Shows "Available" badge on availability slots
- Automatically reloads schedule after setting availability

### SetAvailabilityScreen Updates

#### Changes:
- Now passes `availability_date` to backend API
- Uses `DateFormat` to format date as YYYY-MM-DD
- Checkbox logic: if unchecked, saves specific date; if checked, saves as recurring (null)

## User Workflow

### Setting Availability for Specific Day:
1. Therapist navigates to Manage Schedule
2. Selects a specific date from calendar
3. Clicks "Set Availability"
4. Adds time slots (e.g., 9:00 AM - 12:00 PM)
5. Saves → availability is recorded for that specific date
6. Returns to calendar → sees availability slots displayed

### Viewing Upcoming Schedule:
1. Therapist opens dashboard
2. Sees "Today's Appointments" (booked sessions)
3. Sees "Upcoming Scheduled Days" (next 5 days with availability)
4. Each day shows all time slots available

### Editing Availability:
1. Therapist sees availability slot in upcoming schedule
2. Clicks edit icon
3. Modifies start/end time in modal
4. Saves → availability updated
5. Dashboard refreshes with new times

### Deleting Availability:
1. Therapist sees availability slot in upcoming schedule
2. Clicks delete icon
3. Confirms deletion
4. Slot removed from database
5. Dashboard refreshes

## Technical Notes

### Time Format
- All times use "HH:MM AM/PM" format (e.g., "09:00 AM", "02:30 PM")
- Consistent across frontend and backend

### Date Format
- All dates use "YYYY-MM-DD" format for storage and API communication
- Frontend displays as "Friday, November 22" for user readability

### Availability Priority
- Date-specific availability takes precedence over recurring
- If both exist for a date, both are returned and displayed

### Error Handling
- All API calls wrapped in try-catch
- User-friendly error messages via SnackBar
- Loading states during API operations

## Testing Checklist

- [ ] Dashboard shows therapist name correctly
- [ ] Today's appointments load from database
- [ ] Upcoming availability shows next 5 days
- [ ] Edit availability updates time slots
- [ ] Delete availability removes slots
- [ ] Setting availability saves specific date
- [ ] Calendar shows both sessions and availability
- [ ] Recurring availability (checkbox) works correctly
- [ ] Multiple time slots per day handled correctly
- [ ] Error handling displays appropriate messages

## Future Enhancements

1. **Recurring Availability**: Fully implement "Apply to all {day}s" checkbox
2. **Bulk Edit**: Allow editing multiple slots at once
3. **Availability Templates**: Save common availability patterns
4. **Visual Calendar**: Add color coding for booked vs available slots
5. **Conflict Detection**: Warn if setting availability conflicts with existing sessions
6. **Mobile Responsive**: Optimize for smaller screens

## Booking Flow Status

- [x] Backend booking APIs for availability, creation, and upcoming sessions
- [x] Flutter booking session screen with themed calendar and slot picker
- [x] Booking success confirmation screen linked back to homepage
- [ ] Automated end-to-end booking flow tests
