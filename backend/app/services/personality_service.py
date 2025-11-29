"""
Personality Service
Handles all business logic for AI personalities
"""
import uuid
import logging
from datetime import datetime
from typing import List, Optional

from app.models.personality import PersonalityCreate, PersonalityUpdate, PersonalityResponse
from app.models.database import get_database

# Configure logging
logger = logging.getLogger(__name__)


class PersonalityService:
    """Service class for personality operations"""

    @staticmethod
    def _personality_to_response(personality: dict) -> PersonalityResponse:
        """Convert database personality document to response model"""
        return PersonalityResponse(
            personality_id=personality["personality_id"],
            user_id=personality.get("user_id"),
            personality_name=personality["personality_name"],
            description=personality["description"],
            prompt_modifier=personality["prompt_modifier"],
            created_at=personality["created_at"],
            is_active=personality.get("is_active", True)
        )

    @staticmethod
    def create_personality(personality_data: PersonalityCreate) -> PersonalityResponse:
        """
        Create a new personality
        
        Args:
            personality_data: The personality data to create
            
        Returns:
            The created personality response
        """
        db = get_database()
        
        # Generate UUID for personality_id
        personality_id = str(uuid.uuid4())
        
        # Build personality document
        personality_doc = {
            "personality_id": personality_id,
            "user_id": personality_data.user_id,  # None for system personality
            "personality_name": personality_data.personality_name,
            "description": personality_data.description,
            "prompt_modifier": personality_data.prompt_modifier,
            "created_at": datetime.utcnow(),
            "is_active": personality_data.is_active
        }
        
        # Insert into database
        db.personalities.insert_one(personality_doc)
        
        logger.info(f"Created new personality: {personality_id}")
        return PersonalityService._personality_to_response(personality_doc)

    @staticmethod
    def get_all_personalities(active_only: bool = True) -> List[PersonalityResponse]:
        """
        Get all personalities (both system and user personalities)
        
        Args:
            active_only: If True, return only active personalities
            
        Returns:
            List of all personalities
        """
        db = get_database()
        
        query = {"is_active": True} if active_only else {}
        personalities = list(db.personalities.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(personalities)} personalities")
        return [PersonalityService._personality_to_response(pers) for pers in personalities]

    @staticmethod
    def get_system_personalities(active_only: bool = True) -> List[PersonalityResponse]:
        """
        Get all system personalities (user_id is null)
        
        Args:
            active_only: If True, return only active personalities
            
        Returns:
            List of system personalities
        """
        db = get_database()
        
        query = {"user_id": None}
        if active_only:
            query["is_active"] = True
            
        personalities = list(db.personalities.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(personalities)} system personalities")
        return [PersonalityService._personality_to_response(pers) for pers in personalities]

    @staticmethod
    def get_user_personalities(user_id: str, active_only: bool = True) -> List[PersonalityResponse]:
        """
        Get personalities that belong to a specific user only (excludes system personalities)
        
        Args:
            user_id: The user ID to filter by
            active_only: If True, return only active personalities
            
        Returns:
            List of user's personalities
        """
        db = get_database()
        
        query = {"user_id": user_id}
        if active_only:
            query["is_active"] = True
            
        personalities = list(db.personalities.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(personalities)} personalities for user {user_id}")
        return [PersonalityService._personality_to_response(pers) for pers in personalities]

    @staticmethod
    def get_user_and_system_personalities(user_id: str, active_only: bool = True) -> List[PersonalityResponse]:
        """
        Get all system personalities plus personalities belonging to a specific user
        
        Args:
            user_id: The user ID to include personalities for
            active_only: If True, return only active personalities
            
        Returns:
            List of system personalities and user's personalities
        """
        db = get_database()
        
        query = {
            "$or": [
                {"user_id": None},      # System personalities
                {"user_id": user_id}    # User's personalities
            ]
        }
        if active_only:
            query["is_active"] = True
            
        personalities = list(db.personalities.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(personalities)} personalities (system + user {user_id})")
        return [PersonalityService._personality_to_response(pers) for pers in personalities]

    @staticmethod
    def get_personality_by_id(personality_id: str) -> Optional[PersonalityResponse]:
        """
        Get a specific personality by ID
        
        Args:
            personality_id: The personality ID to retrieve
            
        Returns:
            The personality if found, None otherwise
        """
        db = get_database()
        
        personality = db.personalities.find_one(
            {"personality_id": personality_id},
            {"_id": 0}
        )
        
        if not personality:
            return None
            
        return PersonalityService._personality_to_response(personality)

    @staticmethod
    def update_personality(personality_id: str, update_data: PersonalityUpdate) -> Optional[PersonalityResponse]:
        """
        Update an existing personality
        
        Args:
            personality_id: The personality ID to update
            update_data: The update data
            
        Returns:
            The updated personality if found, None otherwise
        """
        db = get_database()
        
        # Check if personality exists
        existing = db.personalities.find_one({"personality_id": personality_id})
        if not existing:
            return None
        
        # Build update document with only non-None fields
        update_doc = {k: v for k, v in update_data.dict().items() if v is not None}
        
        if update_doc:
            db.personalities.update_one(
                {"personality_id": personality_id},
                {"$set": update_doc}
            )
            
        # Fetch updated personality
        updated = db.personalities.find_one({"personality_id": personality_id}, {"_id": 0})
        
        logger.info(f"Updated personality: {personality_id}")
        return PersonalityService._personality_to_response(updated)

    @staticmethod
    def delete_personality(personality_id: str) -> bool:
        """
        Delete a personality
        
        Args:
            personality_id: The personality ID to delete
            
        Returns:
            True if deleted, False if not found
        """
        db = get_database()
        
        result = db.personalities.delete_one({"personality_id": personality_id})
        
        if result.deleted_count > 0:
            logger.info(f"Deleted personality: {personality_id}")
            return True
        return False
