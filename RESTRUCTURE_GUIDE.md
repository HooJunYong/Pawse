# Project Restructuring Guide - N-Tier Architecture

## Overview
This guide explains how to restructure the Pawse project to follow N-Tier architecture principles.

---

## Backend Structure (Python/FastAPI)

### Current Structure:
```
backend/app/
├── changepassword.py
├── db.py
├── editprofile.py
├── login.py
├── main.py
├── profile.py
├── signup.py
└── timezone.py
```

### New N-Tier Structure:
```
backend/app/
├── main.py                 # Entry point (unchanged)
├── routes/                 # Presentation Layer - API endpoints
│   ├── __init__.py
│   ├── auth_routes.py     # Login, signup
│   ├── profile_routes.py  # Profile, edit profile
│   └── password_routes.py # Change password, reset password
├── services/              # Business Logic Layer
│   ├── __init__.py
│   ├── auth_service.py    # Authentication logic
│   ├── profile_service.py # Profile business logic
│   └── password_service.py# Password management logic
├── models/                # Data Access Layer - MongoDB schemas
│   ├── __init__.py
│   ├── database.py        # DB connection (from db.py)
│   ├── user_model.py      # User schema/operations
│   └── profile_model.py   # Profile schema/operations
└── config/                # Core/Config
    ├── __init__.py
    ├── settings.py        # App settings, env variables
    └── timezone.py        # Timezone utilities (from timezone.py)
```

### File Migration Steps:

#### Step 1: Move to `routes/` (Presentation Layer)
1. Create `routes/auth_routes.py`:
   - Move endpoints from `login.py` and `signup.py`
   - Keep only route definitions, move logic to services

2. Create `routes/profile_routes.py`:
   - Move endpoints from `profile.py` and `editprofile.py`

3. Create `routes/password_routes.py`:
   - Move endpoints from `changepassword.py`

#### Step 2: Move to `services/` (Business Logic Layer)
1. Create `services/auth_service.py`:
   - Move `verify_password()`, `hash_password()` from login.py/signup.py
   - Move authentication logic

2. Create `services/profile_service.py`:
   - Move `_make_initials()`, `_compose_profile_doc()` from profile.py
   - Move profile update logic from editprofile.py

3. Create `services/password_service.py`:
   - Move password verification and hashing logic from changepassword.py

#### Step 3: Move to `models/` (Data Access Layer)
1. Rename `db.py` → `models/database.py`:
   - Keep MongoDB connection logic

2. Create `models/user_model.py`:
   - Define user schema
   - Create functions for user CRUD operations

3. Create `models/profile_model.py`:
   - Define profile schema
   - Create functions for profile CRUD operations

#### Step 4: Move to `config/`
1. Move `timezone.py` → `config/timezone.py`

2. Create `config/settings.py`:
   - Move environment variables
   - Add configuration constants

#### Step 5: Update `main.py`
Update imports to use new structure:
```python
from app.routes import auth_routes, profile_routes, password_routes
from app.config.settings import get_settings
```

---

## Frontend Structure (Flutter/Dart)

### Current Structure:
```
frontend/lib/
├── changepassword.dart
├── editprofile.dart
├── error_boundary.dart
├── forgetpassword.dart
├── login.dart
├── main.dart
├── otp.dart
├── profile.dart
└── signup.dart
```

### New N-Tier Structure:
```
frontend/lib/
├── main.dart              # Entry point (unchanged)
├── screens/               # UI/Presentation Layer
│   ├── auth/
│   │   ├── login_screen.dart      (from login.dart)
│   │   ├── signup_screen.dart     (from signup.dart)
│   │   ├── forgot_password_screen.dart (from forgetpassword.dart)
│   │   └── otp_screen.dart        (from otp.dart)
│   ├── profile/
│   │   ├── profile_screen.dart    (from profile.dart)
│   │   ├── edit_profile_screen.dart (from editprofile.dart)
│   │   └── change_password_screen.dart (from changepassword.dart)
├── widgets/               # Reusable UI components
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── avatar_circle.dart
│   └── error_boundary.dart        (from error_boundary.dart)
├── services/              # Business Logic/API calls
│   ├── api_service.dart           # Base API service
│   ├── auth_service.dart          # Auth API calls
│   ├── profile_service.dart       # Profile API calls
│   └── password_service.dart      # Password API calls
├── models/                # Data models
│   ├── user_model.dart
│   ├── profile_model.dart
│   └── login_response.dart
└── utils/                 # Core/Config
    ├── constants.dart             # Colors, API URLs
    ├── validators.dart            # Form validators
    └── helpers.dart               # Helper functions
```

