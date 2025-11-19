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

# Response Models
class LoginResponse(BaseModel):
    user_id: str
    email: EmailStr
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
    created_at: datetime
    updated_at: datetime

class TherapistApplicationResponse(BaseModel):
    success: bool
    message: str
    application_id: str
