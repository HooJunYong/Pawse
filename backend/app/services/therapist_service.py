import uuid
import logging
from typing import Optional, List, Tuple
from fastapi import HTTPException
from ..models.database import db
from ..models.schemas import TherapistApplicationRequest, TherapistApplicationResponse, TherapistProfileResponse, UpdateTherapistProfileRequest
from ..config.timezone import now_my

logger = logging.getLogger(__name__)


def _guess_image_mime(image_base64: str) -> str:
    """Derive the most likely mime type from a base64-encoded image."""

    sample = image_base64.strip()[:30]
    if sample.startswith('/9j/'):
        return 'image/jpeg'
    if sample.startswith('iVBORw0KGgo'):
        return 'image/png'
    if sample.startswith('R0lGOD'):
        return 'image/gif'
    if sample.startswith('Qk'):
        return 'image/bmp'
    return 'image/png'


def _normalize_profile_picture_input(value: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
    """Normalise incoming profile picture data to ensure DB always stores a usable URL.

    Returns a tuple of (url/data-uri, raw_base64_without_prefix).
    """

    if value is None:
        return None, None

    candidate = value.strip()
    if not candidate:
        return None, None

    if candidate.lower().startswith('data:image'):
        parts = candidate.split(',', 1)
        base64_payload = parts[1] if len(parts) == 2 else ''
        return candidate, base64_payload or None

    if candidate.lower().startswith('http://') or candidate.lower().startswith('https://'):
        return candidate, None

    # Treat as raw base64 content and wrap in a data URI so the front-end can render it.
    mime_type = _guess_image_mime(candidate)
    data_uri = f"data:{mime_type};base64,{candidate}"
    return data_uri, candidate


def _ensure_profile_picture_fields(doc: dict) -> None:
    """Ensure profile picture fields inside the document are normalised."""

    if not isinstance(doc, dict):
        return

    candidates: list[str] = []
    raw_url = doc.get('profile_picture_url')
    raw_base64 = doc.get('profile_picture_base64')

    if isinstance(raw_url, str):
        candidates.append(raw_url)
    if isinstance(raw_base64, str):
        candidates.append(raw_base64)

    resolved_url: Optional[str] = None
    resolved_base64: Optional[str] = None

    for candidate in candidates:
        url, base64_payload = _normalize_profile_picture_input(candidate)
        if url and not resolved_url:
            resolved_url = url
        if base64_payload and not resolved_base64:
            resolved_base64 = base64_payload

    if resolved_url:
        doc['profile_picture_url'] = resolved_url
    if resolved_base64:
        doc['profile_picture_base64'] = resolved_base64


def _compute_rating_summary(therapist_ids: List[str]) -> dict[str, dict[str, float | int]]:
    """Return average rating and count for each therapist id provided."""

    if not therapist_ids:
        return {}

    logger.info(f"Computing ratings for therapist IDs: {therapist_ids}")
    
    summary: dict[str, list[float]] = {}
    cursor = db.therapy_sessions.find(
        {
            "therapist_user_id": {"$in": therapist_ids},
            "user_rating": {"$exists": True, "$ne": None},
        },
        {"therapist_user_id": 1, "user_rating": 1},
    )

    doc_count = 0
    for doc in cursor:
        doc_count += 1
        rating_value = doc.get("user_rating")
        therapist_id = doc.get("therapist_user_id")
        logger.info(f"Found session: therapist_id={therapist_id}, rating={rating_value}")
        if therapist_id and isinstance(rating_value, (int, float)):
            summary.setdefault(therapist_id, []).append(float(rating_value))

    logger.info(f"Total sessions found: {doc_count}")
    logger.info(f"Rating summary: {summary}")

    aggregates: dict[str, dict[str, float | int]] = {}
    for therapist_id, ratings in summary.items():
        if not ratings:
            continue
        average = round(sum(ratings) / len(ratings), 1)
        aggregates[therapist_id] = {
            "average_rating": average,
            "total_ratings": len(ratings),
        }

    logger.info(f"Final aggregates: {aggregates}")
    return aggregates

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
            normalized_url, base64_payload = _normalize_profile_picture_input(payload.profile_picture)

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
                "profile_picture_url": normalized_url,
                "profile_picture_base64": base64_payload,
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
    
    normalized_url, base64_payload = _normalize_profile_picture_input(payload.profile_picture)

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
        "profile_picture_url": normalized_url,
        "profile_picture_base64": base64_payload,
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

    _ensure_profile_picture_fields(therapist)

    rating_map = _compute_rating_summary([user_id])
    rating_info = rating_map.get(user_id)
    if rating_info:
        therapist["average_rating"] = rating_info["average_rating"]
        therapist["total_ratings"] = rating_info["total_ratings"]
    else:
        therapist["average_rating"] = None
        therapist["total_ratings"] = 0
    
    return TherapistProfileResponse(**therapist)


def get_pending_therapists() -> list[TherapistProfileResponse]:
    """Get all pending therapist applications"""
    therapists = list(db.therapist_profile.find(
        {"verification_status": "pending"},
        {"_id": 0}
    ))

    for therapist in therapists:
        _ensure_profile_picture_fields(therapist)
    
    return [TherapistProfileResponse(**t) for t in therapists]


def get_all_verified_therapists(search_text: Optional[str] = None) -> list[TherapistProfileResponse]:
    """Get all verified therapists with optional search"""
    # Build the base query
    query = {"verification_status": "approved"}
    
    # Add search logic if search_text is provided
    if search_text and search_text.strip():
        search_pattern = {"$regex": search_text.strip(), "$options": "i"}
        query["$or"] = [
            {"first_name": search_pattern},
            {"last_name": search_pattern},
            {"specializations": search_pattern}
        ]
    
    therapists = list(db.therapist_profile.find(query, {"_id": 0}))

    for therapist in therapists:
        _ensure_profile_picture_fields(therapist)

    therapist_ids = [t.get("user_id", "") for t in therapists if t.get("user_id")]
    rating_map = _compute_rating_summary(therapist_ids)

    for therapist in therapists:
        therapist_id = therapist.get("user_id")
        rating_info = rating_map.get(therapist_id, {}) if therapist_id else {}
        therapist["average_rating"] = rating_info.get("average_rating")
        therapist["total_ratings"] = rating_info.get("total_ratings", 0)

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


def get_therapist_dashboard_data(user_id: str) -> dict:
    """Get therapist dashboard data including appointments and availability"""
    # Get user basic info
    user = db.users.find_one({"user_id": user_id}, {"_id": 0})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get therapist profile
    therapist = db.therapist_profile.find_one({"user_id": user_id}, {"_id": 0})
    if not therapist:
        raise HTTPException(status_code=404, detail="Therapist profile not found")
    
    # Check if therapist is approved
    if therapist.get("verification_status") != "approved":
        raise HTTPException(status_code=403, detail="Therapist not approved")
    
    # Get therapist name
    first_name = therapist.get("first_name", "")
    last_name = therapist.get("last_name", "")
    therapist_name = f"Dr. {first_name} {last_name}".strip()
    
    # TODO: Get today's appointments from appointments collection
    # For now, return empty lists
    today_appointments = []
    
    # TODO: Get upcoming availability from schedules collection
    upcoming_availability = []
    
    return {
        "therapist_name": therapist_name,
        "today_appointments": today_appointments,
        "upcoming_availability": upcoming_availability,
        "total_clients": 0,  # TODO: Calculate from appointments
        "sessions_completed": 0,  # TODO: Calculate from appointments
        "hours_available": 0,  # TODO: Calculate from schedules
    }


def update_therapist_profile(user_id: str, payload: UpdateTherapistProfileRequest) -> TherapistProfileResponse:
    """Update therapist profile"""
    therapist = db.therapist_profile.find_one({"user_id": user_id})
    if not therapist:
        raise HTTPException(status_code=404, detail="Therapist profile not found")
    
    now = now_my()
    update_data: dict = {"updated_at": now}
    
    # Update basic fields if provided
    if payload.first_name is not None:
        update_data["first_name"] = payload.first_name
    if payload.last_name is not None:
        update_data["last_name"] = payload.last_name
    if payload.email is not None:
        update_data["email"] = payload.email
    if payload.contact_number is not None:
        update_data["contact_number"] = payload.contact_number
    if payload.bio is not None:
        update_data["bio"] = payload.bio
    if payload.office_name is not None:
        update_data["office_name"] = payload.office_name
    if payload.office_address is not None:
        update_data["office_address"] = payload.office_address
    if payload.city is not None:
        update_data["city"] = payload.city
    if payload.state is not None:
        update_data["state"] = payload.state
    if payload.zip is not None:
        update_data["zip"] = payload.zip
    if payload.specializations is not None:
        update_data["specializations"] = payload.specializations
    if payload.languages_spoken is not None:
        update_data["languages_spoken"] = payload.languages_spoken
    if payload.hourly_rate is not None:
        update_data["hourly_rate"] = payload.hourly_rate
    
    # Handle profile picture
    if payload.delete_profile_picture:
        update_data["profile_picture_url"] = None
        update_data["profile_picture_base64"] = None
    elif payload.profile_picture_base64:
        normalized_url, base64_payload = _normalize_profile_picture_input(payload.profile_picture_base64)
        update_data["profile_picture_url"] = normalized_url
        update_data["profile_picture_base64"] = base64_payload
    elif payload.profile_picture_url is not None:
        normalized_url, base64_payload = _normalize_profile_picture_input(payload.profile_picture_url)
        update_data["profile_picture_url"] = normalized_url
        update_data["profile_picture_base64"] = base64_payload
    
    try:
        db.therapist_profile.update_one(
            {"user_id": user_id},
            {"$set": update_data}
        )
        logger.info(f"Therapist profile updated: {user_id}")
        
        # Return updated profile
        updated_therapist = db.therapist_profile.find_one({"user_id": user_id}, {"_id": 0})
        if not updated_therapist:
            raise HTTPException(status_code=404, detail="Updated profile not found")
        _ensure_profile_picture_fields(updated_therapist)
        return TherapistProfileResponse(**updated_therapist)  # type: ignore
    except Exception as e:
        logger.error(f"Failed to update therapist profile: {e}")
        raise HTTPException(status_code=500, detail="Failed to update profile")

