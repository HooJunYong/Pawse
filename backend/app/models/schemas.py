from pydantic import BaseModel, EmailStr  # type: ignore
from typing import Optional
from datetime import datetime

# Request Models
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    phone_number: str | None = None
    user_type: str | None = "users"
    first_name: str
    last_name: str
    gender: str | None = None
    date_of_birth: str | None = None
    home_address: str | None = None
    city: str | None = None
    state: str | None = None
    zip: int | None = None
    profile_picture_url: str | None = None

class UpdateProfileRequest(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    home_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip: Optional[int] = None
    avatar_base64: Optional[str] = None
    avatar_url: Optional[str] = None
    delete_avatar: Optional[bool] = False

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class TherapistApplicationRequest(BaseModel):
    user_id: str
    first_name: str
    last_name: str
    email: EmailStr
    contact_number: str
    license_number: str
    bio: str
    office_name: Optional[str] = None
    office_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip: Optional[int] = None
    specializations: list[str]
    languages: list[str]
    hourly_rate: float
    profile_picture: Optional[str] = None  # base64 encoded

class UpdateTherapistProfileRequest(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    contact_number: Optional[str] = None
    bio: Optional[str] = None
    office_name: Optional[str] = None
    office_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip: Optional[int] = None
    hourly_rate: Optional[float] = None
    profile_picture_base64: Optional[str] = None
    profile_picture_url: Optional[str] = None
    delete_profile_picture: Optional[bool] = False

# Response Models
class LoginResponse(BaseModel):
    user_id: str
    email: EmailStr
    user_type: str
    last_login: datetime

class SignupResponse(BaseModel):
    user_id: str
    email: EmailStr
    created_at: datetime
    first_name: str
    last_name: str

class ProfileResponse(BaseModel):
    user_id: str
    full_name: str
    avatar_url: Optional[str] = None
    avatar_base64: Optional[str] = None
    initials: str

class UpdateProfileResponse(BaseModel):
    success: bool
    message: str
    user_id: str

class LoginHistoryItem(BaseModel):
    login_at: datetime

class LoginHistoryResponse(BaseModel):
    user_id: str
    history: list[LoginHistoryItem]

class TherapistProfileResponse(BaseModel):
    user_id: str
    license_number: str
    first_name: str
    last_name: str
    email: str
    contact_number: Optional[str] = None
    bio: str
    office_name: Optional[str] = None
    office_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip: Optional[int] = None
    specializations: list[str]
    languages_spoken: list[str]
    hourly_rate: float
    profile_picture_url: Optional[str] = None
    verification_status: str
    verified_at: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class TherapistApplicationResponse(BaseModel):
    success: bool
    message: str
    application_id: str

# Therapist Availability Schemas
class AvailabilitySlot(BaseModel):
    start_time: str  # Format: "HH:MM AM/PM"
    end_time: str    # Format: "HH:MM AM/PM"

class SetAvailabilityRequest(BaseModel):
    user_id: str
    day_of_week: str  # monday, tuesday, etc.
    slots: list[AvailabilitySlot]
    is_available: bool = True
    availability_date: Optional[str] = None  # Specific date (YYYY-MM-DD) or None for recurring

class AvailabilityResponse(BaseModel):
    availability_id: str
    user_id: str
    day_of_week: str
    start_time: str
    end_time: str
    is_available: bool
    availability_date: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class TherapistScheduleResponse(BaseModel):
    date: str
    sessions: list[dict]
    availability_slots: list[dict] = []  # Add availability slots to schedule

# Therapy Session Schemas
class SessionResponse(BaseModel):
    session_id: str
    user_id: str
    therapist_user_id: str
    scheduled_at: datetime
    duration_minutes: int
    session_fee: float
    session_type: str
    session_status: str
    session_notes: Optional[str] = None
    user_rating: Optional[int] = None
    user_feedback: Optional[str] = None
    created_at: datetime
    client_name: Optional[str] = None
    client_email: Optional[str] = None

# Dashboard Schemas
class DashboardAppointment(BaseModel):
    time: str  # Format: "2:00"
    period: str  # Format: "PM" or "AM"
    name: str  # Client name
    session: str  # Session description

class UpcomingAvailability(BaseModel):
    date: str  # YYYY-MM-DD
    day_name: str  # Monday, Tuesday, etc.
    slots: list[dict]  # List of {availability_id, start_time, end_time}

class TherapistDashboardResponse(BaseModel):
    therapist_name: str
    today_appointments: list[DashboardAppointment]
    total_today: int
    upcoming_availability: list[UpcomingAvailability] = []  # Next 5 days with availability

class EditAvailabilityRequest(BaseModel):
    start_time: str
    end_time: str

