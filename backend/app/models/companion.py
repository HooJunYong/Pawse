from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class AICompanion(BaseModel):
    """AI Companion model for MongoDB collection"""
    companion_id: str = Field(..., description="Primary Key")
    user_id: Optional[str] = Field(default=None, description="Reference to User")
    personality_id: str = Field(..., description="Reference to Personality")
    companion_name: str = Field(..., description="Name of the companion")
    description: str = Field(..., description="Companion description")
    image: str = Field(..., description="Image URL or path")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_default: bool = Field(default=False)
    is_active: bool = Field(default=True)
    voice_tone: Optional[str] = Field(default=None, description="Voice tone for TTS")
    
    class Config:
        json_schema_extra = {
            "example": {
                "companion_id": "COMP001",
                "user_id": "USER123",
                "personality_id": "PERS001",
                "companion_name": "Luna",
                "description": "A caring and empathetic companion",
                "image": "luna.jpg",
                "is_default": True,
                "is_active": True,
                "voice_tone": "warm"
            }
        }


class AICompanionCreate(BaseModel):
    """Request model for creating an AI Companion"""
    personality_id: str
    user_id: Optional[str] = None
    companion_name: str
    description: str
    image: str
    is_default: bool = False
    is_active: bool = True
    voice_tone: Optional[str] = None


class AICompanionUpdate(BaseModel):
    """Request model for updating an AI Companion"""
    personality_id: Optional[str] = None
    user_id: Optional[str] = None
    companion_name: Optional[str] = None
    description: Optional[str] = None
    image: Optional[str] = None
    is_default: Optional[bool] = None
    is_active: Optional[bool] = None
    voice_tone: Optional[str] = None


class AICompanionResponse(BaseModel):
    """Response model for AI Companion"""
    companion_id: str
    user_id: Optional[str] = None
    personality_id: str
    companion_name: str
    description: str
    image: str
    created_at: datetime
    is_default: bool
    is_active: bool
    voice_tone: Optional[str] = None
