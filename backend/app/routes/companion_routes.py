from fastapi import APIRouter, HTTPException
from typing import List
import logging

from app.models.companion import AICompanionCreate, AICompanionUpdate, AICompanionResponse
from app.models.personality import PersonalityResponse
from app.services.companion_service import CompanionService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Companions"])


# ==================== Companion Routes ====================

@router.post("/companions", response_model=AICompanionResponse)
async def create_companion(companion_data: AICompanionCreate):
    """
    Create a new AI companion
    
    - **user_id**: Optional - None for system bot, user_id for user's companion
    - **personality_id**: Required - Reference to personality
    - **companion_name**: Required - Name of the companion
    - **description**: Required - Companion description
    - **image**: Required - Image URL or path
    
    Returns the created companion
    """
    try:
        companion = CompanionService.create_companion(companion_data)
        return companion
    except Exception as e:
        logger.error(f"Error creating companion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create companion: {str(e)}")


@router.get("/companions", response_model=List[AICompanionResponse])
async def get_all_companions(active_only: bool = True):
    """
    Get all AI companions (both system and user companions)
    
    - **active_only**: If True, return only active companions (default: True)
    
    Returns list of all companions
    """
    try:
        companions = CompanionService.get_all_companions(active_only)
        return companions
    except Exception as e:
        logger.error(f"Error retrieving companions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve companions: {str(e)}")


@router.get("/companions/system", response_model=List[AICompanionResponse])
async def get_system_companions(active_only: bool = True):
    """
    Get all system bot companions (user_id is null)
    
    - **active_only**: If True, return only active companions (default: True)
    
    Returns list of system companions
    """
    try:
        companions = CompanionService.get_system_companions(active_only)
        return companions
    except Exception as e:
        logger.error(f"Error retrieving system companions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve system companions: {str(e)}")


@router.get("/companions/user/{user_id}", response_model=List[AICompanionResponse])
async def get_user_companions(user_id: str, active_only: bool = True):
    """
    Get companions that belong to a specific user only (excludes system bots)
    
    - **user_id**: The user ID to filter by
    - **active_only**: If True, return only active companions (default: True)
    
    Returns list of user's companions
    """
    try:
        companions = CompanionService.get_user_companions(user_id, active_only)
        return companions
    except Exception as e:
        logger.error(f"Error retrieving user companions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve user companions: {str(e)}")


@router.get("/companions/available/{user_id}", response_model=List[AICompanionResponse])
async def get_available_companions(user_id: str, active_only: bool = True):
    """
    Get all system companions plus companions belonging to a specific user
    
    - **user_id**: The user ID to include companions for
    - **active_only**: If True, return only active companions (default: True)
    
    Returns list of system companions and user's companions
    """
    try:
        companions = CompanionService.get_user_and_system_companions(user_id, active_only)
        return companions
    except Exception as e:
        logger.error(f"Error retrieving available companions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve available companions: {str(e)}")


@router.get("/companions/default/get", response_model=AICompanionResponse)
async def get_default_companion():
    """
    Get the default companion
    
    Returns the companion marked as default (is_default=True)
    """
    try:
        companion = CompanionService.get_default_companion()
        
        if not companion:
            raise HTTPException(status_code=404, detail="No default companion found")
        
        return companion
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving default companion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve default companion: {str(e)}")


@router.get("/companions/{companion_id}", response_model=AICompanionResponse)
async def get_companion_by_id(companion_id: str):
    """
    Get companion details by ID
    
    - **companion_id**: The companion to retrieve
    
    Returns companion details
    """
    try:
        companion = CompanionService.get_companion_by_id(companion_id)
        
        if not companion:
            raise HTTPException(status_code=404, detail=f"Companion not found: {companion_id}")
        
        return companion
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving companion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve companion: {str(e)}")


@router.put("/companions/{companion_id}", response_model=AICompanionResponse)
async def update_companion(companion_id: str, update_data: AICompanionUpdate):
    """
    Update an existing companion
    
    - **companion_id**: The companion to update
    
    Returns the updated companion
    """
    try:
        companion = CompanionService.update_companion(companion_id, update_data)
        
        if not companion:
            raise HTTPException(status_code=404, detail=f"Companion not found: {companion_id}")
        
        return companion
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating companion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to update companion: {str(e)}")


@router.delete("/companions/{companion_id}")
async def delete_companion(companion_id: str):
    """
    Delete a companion
    
    - **companion_id**: The companion to delete
    
    Returns success message
    """
    try:
        deleted = CompanionService.delete_companion(companion_id)
        
        if not deleted:
            raise HTTPException(status_code=404, detail=f"Companion not found: {companion_id}")
        
        return {"message": f"Companion {companion_id} deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting companion: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete companion: {str(e)}")


@router.get("/companions/{companion_id}/personality", response_model=PersonalityResponse)
async def get_companion_personality(companion_id: str):
    """
    Get the personality associated with a specific companion
    
    - **companion_id**: The companion ID
    
    Returns the companion's personality details
    """
    try:
        personality = CompanionService.get_companion_personality(companion_id)
        
        if not personality:
            raise HTTPException(status_code=404, detail=f"Companion or personality not found: {companion_id}")
        
        return personality
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving companion personality: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve companion personality: {str(e)}")
