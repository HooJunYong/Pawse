from pydantic import BaseModel, Field
from typing import Optional


class Activity(BaseModel):
    """Activity model for MongoDB collection - defines daily tasks users can complete"""
    activity_id: str = Field(..., description="Primary Key (ACT001, ACT002, ...)")
    name: str = Field(..., description="Display name of the activity")
    description: str = Field(..., description="Description of what the user needs to do")
    point_award: int = Field(..., description="Points awarded for completing the activity")
    action_key: str = Field(..., description="Key used to track this activity (e.g., chat_message, throw_bottle)")
    target_count: int = Field(..., description="Number of times the action must be performed to complete")

    class Config:
        json_schema_extra = {
            "example": {
                "activity_id": "ACT001",
                "name": "Daily Chat",
                "description": "Send 3 messages to your AI companion.",
                "point_award": 50,
                "action_key": "chat_message",
                "target_count": 3
            }
        }


class ActivityCreate(BaseModel):
    """Request model for creating an Activity"""
    activity_id: str
    name: str
    description: str
    point_award: int
    action_key: str
    target_count: int


class ActivityUpdate(BaseModel):
    """Request model for updating an Activity"""
    name: Optional[str] = None
    description: Optional[str] = None
    point_award: Optional[int] = None
    action_key: Optional[str] = None
    target_count: Optional[int] = None


class ActivityResponse(BaseModel):
    """Response model for Activity"""
    activity_id: str
    name: str
    description: str
    point_award: int
    action_key: str
    target_count: int
