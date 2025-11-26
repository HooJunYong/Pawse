from pydantic import BaseModel, Field
from datetime import date as date_type, datetime
from typing import Optional
from enum import Enum


class MoodType(str, Enum):
    """Enum for valid mood types"""
    VERY_HAPPY = "very happy"
    HAPPY = "happy"
    NEUTRAL = "neutral"
    SAD = "sad"
    AWFUL = "awful"


class MoodBase(BaseModel):
    """Base mood model with common fields"""
    mood_level: MoodType = Field(..., description="Mood level for the day")
    note: Optional[str] = Field(None, description="Optional note about the mood")


class MoodCreate(MoodBase):
    """Model for creating a new mood entry"""
    user_id: str = Field(..., description="User ID who is logging the mood")
    date: date_type = Field(default_factory=date_type.today, description="Date of the mood entry")


class MoodUpdate(BaseModel):
    """Model for updating an existing mood entry"""
    mood_level: Optional[MoodType] = Field(None, description="Updated mood level")
    note: Optional[str] = Field(None, description="Updated note")


class MoodResponse(BaseModel):
    """Model for mood data returned to frontend"""
    mood_id: str = Field(..., description="Unique mood entry ID")
    user_id: str = Field(..., description="User ID")
    date: date_type = Field(..., description="Date of the mood entry")
    mood_level: MoodType = Field(..., description="Mood level")
    note: Optional[str] = Field(None, description="Note about the mood")
    
    class Config:
        json_schema_extra = {
            "example": {
                "mood_id": "MOOD001",
                "user_id": "USR001",
                "date": "2025-11-26",
                "mood_level": "happy",
                "note": "Had a great day at work!",
            }
        }


class MoodStats(BaseModel):
    """Model for mood statistics/reports"""
    user_id: str = Field(..., description="User ID")
    start_date: date_type = Field(..., description="Start date of the period")
    end_date: date_type = Field(..., description="End date of the period")
    total_entries: int = Field(..., description="Total number of mood entries")
    mood_distribution: dict = Field(..., description="Distribution of mood types")
    average_mood_score: Optional[float] = Field(None, description="Average mood score if applicable")
    
    class Config:
        json_schema_extra = {
            "example": {
                "user_id": "USR001",
                "start_date": "2025-11-01",
                "end_date": "2025-11-30",
                "total_entries": 25,
                "mood_distribution": {
                    "very happy": 5,
                    "happy": 10,
                    "neutral": 7,
                    "sad": 2,
                    "awful": 1
                },
                "average_mood_score": 3.2
            }
        }
