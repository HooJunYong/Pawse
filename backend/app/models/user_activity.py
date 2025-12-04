from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class ActivityStatus(str, Enum):
    """Enum for user activity status"""
    PENDING = "pending"
    COMPLETED = "completed"
    MISSING = "missing"


class UserActivity(BaseModel):
    """UserActivity model for MongoDB collection - tracks user's daily activity progress"""
    user_id: str = Field(..., description="Reference to User (USR001, USR002, ...)")
    activity_id: str = Field(..., description="Reference to Activity (ACT001, ACT002, ...)")
    assigned_date: datetime = Field(default_factory=datetime.utcnow, description="Date when activity was assigned")
    status: ActivityStatus = Field(default=ActivityStatus.PENDING, description="Activity status")
    action_key: str = Field(..., description="Copy from Activity used to track this activity")
    progress: int = Field(default=0, description="Current progress count (e.g., 0/3 messages sent)")
    target: int = Field(..., description="Target count to complete the activity")
    completion_date: Optional[datetime] = Field(default=None, description="Date when activity was completed")

    class Config:
        json_schema_extra = {
            "example": {
                "user_id": "USR001",
                "activity_id": "ACT001",
                "assigned_date": "2025-12-04T00:00:00",
                "status": "pending",
                "action_key": "chat_message",
                "progress": 0,
                "target": 3,
                "completion_date": None
            }
        }


class UserActivityCreate(BaseModel):
    """Request model for creating a UserActivity"""
    user_id: str
    activity_id: str
    assigned_date: Optional[datetime] = None
    status: ActivityStatus = ActivityStatus.PENDING
    action_key: str
    progress: int = 0
    target: int


class UserActivityUpdate(BaseModel):
    """Request model for updating a UserActivity"""
    status: Optional[ActivityStatus] = None
    progress: Optional[int] = None
    completion_date: Optional[datetime] = None


class UserActivityResponse(BaseModel):
    """Response model for UserActivity"""
    user_id: str
    activity_id: str
    assigned_date: datetime
    status: ActivityStatus
    action_key: str
    progress: int
    target: int
    completion_date: Optional[datetime]
