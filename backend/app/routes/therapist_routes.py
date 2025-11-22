from fastapi import APIRouter, HTTPException, Body
from typing import Optional
from ..models.schemas import TherapistApplicationRequest, TherapistApplicationResponse, TherapistProfileResponse
from ..services.therapist_service import (
    submit_therapist_application,
    get_therapist_profile,
    get_all_verified_therapists,
    get_pending_therapists,
    update_therapist_verification_status,
    get_therapist_dashboard_data
)

router = APIRouter()

@router.post("/therapist/application", response_model=TherapistApplicationResponse)
def create_therapist_application(request: TherapistApplicationRequest):
    """Submit a new therapist application"""
    return submit_therapist_application(request)

@router.get("/therapist/profile/{user_id}", response_model=TherapistProfileResponse)
def get_therapist(user_id: str):
    """Get therapist profile by user_id"""
    return get_therapist_profile(user_id)

@router.get("/therapist/pending", response_model=list[TherapistProfileResponse])
def get_pending_applications():
    """Get all pending therapist applications (admin only)"""
    return get_pending_therapists()

@router.get("/therapist/verified", response_model=list[TherapistProfileResponse])
def get_verified_therapists():
    """Get all verified therapists"""
    return get_all_verified_therapists()

@router.put("/therapist/verify/{user_id}")
def verify_therapist(
    user_id: str, 
    status: str,
    body: Optional[dict] = Body(None)
):
    """Update therapist verification status (admin only)"""
    rejection_reason: Optional[str] = None
    if body and "rejection_reason" in body:
        rejection_reason = body["rejection_reason"]
    return update_therapist_verification_status(user_id, status, rejection_reason)

@router.get("/therapist/dashboard/{user_id}")
def get_dashboard(user_id: str):
    """Get therapist dashboard data"""
    return get_therapist_dashboard_data(user_id)

