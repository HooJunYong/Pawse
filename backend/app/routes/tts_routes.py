"""
TTS (Text-to-Speech) API Routes
Handles text-to-speech generation requests
"""

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field
from typing import Optional
from slowapi import Limiter
from slowapi.util import get_remote_address
import logging

from app.services.tts_service import tts_service
from app.models.database import get_database

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/tts", tags=["TTS"])
limiter = Limiter(key_func=get_remote_address)

# Get database
db = get_database()


class TTSRequest(BaseModel):
    """Request model for TTS generation"""
    text: str = Field(..., description="Text to convert to speech", min_length=1, max_length=5000)
    companion_id: str = Field(..., description="Companion ID to get voice settings from")
    
    class Config:
        json_schema_extra = {
            "example": {
                "text": "Hello! How are you feeling today?",
                "companion_id": "COMP001"
            }
        }


class TTSDirectRequest(BaseModel):
    """Request model for direct TTS generation with explicit settings"""
    text: str = Field(..., description="Text to convert to speech", min_length=1, max_length=5000)
    tone: str = Field(default="gentle", description="Voice tone (gentle, energetic, serious, playful)")
    gender: str = Field(default="female", description="Voice gender (female, male)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "text": "Hello! How are you feeling today?",
                "tone": "gentle",
                "gender": "female"
            }
        }


@router.post("/generate")
@limiter.limit("30/minute")
async def generate_tts(request: Request, tts_request: TTSRequest):
    """
    Generate TTS audio based on companion's voice settings
    
    - Gets companion's voice tone and gender from database
    - Generates audio file using Edge TTS
    - Returns audio file URL and metadata
    """
    try:
        # Get companion from database
        companion = db.ai_companions.find_one({"companion_id": tts_request.companion_id})
        
        if not companion:
            raise HTTPException(status_code=404, detail="Companion not found")
        
        # Get voice settings from companion
        tone = companion.get("voice_tone", "gentle")
        gender = companion.get("gender", "female")
        
        # Validate tone and gender
        if not tone:
            tone = "gentle"
        if not gender:
            gender = "female"
            
        logger.info(f"Generating TTS for companion {tts_request.companion_id} with tone={tone}, gender={gender}")
        
        # Generate audio
        result = await tts_service.generate_audio(
            text=tts_request.text,
            tone=tone,
            gender=gender
        )
        
        if not result.get("success"):
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate audio: {result.get('error', 'Unknown error')}"
            )
        
        return {
            "success": True,
            "audio_url": result["url"],
            "filename": result["filename"],
            "tone": result["tone"],
            "gender": result["gender"],
            "voice": result["voice"],
            "duration_estimated": result["duration_estimated"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in generate_tts: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.post("/generate-direct")
@limiter.limit("30/minute")
async def generate_tts_direct(request: Request, tts_request: TTSDirectRequest):
    """
    Generate TTS audio with explicit tone and gender settings
    
    - Does not require companion lookup
    - Useful for testing or custom voice generation
    """
    try:
        logger.info(f"Generating direct TTS with tone={tts_request.tone}, gender={tts_request.gender}")
        
        # Generate audio
        result = await tts_service.generate_audio(
            text=tts_request.text,
            tone=tts_request.tone,
            gender=tts_request.gender
        )
        
        if not result.get("success"):
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate audio: {result.get('error', 'Unknown error')}"
            )
        
        return {
            "success": True,
            "audio_url": result["url"],
            "filename": result["filename"],
            "tone": result["tone"],
            "gender": result["gender"],
            "voice": result["voice"],
            "duration_estimated": result["duration_estimated"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in generate_tts_direct: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.post("/cleanup")
async def cleanup_old_audio(max_age_hours: int = 24):
    """
    Cleanup old audio files
    
    - Removes audio files older than specified hours
    - Default: 24 hours
    """
    try:
        tts_service.cleanup_old_files(max_age_hours)
        return {
            "success": True,
            "message": f"Cleaned up audio files older than {max_age_hours} hours"
        }
    except Exception as e:
        logger.error(f"Error in cleanup_old_audio: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to cleanup: {str(e)}")


@router.get("/voices")
async def get_available_voices():
    """
    Get list of available voice configurations
    
    - Returns all tone and gender combinations
    - Useful for frontend voice selection UI
    """
    from app.services.tts_service import TONE_CONFIG
    
    voices = []
    for tone, config in TONE_CONFIG.items():
        voices.append({
            "tone": tone,
            "female_voice": config["female"],
            "male_voice": config["male"],
            "rate": config["rate"],
            "pitch": config["pitch"]
        })
    
    return {
        "voices": voices,
        "tones": list(TONE_CONFIG.keys()),
        "genders": ["female", "male"]
    }
