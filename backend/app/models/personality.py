from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class Personality(BaseModel):
    """Personality model for MongoDB collection"""
    personality_id: str = Field(..., description="Primary Key")
    personality_name: str = Field(..., description="Name of personality type")
    description: str = Field(..., description="Personality description")
    prompt_modifier: str = Field(..., description="Prompt instructions for AI")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = Field(default=True)
    
    class Config:
        json_schema_extra = {
            "example": {
                "personality_id": "PERS001",
                "personality_name": "Empathetic",
                "description": "Caring and understanding personality",
                "prompt_modifier": "With an EMPATHETIC personality. Your communication style is warm, caring, and understanding. You listen carefully and respond with compassion.",
                "is_active": True
            }
        }


class PersonalityCreate(BaseModel):
    """Request model for creating a Personality"""
    personality_name: str
    description: str
    prompt_modifier: str
    is_active: bool = True


class PersonalityUpdate(BaseModel):
    """Request model for updating a Personality"""
    personality_name: Optional[str] = None
    description: Optional[str] = None
    prompt_modifier: Optional[str] = None
    is_active: Optional[bool] = None


class PersonalityResponse(BaseModel):
    """Response model for Personality"""
    personality_id: str
    personality_name: str
    description: str
    prompt_modifier: str
    created_at: datetime
    is_active: bool
