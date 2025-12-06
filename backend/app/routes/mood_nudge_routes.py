from fastapi import APIRouter
from app.models.mood_nudge_schemas import MoodNudgeResponse, MoodNudge
from app.services.mood_nudge_service import MoodNudgeService
from typing import List

router = APIRouter()

@router.get("/mood-nudges/{mood}", response_model=MoodNudgeResponse)
def get_mood_nudges(mood: str):
    """Get all nudge prompts for a specific mood"""
    nudges_data = MoodNudgeService.get_nudges_for_mood(mood)
    nudges = [MoodNudge(mood=mood, **nudge) for nudge in nudges_data]
    return MoodNudgeResponse(mood=mood, nudges=nudges)

@router.get("/mood-nudges/{mood}/random", response_model=MoodNudge)
def get_random_mood_nudge(mood: str):
    """Get a random nudge prompt for a specific mood"""
    nudge_data = MoodNudgeService.get_random_nudge_for_mood(mood)
    return MoodNudge(mood=mood, **nudge_data)

@router.post("/mood-nudges/initialize")
def initialize_mood_nudges():
    """Initialize/update mood nudges in database (admin only)"""
    success = MoodNudgeService.initialize_nudges()
    return {"status": "success" if success else "failed"}
