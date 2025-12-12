from typing import Optional
from fastapi import APIRouter, status  # type: ignore
from ..models.schemas import SignupRequest, SignupResponse, LoginRequest, LoginResponse, LoginHistoryResponse
from ..services.auth_service import create_user, authenticate_user, get_login_history
from ..models.database import get_database

router = APIRouter()

@router.post("/signup", response_model=SignupResponse, status_code=status.HTTP_201_CREATED)
def signup(payload: SignupRequest):
    """Register a new user"""
    return create_user(payload)

@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest):
    """Authenticate user and return login credentials"""
    return authenticate_user(payload)

@router.get("/login/history/{user_id}", response_model=LoginHistoryResponse)
def login_history(user_id: str, limit: int = 20):
    """Return recent login timestamps for a user"""
    return get_login_history(user_id, limit)

@router.get("/check-email-exists")
def check_email_exists(email: str, user_id: Optional[str] = None):
    """Check if email exists in users or approved therapist_profile"""
    db = get_database()
    
    email_lower = email.lower()
    
    # Build query for users
    user_query = {"email": email_lower}
    if user_id:
        user_query["user_id"] = {"$ne": user_id}
    
    # Check users collection
    user_exists = db.users.find_one(user_query) is not None
    
    # Build query for therapist_profile (only approved therapists)
    therapist_query = {
        "email": email_lower,
        "verification_status": "approved"
    }
    if user_id:
        therapist_query["user_id"] = {"$ne": user_id}
    
    # Check therapist_profile collection
    therapist_exists = db.therapist_profile.find_one(therapist_query) is not None
    
    return {"exists": user_exists or therapist_exists}
