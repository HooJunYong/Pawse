"""
Activity Routes
API endpoints for daily activities, points, and rank management
"""
from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from pydantic import BaseModel
import logging

from app.services.activity_service import ActivityService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/activities", tags=["Activities"])


# ==================== Request Models ====================

class TrackActivityRequest(BaseModel):
    """Request model for tracking an activity"""
    user_id: str
    action_key: str


class AwardPointsRequest(BaseModel):
    """Request model for manually awarding points"""
    user_id: str
    points: int


# ==================== Activity Assignment Routes ====================

@router.post("/check-and-assign/{user_id}")
async def check_and_assign_activities(user_id: str):
    """
    Check if user has activities assigned for today.
    If not, assigns all activities automatically.
    Call this on user login.
    
    - **user_id**: The user ID
    
    Returns whether activities were already assigned or newly assigned
    """
    try:
        already_assigned = ActivityService.has_activities_assigned_today(user_id)
        
        return {
            "user_id": user_id,
            "already_assigned": already_assigned,
            "message": "Activities already assigned for today" if already_assigned else "Activities assigned successfully"
        }
    except Exception as e:
        logger.error(f"Error checking/assigning activities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to check/assign activities: {str(e)}")


@router.get("/daily/{user_id}")
async def get_daily_activities(user_id: str):
    """
    Get all user's activities for today with progress and details.
    
    - **user_id**: The user ID
    
    Returns list of today's activities with progress
    """
    try:
        activities = ActivityService.get_user_daily_activities(user_id)
        return {
            "user_id": user_id,
            "activities": activities,
            "total_count": len(activities),
            "completed_count": sum(1 for a in activities if a["status"] == "completed")
        }
    except Exception as e:
        logger.error(f"Error getting daily activities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get daily activities: {str(e)}")


# ==================== Activity Tracking Routes ====================

@router.post("/track")
async def track_activity(request: TrackActivityRequest):
    """
    Track when user performs an action.
    Call this when user sends a message, throws a bottle, logs mood, etc.
    
    - **user_id**: The user ID
    - **action_key**: The action key (chat_message, throw_bottle, log_mood_note, reply_bottle, music_listen, breathing_complete)
    
    Returns tracking result with progress info
    """
    try:
        result = ActivityService.track_activity(
            user_id=request.user_id,
            action_key=request.action_key
        )
        
        if result is None:
            return {
                "tracked": False,
                "message": "No pending activity found for this action"
            }
        
        return {
            "tracked": True,
            **result
        }
    except Exception as e:
        logger.error(f"Error tracking activity: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to track activity: {str(e)}")


# ==================== Points Routes ====================

@router.post("/points/award")
async def award_points(request: AwardPointsRequest):
    """
    Manually award points to a user (admin use).
    
    - **user_id**: The user ID
    - **points**: Number of points to award
    
    Returns updated points info
    """
    try:
        result = ActivityService.award_points(
            user_id=request.user_id,
            points=request.points
        )
        return result
    except Exception as e:
        logger.error(f"Error awarding points: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to award points: {str(e)}")


# ==================== Rank Routes ====================

@router.get("/rank/{user_id}")
async def get_user_rank(user_id: str):
    """
    Get user's current rank details.
    
    - **user_id**: The user ID
    
    Returns current rank info with points
    """
    try:
        rank = ActivityService.get_user_rank(user_id)
        
        if not rank:
            raise HTTPException(status_code=404, detail="User not found")
        
        return rank
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting user rank: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get user rank: {str(e)}")


@router.get("/rank/progress/{user_id}")
async def get_rank_progress(user_id: str):
    """
    Get user's progress towards the next rank.
    
    - **user_id**: The user ID
    
    Returns progress info including points needed for next rank
    """
    try:
        progress = ActivityService.get_next_rank_progress(user_id)
        
        if "error" in progress:
            raise HTTPException(status_code=404, detail=progress["error"])
        
        return progress
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting rank progress: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get rank progress: {str(e)}")


@router.post("/rank/check/{user_id}")
async def check_rank_update(user_id: str):
    """
    Manually check and update user's rank based on lifetime points.
    
    - **user_id**: The user ID
    
    Returns rank update result
    """
    try:
        result = ActivityService.check_and_update_rank(user_id)
        
        if "error" in result:
            raise HTTPException(status_code=404, detail=result["error"])
        
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error checking rank: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to check rank: {str(e)}")
