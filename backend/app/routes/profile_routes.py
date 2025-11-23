from fastapi import APIRouter, Query  # type: ignore
from pydantic import EmailStr  # type: ignore
from ..models.schemas import ProfileResponse, UpdateProfileRequest, UpdateProfileResponse
from ..services.profile_service import (
    get_profile_by_id,
    get_profile_by_email,
    get_profile_details,
    update_user_profile
)

router = APIRouter()

@router.get("/profile/{user_id}", response_model=ProfileResponse)
def get_profile(user_id: str):
    """Get user profile by user ID"""
    return get_profile_by_id(user_id)

@router.get("/profile/by-email", response_model=ProfileResponse)
def get_profile_email(email: EmailStr = Query(..., description="User email")):
    """Get user profile by email"""
    return get_profile_by_email(email)

@router.get("/profile/details/{user_id}")
def get_details(user_id: str):
    """Get complete profile details for editing"""
    return get_profile_details(user_id)

@router.put("/profile/{user_id}", response_model=UpdateProfileResponse)
def update_profile(user_id: str, payload: UpdateProfileRequest):
    """Update user profile"""
    return update_user_profile(user_id, payload)
