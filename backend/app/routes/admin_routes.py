from fastapi import APIRouter, HTTPException
from ..models.database import db

router = APIRouter()

@router.get("/admin/dashboard-stats")
def get_dashboard_stats():
    """Get admin dashboard statistics"""
    try:
        # Count total users (excluding admin)
        total_users = db.users.count_documents({"user_type": "users"})
        
        # Count verified therapists from therapist_profile collection
        verified_therapists = db.therapist_profile.count_documents({
            "verification_status": "approved"
        })
        
        # Count pending therapist verifications from therapist_profile collection
        pending_verifications = db.therapist_profile.count_documents({
            "verification_status": "pending"
        })
        
        return {
            "total_users": total_users,
            "verified_therapists": verified_therapists,
            "pending_verifications": pending_verifications
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching dashboard stats: {str(e)}")

@router.get("/admin/users")
def get_all_users():
    """Get all users for admin"""
    try:
        users = list(db.users.find(
            {"user_type": "users"},
            {"password": 0}  # Exclude password field
        ).sort("created_at", -1))
        
        # Enrich user data with profile information
        for user in users:
            if "_id" in user:
                user["_id"] = str(user["_id"])
            
            # Get user profile data
            user_id = user.get("user_id")
            if user_id:
                profile = db.user_profile.find_one({"user_id": user_id})
                if profile:
                    # Add all profile fields (note: user_profile uses 'phone_number', not 'contact_number')
                    user["first_name"] = profile.get("first_name", "")
                    user["last_name"] = profile.get("last_name", "")
                    user["full_name"] = profile.get("full_name", f"{user['first_name']} {user['last_name']}".strip()) if profile.get("full_name") else f"{profile.get('first_name', '')} {profile.get('last_name', '')}".strip()
                    user["contact_number"] = profile.get("phone_number", "")  # user_profile uses 'phone_number'
                    user["gender"] = profile.get("gender", "")
                    user["date_of_birth"] = profile.get("date_of_birth", "")
                    user["home_address"] = profile.get("home_address", "")
                    user["city"] = profile.get("city", "")
                    user["state"] = profile.get("state", "")
                    user["zip"] = str(profile.get("zip", "")) if profile.get("zip") else ""
                    
                    # Get avatar from avatar_base64 field
                    avatar_base64 = profile.get("avatar_base64")
                    if avatar_base64 and isinstance(avatar_base64, str) and avatar_base64.strip():
                        # Check if it already has the data URI prefix
                        if not avatar_base64.startswith("data:image"):
                            user["profile_picture"] = f"data:image/png;base64,{avatar_base64}"
                        else:
                            user["profile_picture"] = avatar_base64
                    else:
                        user["profile_picture"] = ""
                else:
                    user["first_name"] = ""
                    user["last_name"] = ""
                    user["full_name"] = "Unknown User"
                    user["contact_number"] = ""
                    user["profile_picture"] = ""
            else:
                user["first_name"] = ""
                user["last_name"] = ""
                user["full_name"] = "Unknown User"
                user["contact_number"] = ""
                user["profile_picture"] = ""
        
        return users
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching users: {str(e)}")

@router.get("/therapist/verified")
def get_verified_therapists():
    """Get all verified therapists"""
    try:
        therapists = list(db.therapist_profile.find(
            {
                "verification_status": "approved"
            }
        ).sort("created_at", -1))
        
        # Convert ObjectId to string
        for therapist in therapists:
            if "_id" in therapist:
                therapist["_id"] = str(therapist["_id"])
        
        return therapists
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching therapists: {str(e)}")
