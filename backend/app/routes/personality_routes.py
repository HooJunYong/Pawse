from fastapi import APIRouter, HTTPException
from typing import List
import logging

from app.models.personality import PersonalityCreate, PersonalityUpdate, PersonalityResponse
from app.services.personality_service import PersonalityService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Personalities"])


@router.post("/personalities", response_model=PersonalityResponse)
async def create_personality(personality_data: PersonalityCreate):
    """
    Create a new personality
    
    - **user_id**: Optional - None for system personality, user_id for user's personality
    - **personality_name**: Required - Name of the personality
    - **description**: Required - Personality description
    - **prompt_modifier**: Required - Prompt instructions for AI
    
    Returns the created personality
    """
    try:
        personality = PersonalityService.create_personality(personality_data)
        return personality
    except Exception as e:
        logger.error(f"Error creating personality: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create personality: {str(e)}")


@router.get("/personalities", response_model=List[PersonalityResponse])
async def get_all_personalities(active_only: bool = True):
    """
    Get all personalities (both system and user personalities)
    
    - **active_only**: If True, return only active personalities (default: True)
    
    Returns list of all personalities
    """
    try:
        personalities = PersonalityService.get_all_personalities(active_only)
        return personalities
    except Exception as e:
        logger.error(f"Error retrieving personalities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve personalities: {str(e)}")


@router.get("/personalities/system", response_model=List[PersonalityResponse])
async def get_system_personalities(active_only: bool = True):
    """
    Get all system personalities (user_id is null)
    
    - **active_only**: If True, return only active personalities (default: True)
    
    Returns list of system personalities
    """
    try:
        personalities = PersonalityService.get_system_personalities(active_only)
        return personalities
    except Exception as e:
        logger.error(f"Error retrieving system personalities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve system personalities: {str(e)}")


@router.get("/personalities/user/{user_id}", response_model=List[PersonalityResponse])
async def get_user_personalities(user_id: str, active_only: bool = True):
    """
    Get personalities that belong to a specific user only (excludes system personalities)
    
    - **user_id**: The user ID to filter by
    - **active_only**: If True, return only active personalities (default: True)
    
    Returns list of user's personalities
    """
    try:
        personalities = PersonalityService.get_user_personalities(user_id, active_only)
        return personalities
    except Exception as e:
        logger.error(f"Error retrieving user personalities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve user personalities: {str(e)}")


@router.get("/personalities/available/{user_id}", response_model=List[PersonalityResponse])
async def get_available_personalities(user_id: str, active_only: bool = True):
    """
    Get all system personalities plus personalities belonging to a specific user
    
    - **user_id**: The user ID to include personalities for
    - **active_only**: If True, return only active personalities (default: True)
    
    Returns list of system personalities and user's personalities
    """
    try:
        personalities = PersonalityService.get_user_and_system_personalities(user_id, active_only)
        return personalities
    except Exception as e:
        logger.error(f"Error retrieving available personalities: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve available personalities: {str(e)}")


@router.get("/personalities/{personality_id}", response_model=PersonalityResponse)
async def get_personality_by_id(personality_id: str):
    """
    Get personality details by ID
    
    - **personality_id**: The personality to retrieve
    
    Returns personality details
    """
    try:
        personality = PersonalityService.get_personality_by_id(personality_id)
        
        if not personality:
            raise HTTPException(status_code=404, detail=f"Personality not found: {personality_id}")
        
        return personality
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving personality: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve personality: {str(e)}")


@router.put("/personalities/{personality_id}", response_model=PersonalityResponse)
async def update_personality(personality_id: str, update_data: PersonalityUpdate):
    """
    Update an existing personality
    
    - **personality_id**: The personality to update
    
    Returns the updated personality
    """
    try:
        personality = PersonalityService.update_personality(personality_id, update_data)
        
        if not personality:
            raise HTTPException(status_code=404, detail=f"Personality not found: {personality_id}")
        
        return personality
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating personality: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to update personality: {str(e)}")


@router.delete("/personalities/{personality_id}")
async def delete_personality(personality_id: str):
    """
    Delete a personality
    
    - **personality_id**: The personality to delete
    
    Returns success message
    """
    try:
        deleted = PersonalityService.delete_personality(personality_id)
        
        if not deleted:
            raise HTTPException(status_code=404, detail=f"Personality not found: {personality_id}")
        
        return {"message": f"Personality {personality_id} deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting personality: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete personality: {str(e)}")
