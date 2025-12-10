from fastapi import APIRouter, HTTPException
from ..models.schemas import (
    CreateOtpRequest,
    VerifyOtpRequest,
    ResetPasswordRequest,
    OtpResponse,
    VerifyOtpResponse,
)
from ..services import otp_service

router = APIRouter(prefix="/otp", tags=["otp"])


@router.post("/create", response_model=OtpResponse)
def create_otp(request: CreateOtpRequest):
    """
    Generate and send OTP to user's email for password reset
    
    In production, the OTP should be sent via email (not returned in response)
    """
    try:
        result = otp_service.create_otp(request.email)
        return OtpResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create OTP: {str(e)}")


@router.post("/verify", response_model=VerifyOtpResponse)
def verify_otp(request: VerifyOtpRequest):
    """
    Verify OTP code entered by user
    
    This endpoint validates the OTP and marks it as verified
    """
    try:
        result = otp_service.verify_otp(request.email, request.otp)
        return VerifyOtpResponse(**result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to verify OTP: {str(e)}")


@router.post("/reset-password", response_model=VerifyOtpResponse)
def reset_password(request: ResetPasswordRequest):
    """
    Reset password using verified OTP
    
    The OTP must be verified first using /verify endpoint
    """
    try:
        result = otp_service.reset_password_with_otp(
            request.email,
            request.otp,
            request.new_password
        )
        return VerifyOtpResponse(**result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to reset password: {str(e)}")


@router.delete("/cleanup")
def cleanup_expired_otps():
    """
    Clean up expired and used OTP records
    
    This endpoint should be called periodically (e.g., via cron job)
    """
    try:
        deleted_count = otp_service.cleanup_expired_otps()
        return {
            "success": True,
            "message": f"Cleaned up {deleted_count} expired/used OTP records"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to cleanup OTPs: {str(e)}")
