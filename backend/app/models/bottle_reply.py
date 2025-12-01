from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class BottleReply(BaseModel):
    """Bottle Reply model for MongoDB collection"""
    reply_id: str = Field(..., description="Primary Key (REP001, REP002, ...)")
    bottle_id: str = Field(..., description="Reference to Drift Bottle")
    user_id: str = Field(..., description="Reference to User who replied")
    reply_content: str = Field(..., description="Reply message content")
    reply_time: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        json_schema_extra = {
            "example": {
                "reply_id": "REP001",
                "bottle_id": "BTL001",
                "user_id": "USER456",
                "reply_content": "Thank you for your message!"
            }
        }


class BottleReplyCreate(BaseModel):
    """Request model for creating a Bottle Reply"""
    bottle_id: str
    user_id: str
    reply_content: str


class BottleReplyUpdate(BaseModel):
    """Request model for updating a Bottle Reply"""
    reply_content: Optional[str] = None


class BottleReplyResponse(BaseModel):
    """Response model for Bottle Reply"""
    reply_id: str
    bottle_id: str
    user_id: str
    reply_content: str
    reply_time: datetime
