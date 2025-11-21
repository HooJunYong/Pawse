import uuid
import logging
from typing import Optional
from fastapi import HTTPException
from ..models.database import db
from ..models.schemas import TherapistApplicationRequest, TherapistApplicationResponse, TherapistProfileResponse
from ..config.timezone import now_my

logger = logging.getLogger(__name__)

def submit_therapist_application(payload: TherapistApplicationRequest) -> TherapistApplicationResponse:
    """Submit a therapist application"""
    
    # Check if user exists
    user = db.users.find_one({"user_id": payload.user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if therapist profile already exists
    existing_therapist = db.therapist_profile.find_one({"user_id": payload.user_id})
    
    # If existing application is rejected, allow resubmission by updating the document
    if existing_therapist:
        if existing_therapist.get("verification_status") == "rejected":
            # Allow resubmission - update the existing document
            now = now_my()
            update_doc = {
                "license_number": payload.license_number,
                "first_name": payload.first_name,
                "last_name": payload.last_name,
                "email": payload.email,
                "contact_number": payload.contact_number,
                "bio": payload.bio,
                "office_name": payload.office_name,
                "office_address": payload.office_address,
                "city": payload.city,
                "state": payload.state,
                "zip": payload.zip,
                "specializations": payload.specializations,
                "languages_spoken": payload.languages,
                "hourly_rate": payload.hourly_rate,
                "profile_picture_url": payload.profile_picture,
                "verification_status": "pending",  # Reset to pending
                "verified_at": None,
                "rejection_reason": None,  # Clear rejection reason
                "updated_at": now,
            }
            
            try:
                db.therapist_profile.update_one(
                    {"user_id": payload.user_id},
                    {"$set": update_doc}
                )
                logger.info(f"Therapist application resubmitted: {payload.user_id}")
                
                return TherapistApplicationResponse(
                    success=True,
                    message="Application resubmitted successfully. We will review and contact you soon.",
                    application_id=str(existing_therapist["_id"])
                )
            except Exception as e:
                logger.error(f"Failed to resubmit therapist application: {e}")
                raise HTTPException(status_code=500, detail="Failed to resubmit application")
        else:
            # Application exists and is not rejected
            raise HTTPException(status_code=409, detail="Therapist application already exists")
    
    # Check if license number is already registered by another user
    existing_license = db.therapist_profile.find_one({
        "license_number": payload.license_number,
        "user_id": {"$ne": payload.user_id}
    })
    if existing_license:
        raise HTTPException(status_code=409, detail="License number already registered")
    
    now = now_my()
    
    therapist_doc = {
        "user_id": payload.user_id,
        "license_number": payload.license_number,
        "first_name": payload.first_name,
        "last_name": payload.last_name,
        "email": payload.email,
        "contact_number": payload.contact_number,
        "bio": payload.bio,
        "office_name": payload.office_name,
        "office_address": payload.office_address,
        "city": payload.city,
        "state": payload.state,
        "zip": payload.zip,
        "specializations": payload.specializations,
        "languages_spoken": payload.languages,
        "hourly_rate": payload.hourly_rate,
        "profile_picture_url": payload.profile_picture,  # Can store base64 or URL
        "verification_status": "pending",  # pending, approved, rejected
        "verified_at": None,
        "created_at": now,
        "updated_at": now,
    }
    
    try:
        result = db.therapist_profile.insert_one(therapist_doc)
        logger.info(f"Therapist application submitted: {payload.user_id}")
        
        return TherapistApplicationResponse(
            success=True,
            message="Application submitted successfully. We will review and contact you soon.",
            application_id=str(result.inserted_id)
        )
    except Exception as e:
        logger.error(f"Failed to submit therapist application: {e}")
        raise HTTPException(status_code=500, detail="Failed to submit application")


def get_therapist_profile(user_id: str) -> TherapistProfileResponse:
    """Get therapist profile by user_id"""
    therapist = db.therapist_profile.find_one({"user_id": user_id}, {"_id": 0})
    
    if not therapist:
        raise HTTPException(status_code=404, detail="Therapist profile not found")
    
    return TherapistProfileResponse(**therapist)


def get_pending_therapists() -> list[TherapistProfileResponse]:
    """Get all pending therapist applications"""
    therapists = list(db.therapist_profile.find(
        {"verification_status": "pending"},
        {"_id": 0}
    ))
    
    return [TherapistProfileResponse(**t) for t in therapists]


def get_all_verified_therapists() -> list[TherapistProfileResponse]:
    """Get all verified therapists"""
    therapists = list(db.therapist_profile.find(
        {"verification_status": "approved"},
        {"_id": 0}
    ))
    
    return [TherapistProfileResponse(**t) for t in therapists]


def update_therapist_verification_status(user_id: str, status: str, rejection_reason: Optional[str] = None) -> dict:
    """Update therapist verification status (admin function)"""
    if status not in ["pending", "approved", "rejected"]:
        raise HTTPException(status_code=400, detail="Invalid verification status")
    
    therapist = db.therapist_profile.find_one({"user_id": user_id})
    if not therapist:
        raise HTTPException(status_code=404, detail="Therapist profile not found")
    
    now = now_my()
    update_data = {
        "verification_status": status,
        "updated_at": now
    }
    
    if status == "approved":
        update_data["verified_at"] = now
        update_data["rejection_reason"] = None  # Clear rejection reason if approving
    elif status == "rejected":
        update_data["rejection_reason"] = rejection_reason
        update_data["verified_at"] = None
    
    db.therapist_profile.update_one(
        {"user_id": user_id},
        {"$set": update_data}
    )
    
    logger.info(f"Therapist verification status updated: {user_id} -> {status}")
    
    return {
        "success": True,
        "message": f"Verification status updated to {status}",
        "user_id": user_id,
        "status": status
    }
