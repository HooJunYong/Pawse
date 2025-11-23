from fastapi import APIRouter  # type: ignore
from ..models.schemas import ChangePasswordRequest
from ..services.profile_service import change_user_password

router = APIRouter()

@router.put("/change-password/{user_id}")
def change_password(user_id: str, request: ChangePasswordRequest):
    """Change user password"""
    return change_user_password(user_id, request.current_password, request.new_password)
