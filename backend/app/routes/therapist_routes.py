from fastapi import APIRouter, HTTPException
from ..models.schemas import TherapistApplicationRequest, TherapistApplicationResponse, TherapistProfileResponse
from ..services.therapist_service import (
    submit_therapist_application,
    get_therapist_profile,
    get_all_verified_therapists,
    update_therapist_verification_status
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

@router.get("/therapist/verified", response_model=list[TherapistProfileResponse])
def get_verified_therapists():
    """Get all verified therapists"""
    return get_all_verified_therapists()

@router.put("/therapist/verify/{user_id}")
def verify_therapist(user_id: str, status: str):
    """Update therapist verification status (admin only)"""
    return update_therapist_verification_status(user_id, status)
