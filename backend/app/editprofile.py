from fastapi import APIRouter, HTTPException  # type: ignore
from pydantic import BaseModel, EmailStr  # type: ignore
from typing import Optional
from datetime import datetime

from .db import db
from .timezone import now_my

router = APIRouter()


class UpdateProfileRequest(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    date_of_birth: Optional[str] = None  # DD/MM/YYYY format
    gender: Optional[str] = None
    home_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip: Optional[int] = None
    avatar_base64: Optional[str] = None  # Base64 encoded image
    avatar_url: Optional[str] = None
    delete_avatar: Optional[bool] = False


class UpdateProfileResponse(BaseModel):
    success: bool
    message: str
    user_id: str


@router.put("/profile/{user_id}", response_model=UpdateProfileResponse)
def update_profile(user_id: str, payload: UpdateProfileRequest):
    # Verify user exists
    user = db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    updates_user = {}
    updates_profile = {}

    # Email update goes to users collection
    if payload.email is not None:
        # Check if email is already taken by another user
        existing = db.users.find_one({"email": payload.email.lower(), "user_id": {"$ne": user_id}})
        if existing:
            raise HTTPException(status_code=409, detail="Email already in use")
        updates_user["email"] = payload.email.lower()

    # Profile fields go to user_profile collection
    if payload.first_name is not None:
        updates_profile["first_name"] = payload.first_name.strip()
    if payload.last_name is not None:
        updates_profile["last_name"] = payload.last_name.strip()
    if payload.date_of_birth is not None:
        updates_profile["date_of_birth"] = payload.date_of_birth
    if payload.gender is not None:
        updates_profile["gender"] = payload.gender
    if payload.home_address is not None:
        updates_profile["home_address"] = payload.home_address.strip()
    if payload.city is not None:
        updates_profile["city"] = payload.city.strip()
    if payload.state is not None:
        updates_profile["state"] = payload.state.strip()
    if payload.zip is not None:
        updates_profile["zip"] = payload.zip

    # Handle avatar
    if payload.delete_avatar:
        updates_profile["avatar_url"] = None
        updates_profile["avatar_base64"] = None
        updates_profile["profile_picture_url"] = None
    else:
        if payload.avatar_base64 is not None:
            updates_profile["avatar_base64"] = payload.avatar_base64
            updates_profile["avatar_url"] = None  # Clear URL if base64 provided
            updates_profile["profile_picture_url"] = None  # Clear URL when using base64
        if payload.avatar_url is not None:
            updates_profile["avatar_url"] = payload.avatar_url
            updates_profile["profile_picture_url"] = payload.avatar_url

    # Update timestamp
    updates_profile["updated_at"] = now_my()

    # Apply updates
    if updates_user:
        db.users.update_one({"user_id": user_id}, {"$set": updates_user})
    
    if updates_profile:
        # Upsert profile document
        db.user_profile.update_one(
            {"user_id": user_id},
            {"$set": updates_profile},
            upsert=True
        )

    return UpdateProfileResponse(
        success=True,
        message="Profile updated successfully",
        user_id=user_id
    )


@router.get("/profile/details/{user_id}")
def get_profile_details(user_id: str):
    """Get complete profile with all fields for editing."""
    user = db.users.find_one({"user_id": user_id}, {"_id": 0, "password": 0})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    profile = db.user_profile.find_one({"user_id": user_id}, {"_id": 0})
    
    # Merge user and profile data
    result = {
        "user_id": user_id,
        "email": user.get("email"),
        "first_name": (profile or {}).get("first_name", ""),
        "last_name": (profile or {}).get("last_name", ""),
        "date_of_birth": (profile or {}).get("date_of_birth", ""),
        "gender": (profile or {}).get("gender", ""),
        "home_address": (profile or {}).get("home_address", ""),
        "city": (profile or {}).get("city", ""),
        "state": (profile or {}).get("state", ""),
        "zip": (profile or {}).get("zip"),
        "avatar_url": (profile or {}).get("avatar_url"),
        "avatar_base64": (profile or {}).get("avatar_base64"),
        "profile_picture_url": (profile or {}).get("profile_picture_url"),
    }
    
    return result
