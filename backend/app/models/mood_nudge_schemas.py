"""
Mood Nudge Schemas
Data models for mood-based intelligent nudges
"""
from pydantic import BaseModel
from typing import List

class MoodNudge(BaseModel):
    """A single mood nudge prompt"""
    mood: str  # 'very_happy', 'happy', 'neutral', 'sad', 'awful'
    title: str
    message: str
    action: str  # e.g., 'open_breathing', 'open_journal', 'call_helpline'

class MoodNudgeResponse(BaseModel):
    """Response containing all nudges for a mood"""
    mood: str
    nudges: List[MoodNudge]
