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
def check_email_exists(email: str):
    """Check if email exists in either user_profiles or therapist_profiles collection"""
    db = get_database()
    
    # Check user_profiles collection
    user_exists = db.user_profiles.find_one({"email": email}) is not None
    
    # Check therapist_profiles collection
    therapist_exists = db.therapist_profiles.find_one({"email": email}) is not None
    
    return {"exists": user_exists or therapist_exists}
