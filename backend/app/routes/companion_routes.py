from fastapi import APIRouter, HTTPException
from typing import List
import logging

from app.models.companion import AICompanionResponse
from app.models.personality import PersonalityResponse
from app.models.database import get_database

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Companions & Personalities"])


@router.get("/companions", response_model=List[AICompanionResponse])
async def get_all_companions(active_only: bool = True):
    """
    Get all AI companions
    
    - **active_only**: If True, return only active companions (default: True)
    
    Returns list of companions
    """
    try:
        db = get_database()
        
        # Build query filter
        query = {"is_active": True} if active_only else {}
        
        # Fetch companions
        companions = list(db.ai_companions.find(query, {"_id": 0}))
        
        # Convert to response models
        companion_responses = [
            AICompanionResponse(
                companion_id=comp["companion_id"],
                personality_id=comp["personality_id"],
                companion_name=comp["companion_name"],
                description=comp["description"],
                image=comp["image"],
                created_at=comp["created_at"],
                is_default=comp.get("is_default", False),
                is_active=comp.get("is_active", True),
                voice_tone=comp.get("voice_tone")
            )
            for comp in companions
        ]
        
        logger.info(f"Retrieved {len(companion_responses)} companions")
        return companion_responses
        
    except Exception as e:
        logger.error(f"Error retrieving companions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve companions: {str(e)}")


@router.get("/companions/{companion_id}", response_model=AICompanionResponse)
async def get_companion_by_id(companion_id: str):
    """
    Get companion details by ID
    
    - **companion_id**: The companion to retrieve
    
    Returns companion details
    """
    try:
        db = get_database()
        
        companion = db.ai_companions.find_one({"companion_id": companion_id}, {"_id": 0})
        
        if not companion:
            raise HTTPException(
                status_code=404,
                detail=f"Companion not found: {companion_id}"
            )
        
        return AICompanionResponse(
            companion_id=companion["companion_id"],
            personality_id=companion["personality_id"],
            companion_name=companion["companion_name"],
            description=companion["description"],
            image=companion["image"],
            created_at=companion["created_at"],
            is_default=companion.get("is_default", False),
            is_active=companion.get("is_active", True),
            voice_tone=companion.get("voice_tone")
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving companion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve companion: {str(e)}")


@router.get("/companions/default/get", response_model=AICompanionResponse)
async def get_default_companion():
    """
    Get the default companion
    
    Returns the companion marked as default (is_default=True)
    """
    try:
        db = get_database()
        
        companion = db.ai_companions.find_one(
            {"is_default": True, "is_active": True}, 
            {"_id": 0}
        )
        
        if not companion:
            raise HTTPException(
                status_code=404,
                detail="No default companion found"
            )
        
        return AICompanionResponse(
            companion_id=companion["companion_id"],
            personality_id=companion["personality_id"],
            companion_name=companion["companion_name"],
            description=companion["description"],
            image=companion["image"],
            created_at=companion["created_at"],
            is_default=companion.get("is_default", False),
            is_active=companion.get("is_active", True),
            voice_tone=companion.get("voice_tone")
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving default companion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve default companion: {str(e)}")


@router.get("/personalities", response_model=List[PersonalityResponse])
async def get_all_personalities(active_only: bool = True):
    """
    Get all personalities
    
    - **active_only**: If True, return only active personalities (default: True)
    
    Returns list of personalities
    """
    try:
        db = get_database()
        
        # Build query filter
        query = {"is_active": True} if active_only else {}
        
        # Fetch personalities
        personalities = list(db.personalities.find(query, {"_id": 0}))
        
        # Convert to response models
        personality_responses = [
            PersonalityResponse(
                personality_id=pers["personality_id"],
                personality_name=pers["personality_name"],
                description=pers["description"],
                prompt_modifier=pers["prompt_modifier"],
                created_at=pers["created_at"],
                is_active=pers.get("is_active", True)
            )
            for pers in personalities
        ]
        
        logger.info(f"Retrieved {len(personality_responses)} personalities")
        return personality_responses
        
    except Exception as e:
        logger.error(f"Error retrieving personalities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve personalities: {str(e)}")


@router.get("/personalities/{personality_id}", response_model=PersonalityResponse)
async def get_personality_by_id(personality_id: str):
    """
    Get personality details by ID
    
    - **personality_id**: The personality to retrieve
    
    Returns personality details
    """
    try:
        db = get_database()
        
        personality = db.personalities.find_one(
            {"personality_id": personality_id},
            {"_id": 0}
        )
        
        if not personality:
            raise HTTPException(
                status_code=404,
                detail=f"Personality not found: {personality_id}"
            )
        
        return PersonalityResponse(
            personality_id=personality["personality_id"],
            personality_name=personality["personality_name"],
            description=personality["description"],
            prompt_modifier=personality["prompt_modifier"],
            created_at=personality["created_at"],
            is_active=personality.get("is_active", True)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving personality: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve personality: {str(e)}")


@router.get("/companions/{companion_id}/personality", response_model=PersonalityResponse)
async def get_companion_personality(companion_id: str):
    """
    Get the personality associated with a specific companion
    
    - **companion_id**: The companion ID
    
    Returns the companion's personality details
    """
    try:
        db = get_database()
        
        # Get companion
        companion = db.ai_companions.find_one({"companion_id": companion_id})
        
        if not companion:
            raise HTTPException(
                status_code=404,
                detail=f"Companion not found: {companion_id}"
            )
        
        # Get personality
        personality = db.personalities.find_one(
            {"personality_id": companion["personality_id"]},
            {"_id": 0}
        )
        
        if not personality:
            raise HTTPException(
                status_code=404,
                detail=f"Personality not found for companion: {companion_id}"
            )
        
        return PersonalityResponse(
            personality_id=personality["personality_id"],
            personality_name=personality["personality_name"],
            description=personality["description"],
            prompt_modifier=personality["prompt_modifier"],
            created_at=personality["created_at"],
            is_active=personality.get("is_active", True)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving companion personality: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve companion personality: {str(e)}"
        )
