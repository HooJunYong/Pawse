from typing import Optional
from fastapi import HTTPException  # type: ignore
from ..models.database import db
from ..models.schemas import ProfileResponse, UpdateProfileRequest, UpdateProfileResponse
from ..config.timezone import now_my

def make_initials(
    first_name: Optional[str],
    last_name: Optional[str],
    full_name: Optional[str],
    email: Optional[str],
) -> str:
    """Generate user initials from name or email"""
    fn = (first_name or "").strip()
    ln = (last_name or "").strip()
    if fn or ln:
        first = fn[0].upper() if fn else ""
        last = ln[0].upper() if ln else ""
        return (first + last) or (first or last) or "U"
    if full_name:
        parts = [p for p in full_name.strip().split() if p]
        if len(parts) >= 2:
            return (parts[0][0] + parts[1][0]).upper()
        if parts:
            return parts[0][0].upper()
    if email:
        return email[0].upper()
    return "U"

def compose_profile_response(user_doc: Optional[dict], profile_doc: Optional[dict]) -> ProfileResponse:
    """Compose profile response from user and profile documents"""
    if not user_doc and not profile_doc:
        raise HTTPException(status_code=404, detail="User not found")

    user_id = (profile_doc or {}).get("user_id") or (user_doc or {}).get("user_id")
    email = (user_doc or {}).get("email")

    first_name = (profile_doc or {}).get("first_name") or (user_doc or {}).get("first_name")
    last_name = (profile_doc or {}).get("last_name") or (user_doc or {}).get("last_name")

    if (first_name and first_name.strip()) or (last_name and last_name.strip()):
        full_name = f"{(first_name or '').strip()} {(last_name or '').strip()}".strip()
    else:
        full_name = (
            (profile_doc or {}).get("full_name")
            or (user_doc or {}).get("full_name")
            or (user_doc or {}).get("name")
            or (email.split("@")[0].replace(".", " ").title() if email else "User")
        )

    avatar_url = (profile_doc or {}).get("avatar_url")
    avatar_base64 = (profile_doc or {}).get("avatar_base64")

    return ProfileResponse(
        user_id=str(user_id),
        full_name=str(full_name),
        avatar_url=avatar_url,
        avatar_base64=avatar_base64,
        initials=make_initials(first_name, last_name, full_name, email),
    )

def get_profile_by_id(user_id: str) -> ProfileResponse:
    """Get profile by user ID"""
    profile_doc = db.user_profile.find_one({"user_id": user_id}, {"_id": 0})
    user_doc = db.users.find_one({"user_id": user_id}, {"_id": 0})
    return compose_profile_response(user_doc, profile_doc)

def get_profile_by_email(email: str) -> ProfileResponse:
    """Get profile by email"""
    user_doc = db.users.find_one({"email": email.lower()}, {"_id": 0})
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")
    user_id = user_doc.get("user_id")
    profile_doc = db.user_profile.find_one({"user_id": user_id}, {"_id": 0})
    return compose_profile_response(user_doc, profile_doc)

def get_profile_details(user_id: str) -> dict:
    """Get complete profile details for editing"""
    user = db.users.find_one({"user_id": user_id}, {"_id": 0, "password": 0})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    profile = db.user_profile.find_one({"user_id": user_id}, {"_id": 0})
    
    return {
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

def update_user_profile(user_id: str, payload: UpdateProfileRequest) -> UpdateProfileResponse:
    """Update user profile"""
    user = db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    updates_user = {}
    updates_profile = {}

    if payload.email is not None:
        existing = db.users.find_one({"email": payload.email.lower(), "user_id": {"$ne": user_id}})
        if existing:
            raise HTTPException(status_code=409, detail="Email already in use")
        updates_user["email"] = payload.email.lower()

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

    if payload.delete_avatar:
        updates_profile["avatar_url"] = None
        updates_profile["avatar_base64"] = None
        updates_profile["profile_picture_url"] = None
    else:
        if payload.avatar_base64 is not None:
            updates_profile["avatar_base64"] = payload.avatar_base64
            updates_profile["avatar_url"] = None
            updates_profile["profile_picture_url"] = None
        if payload.avatar_url is not None:
            updates_profile["avatar_url"] = payload.avatar_url
            updates_profile["profile_picture_url"] = payload.avatar_url

    updates_profile["updated_at"] = now_my()

    if updates_user:
        db.users.update_one({"user_id": user_id}, {"$set": updates_user})
    
    if updates_profile:
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

def change_user_password(user_id: str, current_password: str, new_password: str) -> dict:
    """Change user password"""
    from .password_service import verify_password, hash_password
    
    user = db.users.find_one({"user_id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if not verify_password(current_password, user.get("password", "")):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters")
    
    if current_password == new_password:
        raise HTTPException(status_code=400, detail="New password must be different from current password")
    
    hashed_password = hash_password(new_password)
    
    db.users.update_one(
        {"user_id": user_id},
        {"$set": {"password": hashed_password}}
    )
    
    return {"message": "Password updated successfully"}
