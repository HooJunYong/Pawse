from fastapi import APIRouter, status  # type: ignore
from ..models.schemas import SignupRequest, SignupResponse, LoginRequest, LoginResponse, LoginHistoryResponse
from ..services.auth_service import create_user, authenticate_user, get_login_history

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