### File Migration Steps:

#### Step 1: Move to `screens/` (UI Layer)
1. Rename and move authentication screens:
   ```
   login.dart → screens/auth/login_screen.dart
   signup.dart → screens/auth/signup_screen.dart
   forgetpassword.dart → screens/auth/forgot_password_screen.dart
   otp.dart → screens/auth/otp_screen.dart
   ```

2. Rename and move profile screens:
   ```
   profile.dart → screens/profile/profile_screen.dart
   editprofile.dart → screens/profile/edit_profile_screen.dart
   changepassword.dart → screens/profile/change_password_screen.dart
   ```

#### Step 2: Extract to `widgets/` (Reusable Components)
Extract common widgets from your screens:

1. `widgets/custom_button.dart` - Reusable button with app styling
2. `widgets/custom_text_field.dart` - Reusable text field with validation
3. `widgets/avatar_circle.dart` - Avatar display logic
4. Move `error_boundary.dart` → `widgets/error_boundary.dart`

#### Step 3: Create `services/` (Business Logic)
Extract API calls from screens:

1. `services/api_service.dart`:
```dart
class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  
  static Future<http.Response> get(String endpoint) async {
    return await http.get(Uri.parse('$baseUrl$endpoint'));
  }
  
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}
```

2. `services/auth_service.dart` - Login, signup logic
3. `services/profile_service.dart` - Profile CRUD logic
4. `services/password_service.dart` - Password change logic

#### Step 4: Create `models/` (Data Models)
1. `models/user_model.dart`:
```dart
class User {
  final String userId;
  final String email;
  final String fullName;
  
  User({required this.userId, required this.email, required this.fullName});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      email: json['email'],
      fullName: json['full_name'],
    );
  }
}
```

2. `models/profile_model.dart` - Profile data model
3. `models/login_response.dart` - API response models

#### Step 5: Create `utils/` (Helpers)
1. `utils/constants.dart`:
```dart
class AppColors {
  static const beige = Color(0xFFF7F4F2);
  static const darkBrown = Color(0xFF422006);
  static const orange = Color(0xFFF97316);
}

class ApiEndpoints {
  static const login = '/login';
  static const signup = '/signup';
  static const profile = '/profile';
}
```

2. `utils/validators.dart` - Form validation logic
3. `utils/helpers.dart` - Helper functions

---

## Migration Commands

### Backend
```bash
# Create __init__.py files
cd backend/app
echo. > routes/__init__.py
echo. > services/__init__.py
echo. > models/__init__.py
echo. > config/__init__.py

# You'll need to manually split and move code from existing files
# Then delete old files after confirming everything works
```

### Frontend
```bash
# Move files to new structure (do this manually or use git mv to preserve history)
cd frontend/lib

# Example:
git mv login.dart screens/auth/login_screen.dart
git mv profile.dart screens/profile/profile_screen.dart
# ... repeat for all files
```

---

## Benefits of This Structure

### Backend:
- **Routes**: Pure API endpoints, no business logic
- **Services**: Reusable business logic, testable
- **Models**: Single source of truth for data access
- **Config**: Centralized settings

### Frontend:
- **Screens**: Focus only on UI rendering
- **Widgets**: Reusable components across screens
- **Services**: Testable API logic separate from UI
- **Models**: Type-safe data structures
- **Utils**: Shared constants and helpers

---

## Next Steps

1. Create empty files in new structure
2. Copy/move code from old files to new structure
3. Update imports throughout the project
4. Test each feature after migration
5. Delete old files once confirmed working
6. Update documentation

---

## Important Notes

- Do NOT delete old files until new structure is working
- Update imports gradually
- Test after each major migration
- Keep a backup or use git branches
- The old files remain in place until you manually move the code

