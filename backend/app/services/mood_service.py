from typing import List, Optional
from datetime import date as date_type, datetime
from fastapi import HTTPException
from ..models.database import db
from ..models.database import mood_collection
from ..models.mood_model import MoodCreate, MoodUpdate, MoodResponse
from ..config.timezone import now_my
from .activity_service import ActivityService
import logging
import uuid

logger = logging.getLogger(__name__)


def generate_mood_id() -> str:
    """Generate a unique mood ID using UUID."""
    return str(uuid.uuid4())


def check_today_log(user_id: str) -> bool:
    """
    Check if user has already logged a mood entry for today
    
    Args:
        user_id: The user's ID
        
    Returns:
        bool: True if user has logged mood today, False otherwise
    """
    try:
        today = now_my().date()
        
        existing_mood = db.mood_tracking.find_one({
            "user_id": user_id,
            "date": today.isoformat()
        })
        
        return existing_mood is not None
    
    except Exception as e:
        logger.error(f"Error checking today's mood log: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to check mood log status")


def create_mood_entry(mood_data: MoodCreate) -> MoodResponse:
    """
    Create a new mood entry in the database
    
    Args:
        mood_data: MoodCreate object with mood information
        
    Returns:
        MoodResponse: The created mood entry
    """
    try:
        # Get server's current date
        server_today = now_my().date()
        
        # Determine which date to use:
        # - If mood_data.date is today (or not provided), use server_today to ensure consistency
        # - If mood_data.date is a past date, use that date (for retroactive logging)
        if mood_data.date == server_today or mood_data.date >= server_today:
            # User is logging for today - use server date to prevent timezone issues
            entry_date = server_today
        else:
            # User is logging for a past date - use the provided date
            entry_date = mood_data.date
        
        # Check if mood already exists for this date
        existing_mood = db.mood_tracking.find_one({
            "user_id": mood_data.user_id,
            "date": entry_date.isoformat()
        })
        
        if existing_mood:
            raise HTTPException(
                status_code=400,
                detail=f"Mood entry already exists for {entry_date.isoformat()}"
            )

        # Generate unique mood ID
        mood_id = generate_mood_id()
        
        # Prepare mood document
        mood_doc = {
            "mood_id": mood_id,
            "user_id": mood_data.user_id,
            "date": entry_date.isoformat(),
            "mood_level": mood_data.mood_level.value,
            "note": mood_data.note,
        }
        
        # Insert into database
        result = db.mood_tracking.insert_one(mood_doc)
        
        if not result.inserted_id:
            raise HTTPException(status_code=500, detail="Failed to create mood entry")
        
        # Track activity only if logging for today with a note
        is_today = (entry_date == server_today)

        if mood_data.note and mood_data.note.strip() and is_today:
            try:
                track_result = ActivityService.track_activity(
                    user_id=mood_data.user_id,
                    action_key="log_mood_note"
                )
                if track_result:
                    logger.info(f"Activity tracked for mood note logging: {track_result}")
            except Exception as e:
                logger.error(f"Error tracking activity for mood note: {str(e)}")

        # Return response
        return MoodResponse(
            mood_id=mood_id,
            user_id=mood_data.user_id,
            date=entry_date,
            mood_level=mood_data.mood_level,
            note=mood_data.note,
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating mood entry: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create mood entry")


def update_mood(user_id: str, mood_id: str, mood_data: MoodUpdate) -> MoodResponse:
    """
    Update an existing mood entry
    
    Args:
        user_id: The user's ID
        mood_id: The mood entry ID to update
        mood_data: MoodUpdate object with updated fields
        
    Returns:
        MoodResponse: The updated mood entry
    """
    try:
        # Find the mood entry
        existing_mood = db.mood_tracking.find_one({
            "mood_id": mood_id,
            "user_id": user_id
        })
        
        if not existing_mood:
            raise HTTPException(
                status_code=404,
                detail="Mood entry not found or you don't have permission to update it"
            )
        
        # Check if this mood entry is for today
        mood_date = date_type.fromisoformat(existing_mood["date"])
        today = now_my().date()
        is_today = (mood_date == today)

        # Check if user is adding a note for the first time
        had_note_before = existing_mood.get("note") and existing_mood.get("note").strip()
        adding_note_now = mood_data.note and mood_data.note.strip()
        
        # Prepare update fields
        update_fields = {"updated_at": now_my()}
        
        if mood_data.mood_level is not None:
            update_fields["mood_level"] = mood_data.mood_level.value
        
        if mood_data.note is not None:
            update_fields["note"] = mood_data.note
        
        # Update the document
        result = db.mood_tracking.update_one(
            {"mood_id": mood_id, "user_id": user_id},
            {"$set": update_fields}
        )
        
        if result.modified_count == 0:
            logger.warning(f"No changes made to mood entry {mood_id}")
        
        if adding_note_now and not had_note_before and is_today:
            try:
                track_result = ActivityService.track_activity(
                    user_id=user_id,
                    action_key="log_mood_note"
                )
                if track_result:
                    logger.info(f"Activity tracked for mood note update: {track_result}")
            except Exception as e:
                # Log error but don't fail mood update
                logger.warning(f"Failed to track activity for log_mood_note: {str(e)}")

        # Fetch updated document
        updated_mood = db.mood_tracking.find_one({
            "mood_id": mood_id,
            "user_id": user_id
        }, {"_id": 0})
        
        # Return response
        return MoodResponse(
            mood_id=updated_mood["mood_id"],
            user_id=updated_mood["user_id"],
            date=date_type.fromisoformat(updated_mood["date"]),
            mood_level=updated_mood["mood_level"],
            note=updated_mood.get("note")
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating mood entry: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update mood entry")


def get_mood_by_range(user_id: str, start_date: date_type, end_date: date_type) -> List[MoodResponse]:
    """
    Fetch all mood logs for a specific date range
    
    Args:
        user_id: The user's ID
        start_date: Start date of the range
        end_date: End date of the range
        
    Returns:
        List[MoodResponse]: List of mood entries in the date range
    """
    try:
        # Validate date range
        if start_date > end_date:
            raise HTTPException(
                status_code=400,
                detail="Start date must be before or equal to end date"
            )
        
        # Query database
        mood_entries = db.mood_tracking.find({
            "user_id": user_id,
            "date": {
                "$gte": start_date.isoformat(),
                "$lte": end_date.isoformat()
            }
        }, {"_id": 0}).sort("date", -1)  # Sort by date descending
        
        # Convert to response models
        results = []
        for entry in mood_entries:
            results.append(MoodResponse(
                mood_id=entry["mood_id"],
                user_id=entry["user_id"],
                date=date_type.fromisoformat(entry["date"]),
                mood_level=entry["mood_level"],
                note=entry.get("note"),
            ))
        
        return results
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching mood entries: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch mood entries")
