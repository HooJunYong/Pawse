# Therapist Dashboard API Documentation

## New Endpoint

### GET `/therapist/dashboard/{user_id}`

Gets the therapist's dashboard data including their name and today's scheduled appointments.

#### Parameters
- `user_id` (path parameter): The therapist's user ID

#### Response Schema
```json
{
  "therapist_name": "Dr. FirstName",
  "today_appointments": [
    {
      "time": "2:00",
      "period": "PM",
      "name": "John D.",
      "session": "Initial Consultation (Online)"
    }
  ],
  "total_today": 2
}
```

#### Response Fields
- `therapist_name` (string): The therapist's name in format "Dr. FirstName"
- `today_appointments` (array): List of today's scheduled/confirmed appointments
  - `time` (string): Appointment time in format "H:MM" (e.g., "2:00", "10:30")
  - `period` (string): AM or PM
  - `name` (string): Client name formatted as "FirstName LastInitial." (e.g., "John D.")
  - `session` (string): Session description with type and format (e.g., "Initial Consultation (Online)")
- `total_today` (integer): Total count of appointments for today

#### Business Rules
1. Only returns appointments with status "scheduled" or "confirmed"
2. Only returns sessions for the current day (00:00:00 to 23:59:59)
3. Appointments are sorted by scheduled time (earliest first)
4. Requires therapist to have "approved" verification status
5. Client names are abbreviated to protect privacy (FirstName LastInitial.)

#### Error Responses
- **404 Not Found**: If no approved therapist profile exists for the user_id
  ```json
  {
    "detail": "Approved therapist profile not found"
  }
  ```

#### Example Request
```bash
GET /therapist/dashboard/507f1f77bcf86cd799439011
```

#### Example Response
```json
{
  "therapist_name": "Dr. Alya",
  "today_appointments": [
    {
      "time": "2:00",
      "period": "PM",
      "name": "Sarah K.",
      "session": "Follow-up Session (Online)"
    },
    {
      "time": "4:00",
      "period": "PM",
      "name": "Ahmad F.",
      "session": "Initial Consultation (Online)"
    }
  ],
  "total_today": 2
}
```

## Database Collections Used

### therapist_profile
- Used to get therapist's first name and verify approval status
- Fields: `user_id`, `first_name`, `verification_status`

### therapy_session
- Used to get today's scheduled sessions
- Filtered by: `therapist_user_id`, `scheduled_at` (today), `session_status` (scheduled/confirmed)
- Fields: `user_id`, `scheduled_at`, `session_type`

### user_profile
- Used to get client names for each session
- Fields: `user_id`, `first_name`, `last_name`

## Frontend Integration

The Flutter dashboard screen now:
1. Calls this endpoint on initialization
2. Displays loading spinner while fetching data
3. Shows therapist name in header
4. Displays appointments in card format
5. Shows empty state when no appointments exist
6. Handles errors with snackbar notifications

### Frontend Usage
```dart
final response = await http.get(
  Uri.parse('$apiUrl/therapist/dashboard/$userId'),
);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  setState(() {
    _therapistName = data['therapist_name'];
    _todaysAppointments = List<Map<String, dynamic>>.from(
      data['today_appointments'] ?? []
    );
  });
}
```

## Related Endpoints

- `GET /therapist/schedule/{user_id}?date=YYYY-MM-DD` - Get full schedule for specific date
- `GET /therapist/today-sessions/{user_id}` - Get detailed session data for today
- `POST /therapist/availability` - Set therapist availability

## Testing

To test with sample data, you'll need:
1. An approved therapist profile in `therapist_profile` collection
2. One or more therapy sessions in `therapy_session` collection with:
   - `therapist_user_id` matching your therapist
   - `scheduled_at` set to today's date
   - `session_status` as "scheduled" or "confirmed"
3. Corresponding user profiles in `user_profile` collection for client names
