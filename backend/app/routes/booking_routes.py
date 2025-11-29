from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from ..models.booking_schemas import (
    TherapistAvailabilityResponse,
    BookingRequest,
    BookingResponse,
    BookingListResponse,
    UpcomingSessionResponse,
    CancelBookingRequest,
    CancelBookingResponse,
    UpdateSessionStatusRequest,
    UpdateSessionStatusResponse,
    PendingRatingResponse,
    SubmitSessionRatingRequest,
    SubmitSessionRatingResponse,
)
from ..services import booking_service

router = APIRouter(prefix="/booking", tags=["booking"])


@router.get("/availability/{therapist_user_id}", response_model=TherapistAvailabilityResponse)
def get_therapist_availability(
    therapist_user_id: str,
    date: str = Query(..., description="Date in YYYY-MM-DD format")
):
    """
    Get available time slots for a therapist on a specific date
    Shows therapist's set availability times with pricing
    """
    try:
        availability = booking_service.get_therapist_availability_for_booking(
            therapist_user_id=therapist_user_id,
            date_str=date
        )
        return availability
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get availability: {str(e)}")


@router.post("/create", response_model=BookingResponse)
def create_booking(request: BookingRequest):
    """
    Create a new booking for a therapy session
    Validates availability and creates confirmed booking
    """
    try:
        booking = booking_service.create_booking(request)
        return booking
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create booking: {str(e)}")


@router.get("/client/{client_user_id}", response_model=BookingListResponse)
def get_client_bookings(client_user_id: str):
    """
    Get all bookings for a client
    Returns list sorted by scheduled date (newest first)
    """
    try:
        bookings = booking_service.get_client_bookings(client_user_id)
        return BookingListResponse(bookings=bookings, total=len(bookings))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get bookings: {str(e)}")


@router.get("/therapist/{therapist_user_id}", response_model=BookingListResponse)
def get_therapist_bookings(therapist_user_id: str):
    """
    Get all bookings for a therapist
    Returns list sorted by scheduled date (newest first)
    """
    try:
        bookings = booking_service.get_therapist_bookings(therapist_user_id)
        return BookingListResponse(bookings=bookings, total=len(bookings))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get bookings: {str(e)}")


@router.get("/client/{client_user_id}/upcoming", response_model=Optional[UpcomingSessionResponse])
def get_client_upcoming_session(client_user_id: str):
    """Get the next upcoming therapy session for the specified client"""

    try:
        return booking_service.get_upcoming_client_session(client_user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get upcoming session: {str(e)}")


@router.post("/cancel", response_model=CancelBookingResponse)
def cancel_booking(request: CancelBookingRequest):
    """Cancel a scheduled booking for a client"""

    try:
        return booking_service.cancel_client_booking(request)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to cancel booking: {str(e)}")


@router.post("/session/status", response_model=UpdateSessionStatusResponse)
def update_session_status(request: UpdateSessionStatusRequest):
    """Update the status of a therapy session (e.g., completed, no_show)"""

    try:
        return booking_service.update_session_status(request)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update session status: {str(e)}")


@router.get("/client/{client_user_id}/pending-rating", response_model=PendingRatingResponse)
def get_pending_rating(client_user_id: str):
    """Return the next completed session awaiting a client rating."""

    try:
        return booking_service.get_pending_rating(client_user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load pending rating: {str(e)}")


@router.post("/session/rate", response_model=SubmitSessionRatingResponse)
def submit_session_rating(request: SubmitSessionRatingRequest):
    """Persist a client rating for a completed session."""

    try:
        return booking_service.submit_session_rating(request)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit rating: {str(e)}")
