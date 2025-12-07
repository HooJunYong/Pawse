import secrets
import logging
from datetime import datetime, timedelta
from typing import Optional
from fastapi import HTTPException
import pytz
from ..models.database import db
from ..config.timezone import now_my

logger = logging.getLogger(__name__)

# OTP Configuration
OTP_LENGTH = 6
OTP_EXPIRY_MINUTES = 10
MAX_OTP_ATTEMPTS = 5

def generate_otp() -> str:
    """Generate a 6-digit OTP code"""
    return ''.join([str(secrets.randbelow(10)) for _ in range(OTP_LENGTH)])

def create_otp(email: str) -> dict:
    """
    Create and store OTP for password reset, then send via email
    """
    from .email_service import send_otp_email
    
    # Verify user exists
    user = db.users.find_one({"email": email.lower()})
    if not user:
        raise HTTPException(status_code=404, detail="No account found. Did you mean to Sign Up?")
    
    # Generate OTP
    otp_code = generate_otp()
    now = now_my()
    expires_at = now + timedelta(minutes=OTP_EXPIRY_MINUTES)
    
    # Send OTP via email
    email_sent = send_otp_email(email, otp_code)
    if not email_sent:
        logger.error(f"Failed to send OTP email to {email}")
        raise HTTPException(
            status_code=500,
            detail="Failed to send verification email. Please check email configuration or try again later."
        )
    
    # Store OTP in database
    otp_doc = {
        "email": email.lower(),
        "otp_code": otp_code,
        "created_at": now,
        "expires_at": expires_at,
        "attempts": 0,
        "verified": False,
        "used": False,
    }
    
    # Remove any existing OTPs for this email
    db.otp_codes.delete_many({"email": email.lower()})
    
    # Insert new OTP
    db.otp_codes.insert_one(otp_doc)
    
    logger.info(f"OTP created and emailed to {email} (expires at {expires_at})")
    
    return {
        "message": "Verification code sent to your email",
        "expires_in_minutes": OTP_EXPIRY_MINUTES
    }

def verify_otp(email: str, otp_code: str) -> dict:
    """
    Verify OTP code for password reset
    Returns success status and user_id if valid
    """
    # Find OTP record
    otp_record = db.otp_codes.find_one({
        "email": email.lower(),
        "used": False
    })
    
    if not otp_record:
        raise HTTPException(status_code=404, detail="No OTP found for this email")
    
    now = now_my()
    
    # Check if OTP is expired - Fix timezone comparison
    expires_at = otp_record["expires_at"]
    
    # MongoDB stores datetime as UTC naive - convert properly to Malaysia time
    if expires_at.tzinfo is None:
        # Treat stored naive datetime as UTC, then convert to Malaysia time
        utc_tz = pytz.timezone('UTC')
        malaysia_tz = pytz.timezone('Asia/Kuala_Lumpur')
        expires_at = utc_tz.localize(expires_at).astimezone(malaysia_tz)
    
    if now > expires_at:
        db.otp_codes.delete_one({"_id": otp_record["_id"]})
        raise HTTPException(status_code=400, detail="OTP has expired")
    
    # Check if too many attempts
    if otp_record["attempts"] >= MAX_OTP_ATTEMPTS:
        db.otp_codes.delete_one({"_id": otp_record["_id"]})
        raise HTTPException(status_code=400, detail="Too many failed attempts")
    
    # Verify OTP code
    if otp_record["otp_code"] != otp_code:
        # Increment attempt counter
        db.otp_codes.update_one(
            {"_id": otp_record["_id"]},
            {"$inc": {"attempts": 1}}
        )
        raise HTTPException(status_code=400, detail="Invalid OTP code")
    
    # Mark OTP as verified
    db.otp_codes.update_one(
        {"_id": otp_record["_id"]},
        {"$set": {"verified": True, "verified_at": now}}
    )
    
    # Get user_id
    user = db.users.find_one({"email": email.lower()})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    logger.info(f"OTP verified successfully for {email}")
    
    return {
        "success": True,
        "message": "OTP verified successfully",
        "user_id": user.get("user_id"),
        "email": email
    }

def reset_password_with_otp(email: str, otp_code: str, new_password: str) -> dict:
    """
    Reset password using verified OTP
    """
    from .password_service import hash_password
    
    # Verify OTP is valid and verified
    otp_record = db.otp_codes.find_one({
        "email": email.lower(),
        "otp_code": otp_code,
        "verified": True,
        "used": False
    })
    
    if not otp_record:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    
    now = now_my()
    
    # Check if OTP is expired - Fix timezone comparison
    expires_at = otp_record["expires_at"]
    
    # MongoDB stores datetime as UTC naive - convert properly to Malaysia time
    if expires_at.tzinfo is None:
        # Treat stored naive datetime as UTC, then convert to Malaysia time
        utc_tz = pytz.timezone('UTC')
        malaysia_tz = pytz.timezone('Asia/Kuala_Lumpur')
        expires_at = utc_tz.localize(expires_at).astimezone(malaysia_tz)
    
    if now > expires_at:
        raise HTTPException(status_code=400, detail="OTP has expired")
    
    # Validate new password
    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    
    # Update user password
    hashed_password = hash_password(new_password)
    result = db.users.update_one(
        {"email": email.lower()},
        {"$set": {"password": hashed_password}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Mark OTP as used
    db.otp_codes.update_one(
        {"_id": otp_record["_id"]},
        {"$set": {"used": True, "used_at": now}}
    )
    
    logger.info(f"Password reset successfully for {email}")
    
    return {
        "success": True,
        "message": "Password reset successfully"
    }

def cleanup_expired_otps() -> int:
    """
    Remove expired OTP records from database
    Returns number of deleted records
    """
    now = now_my()
    result = db.otp_codes.delete_many({
        "$or": [
            {"expires_at": {"$lt": now}},
            {"used": True}
        ]
    })
    
    logger.info(f"Cleaned up {result.deleted_count} expired/used OTP records")
    return result.deleted_count
