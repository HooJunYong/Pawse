from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel


class SessionType(str, Enum):
    """Supported therapy session delivery types"""

    chat = "chat"
    in_person = "in_person"


class SessionStatus(str, Enum):
    """Lifecycle states for therapy sessions"""

    scheduled = "scheduled"
    completed = "completed"
    cancelled = "cancelled"
    no_show = "no_show"


class AvailableTimeSlot(BaseModel):
    """Available time slot for booking"""
    slot_id: str
    start_time: str  # Format: "9:00 AM"
    end_time: str    # Format: "10:00 AM"
    is_available: bool
    date: str        # Format: "YYYY-MM-DD"


class TherapistAvailabilityResponse(BaseModel):
    """Therapist availability for a specific date"""
    therapist_id: str
    therapist_name: str
    date: str
    available_slots: list[AvailableTimeSlot]
    price: float
    center_name: Optional[str] = None


class BookingRequest(BaseModel):
    """Request to create a booking"""
    client_user_id: str
    therapist_user_id: str
    date: str           # Format: "YYYY-MM-DD"
    start_time: str     # Format: "9:00 AM"
    duration_minutes: int = 50
    notes: Optional[str] = None
    session_type: SessionType = SessionType.in_person


class BookingResponse(BaseModel):
    """Response after creating a booking"""
    booking_id: str
    session_id: str
    client_user_id: str
    therapist_user_id: str
    therapist_name: str
    scheduled_at: str   # ISO format datetime
    start_time: str     # Format: "9:00 AM"
    end_time: str       # Format: "10:00 AM"
    duration_minutes: int
    price: float
    session_fee: float
    status: str
    session_status: SessionStatus
    session_type: SessionType
    created_at: str
    message: str
    center_name: Optional[str] = None
    center_address: Optional[str] = None


class UpcomingSessionResponse(BaseModel):
    """Next upcoming therapy session for a client"""

    session_id: str
    therapist_user_id: str
    therapist_name: str
    scheduled_at: datetime
    start_time: str
    end_time: str
    duration_minutes: int
    session_fee: float
    session_status: SessionStatus
    session_type: SessionType
    center_name: Optional[str] = None
    center_address: Optional[str] = None


class CancelBookingRequest(BaseModel):
    """Request model to cancel a scheduled booking"""

    session_id: str
    client_user_id: str
    reason: Optional[str] = None


class CancelBookingResponse(BaseModel):
    """Response returned after cancelling a booking"""

    success: bool
    message: str


class BookingListResponse(BaseModel):
    """List of bookings"""
    bookings: list[BookingResponse]
    total: int
