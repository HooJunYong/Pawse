import uuid
import logging
from fastapi import HTTPException, status  # type: ignore
from pymongo.errors import DuplicateKeyError
from ..models.database import db
from ..models.schemas import SignupRequest, SignupResponse, LoginRequest, LoginResponse, LoginHistoryItem, LoginHistoryResponse
from ..config.settings import PASSWORD_MIN_LENGTH, VALID_USER_TYPES
from ..config.timezone import now_my
from .password_service import hash_password, verify_password

logger = logging.getLogger(__name__)

def create_user(payload: SignupRequest) -> SignupResponse:
    """Create a new user account"""
    # Validate password
    if len(payload.password) < PASSWORD_MIN_LENGTH:
        raise HTTPException(status_code=400, detail="Password too short")
    if payload.user_type not in VALID_USER_TYPES:
        raise HTTPException(status_code=400, detail="Invalid user_type")

    # Check existing user
    existing = db.users.find_one({"email": payload.email.lower()})
    if existing:
        logger.warning(f"Signup failed: email {payload.email} already exists")
        raise HTTPException(status_code=409, detail="Email already registered")

    user_id = str(uuid.uuid4())
    logger.info(f"Creating new user: {user_id} / {payload.email}")
    now = now_my()
    password_hash = hash_password(payload.password)

    user_doc = {
        "user_id": user_id,
        "email": payload.email.lower(),
        "phone_number": payload.phone_number,
        "password": password_hash,
        "user_type": payload.user_type,
        "created_at": now,
        "last_login": None,
        "is_active": True,
    }

    profile_doc = {
        "user_id": user_id,
        "first_name": payload.first_name,
        "last_name": payload.last_name,
        "gender": payload.gender,
        "date_of_birth": payload.date_of_birth,
        "home_address": payload.home_address,
        "city": payload.city,
        "state": payload.state,
        "zip": payload.zip,
        "profile_picture_url": payload.profile_picture_url,
        "updated_at": now,
        "total_points": 0,
    }

    try:
        db.users.insert_one(user_doc)
        logger.info(f"Inserted user document: {user_id}")
        db.user_profile.insert_one(profile_doc)
        logger.info(f"Inserted profile document: {user_id}")
    except DuplicateKeyError:
        logger.warning(f"Signup failed: email {payload.email} already exists (DuplicateKeyError)")
        # Clean up if user was inserted but profile failed (unlikely for email dup, but good practice)
        db.users.delete_one({"user_id": user_id}) 
        raise HTTPException(status_code=409, detail="Email already registered")
    except Exception as e:
        logger.error(f"Insert failed for {user_id}: {e}")
        db.users.delete_one({"user_id": user_id})
        raise HTTPException(status_code=500, detail="Failed to create user profile")

    logger.info(f"Signup successful: {user_id} / {payload.email}")
    return SignupResponse(
        user_id=user_id,
        email=payload.email,
        created_at=now,
        first_name=payload.first_name,
        last_name=payload.last_name,
    )

def authenticate_user(payload: LoginRequest) -> LoginResponse:
    """Authenticate user and return login response"""
    user = db.users.find_one({"email": payload.email.lower()})
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not verify_password(payload.password, user.get("password", "")):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user.get("is_active", True):
        raise HTTPException(status_code=403, detail="User inactive")

    now = now_my()
    db.users.update_one({"user_id": user["user_id"]}, {"$set": {"last_login": now}})
    db.user_login_events.insert_one({
        "user_id": user["user_id"],
        "login_at": now,
    })
    return LoginResponse(
        user_id=user["user_id"], 
        email=user["email"], 
        user_type=user.get("user_type", "user"),
        last_login=now
    )

def get_login_history(user_id: str, limit: int = 20) -> LoginHistoryResponse:
    """Get user login history"""
    if limit <= 0 or limit > 100:
        limit = 20
    cursor = (
        db.user_login_events.find({"user_id": user_id}, {"_id": 0})
        .sort("login_at", -1)
        .limit(limit)
    )
    events = [LoginHistoryItem(**doc) for doc in cursor]
    if not events and not db.users.find_one({"user_id": user_id}):
        raise HTTPException(status_code=404, detail="User not found")
    return LoginHistoryResponse(user_id=user_id, history=events)
