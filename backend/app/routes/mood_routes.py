from fastapi import APIRouter, HTTPException, Query
from typing import List
from datetime import date as date_type
from ..models.mood_model import MoodCreate, MoodUpdate, MoodResponse
from ..services.mood_service import (
    check_today_log,
    create_mood_entry,
    update_mood,
    get_mood_by_range
)

router = APIRouter()


@router.get("/mood/check-status/{user_id}")
def check_mood_status(user_id: str):
    """
    Check if user has already logged mood for today
    Called upon login to verify mood check-in status
    
    Args:
        user_id: The user's ID
        
    Returns:
        dict: {"has_logged_today": bool}
    """
    has_logged = check_today_log(user_id)
    return {"has_logged_today": has_logged}


@router.post("/mood", response_model=MoodResponse)
def submit_mood(mood_data: MoodCreate):
    """
    Submit a new mood check-in entry
    
    Args:
        mood_data: MoodCreate object containing mood information
        
    Returns:
        MoodResponse: The created mood entry
    """
    return create_mood_entry(mood_data)


@router.put("/mood/{mood_id}", response_model=MoodResponse)
def edit_mood(
    mood_id: str,
    user_id: str = Query(..., description="User ID for verification"),
    mood_data: MoodUpdate = ...
):
    """
    Update an existing mood entry
    
    Args:
        mood_id: The mood entry ID to update
        user_id: User ID for verification (query parameter)
        mood_data: MoodUpdate object with fields to update
        
    Returns:
        MoodResponse: The updated mood entry
    """
    return update_mood(user_id, mood_id, mood_data)


@router.get("/mood/range/{user_id}", response_model=List[MoodResponse])
def get_mood_range(
    user_id: str,
    start_date: date_type = Query(..., description="Start date (YYYY-MM-DD)"),
    end_date: date_type = Query(..., description="End date (YYYY-MM-DD)")
):
    """
    Get mood entries for a specific date range
    
    Args:
        user_id: The user's ID
        start_date: Start date of the range
        end_date: End date of the range
        
    Returns:
        List[MoodResponse]: List of mood entries in the date range
    """
    return get_mood_by_range(user_id, start_date, end_date)
