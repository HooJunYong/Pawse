from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class ChatSession(BaseModel):
    """Chat Session model for MongoDB collection"""
    session_id: str = Field(..., description="Primary Key (SESS001, SESS002, etc.)")
    user_id: str = Field(..., description="User identifier")
    companion_id: str = Field(..., description="AI Companion identifier")
    start_time: datetime = Field(default_factory=datetime.utcnow)
    end_time: Optional[datetime] = Field(default=None)
    
    class Config:
        json_schema_extra = {
            "example": {
                "session_id": "SESS001",
                "user_id": "USER001",
                "companion_id": "COMP001",
                "start_time": "2024-01-01T10:00:00",
                "end_time": None
            }
        }


class ChatSessionCreate(BaseModel):
    """Request model for creating a Chat Session"""
    user_id: str
    companion_id: str


class ChatSessionResponse(BaseModel):
    """Response model for Chat Session"""
    session_id: str
    user_id: str
    companion_id: str
    start_time: datetime
    end_time: Optional[datetime] = None
    is_active: bool = Field(default=True, description="Session is active if end_time is None")
    
    @classmethod
    def from_session(cls, session: ChatSession):
        return cls(
            session_id=session.session_id,
            user_id=session.user_id,
            companion_id=session.companion_id,
            start_time=session.start_time,
            end_time=session.end_time,
            is_active=session.end_time is None
        )
