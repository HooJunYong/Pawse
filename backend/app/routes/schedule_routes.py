from fastapi import APIRouter, Query
from typing import Optional
from ..models.schemas import (
    SetAvailabilityRequest, AvailabilityResponse, TherapistScheduleResponse, 
    TherapistDashboardResponse, EditAvailabilityRequest
)
from ..services.schedule_service import (
    set_therapist_availability,
    get_therapist_availability,
    delete_availability_slot,
    get_therapist_schedule,
    get_today_sessions,
    get_therapist_dashboard,
    edit_availability_slot,
    get_therapist_schedule_for_month,
)

router = APIRouter()

@router.post("/therapist/availability")
def set_availability(request: SetAvailabilityRequest):
    """Set therapist availability for a specific day"""
    return set_therapist_availability(request)

@router.get("/therapist/availability/{user_id}", response_model=list[AvailabilityResponse])
def get_availability(
    user_id: str,
    day_of_week: Optional[str] = Query(None, description="Filter by day of week (monday-sunday)")
):
    """Get therapist availability"""
    return get_therapist_availability(user_id, day_of_week)

@router.delete("/therapist/availability/{availability_id}")
def delete_availability(availability_id: str, user_id: str = Query(...)):
    """Delete a specific availability slot"""
    return delete_availability_slot(availability_id, user_id)

@router.get("/therapist/schedule/{user_id}", response_model=TherapistScheduleResponse)
def get_schedule(user_id: str, date: str = Query(..., description="Date in YYYY-MM-DD format")):
    """Get therapist schedule for a specific date"""
    return get_therapist_schedule(user_id, date)

@router.get("/therapist/schedule/{user_id}/month")
def get_schedule_for_month(user_id: str, year: int, month: int):
    """Get all scheduled dates for a therapist in a given month"""
    return get_therapist_schedule_for_month(user_id, year, month)

@router.get("/therapist/today-sessions/{user_id}")
def get_sessions_today(user_id: str):
    """Get therapist's sessions for today"""
    return {
        "sessions": get_today_sessions(user_id)
    }

@router.get("/therapist/dashboard/{user_id}", response_model=TherapistDashboardResponse)
def get_dashboard(user_id: str):
    """Get therapist dashboard data including today's appointments"""
    return get_therapist_dashboard(user_id)

@router.put("/therapist/availability/{availability_id}")
def edit_availability(availability_id: str, payload: EditAvailabilityRequest, user_id: str = Query(...)):
    """Edit an existing availability slot"""
    return edit_availability_slot(availability_id, user_id, payload)
