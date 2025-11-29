"""
Companion Service
Handles all business logic for AI companions
"""
import uuid
import logging
from datetime import datetime
from typing import List, Optional

from app.models.companion import AICompanion, AICompanionCreate, AICompanionUpdate, AICompanionResponse
from app.models.personality import PersonalityResponse
from app.models.database import get_database

# Configure logging
logger = logging.getLogger(__name__)


class CompanionService:
    """Service class for companion operations"""

    @staticmethod
    def _companion_to_response(companion: dict) -> AICompanionResponse:
        """Convert database companion document to response model"""
        return AICompanionResponse(
            companion_id=companion["companion_id"],
            user_id=companion.get("user_id"),
            personality_id=companion["personality_id"],
            companion_name=companion["companion_name"],
            description=companion["description"],
            image=companion["image"],
            created_at=companion["created_at"],
            is_default=companion.get("is_default", False),
            is_active=companion.get("is_active", True),
            voice_tone=companion.get("voice_tone")
        )

    @staticmethod
    def create_companion(companion_data: AICompanionCreate) -> AICompanionResponse:
        """
        Create a new AI companion
        
        Args:
            companion_data: The companion data to create
            
        Returns:
            The created companion response
        """
        db = get_database()
        
        # Generate UUID for companion_id
        companion_id = str(uuid.uuid4())
        
        # Build companion document
        companion_doc = {
            "companion_id": companion_id,
            "user_id": companion_data.user_id,  # None for system bot
            "personality_id": companion_data.personality_id,
            "companion_name": companion_data.companion_name,
            "description": companion_data.description,
            "image": companion_data.image,
            "created_at": datetime.utcnow(),
            "is_default": companion_data.is_default,
            "is_active": companion_data.is_active,
            "voice_tone": companion_data.voice_tone
        }
        
        # Insert into database
        db.ai_companions.insert_one(companion_doc)
        
        logger.info(f"Created new companion: {companion_id}")
        return CompanionService._companion_to_response(companion_doc)

    @staticmethod
    def get_all_companions(active_only: bool = True) -> List[AICompanionResponse]:
        """
        Get all AI companions (both system and user companions)
        
        Args:
            active_only: If True, return only active companions
            
        Returns:
            List of all companions
        """
        db = get_database()
        
        query = {"is_active": True} if active_only else {}
        companions = list(db.ai_companions.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(companions)} companions")
        return [CompanionService._companion_to_response(comp) for comp in companions]

    @staticmethod
    def get_system_companions(active_only: bool = True) -> List[AICompanionResponse]:
        """
        Get all system bot companions (user_id is null)
        
        Args:
            active_only: If True, return only active companions
            
        Returns:
            List of system companions
        """
        db = get_database()
        
        query = {"user_id": None}
        if active_only:
            query["is_active"] = True
            
        companions = list(db.ai_companions.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(companions)} system companions")
        return [CompanionService._companion_to_response(comp) for comp in companions]

    @staticmethod
    def get_user_companions(user_id: str, active_only: bool = True) -> List[AICompanionResponse]:
        """
        Get companions that belong to a specific user only (excludes system bots)
        
        Args:
            user_id: The user ID to filter by
            active_only: If True, return only active companions
            
        Returns:
            List of user's companions
        """
        db = get_database()
        
        query = {"user_id": user_id}
        if active_only:
            query["is_active"] = True
            
        companions = list(db.ai_companions.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(companions)} companions for user {user_id}")
        return [CompanionService._companion_to_response(comp) for comp in companions]

    @staticmethod
    def get_user_and_system_companions(user_id: str, active_only: bool = True) -> List[AICompanionResponse]:
        """
        Get all system companions plus companions belonging to a specific user
        
        Args:
            user_id: The user ID to include companions for
            active_only: If True, return only active companions
            
        Returns:
            List of system companions and user's companions
        """
        db = get_database()
        
        query = {
            "$or": [
                {"user_id": None},      # System bots
                {"user_id": user_id}    # User's companions
            ]
        }
        if active_only:
            query["is_active"] = True
            
        companions = list(db.ai_companions.find(query, {"_id": 0}))
        
        logger.info(f"Retrieved {len(companions)} companions (system + user {user_id})")
        return [CompanionService._companion_to_response(comp) for comp in companions]

    @staticmethod
    def get_companion_by_id(companion_id: str) -> Optional[AICompanionResponse]:
        """
        Get a specific companion by ID
        
        Args:
            companion_id: The companion ID to retrieve
            
        Returns:
            The companion if found, None otherwise
        """
        db = get_database()
        
        companion = db.ai_companions.find_one({"companion_id": companion_id}, {"_id": 0})
        
        if not companion:
            return None
            
        return CompanionService._companion_to_response(companion)

    @staticmethod
    def get_default_companion() -> Optional[AICompanionResponse]:
        """
        Get the default companion
        
        Returns:
            The default companion if found, None otherwise
        """
        db = get_database()
        
        companion = db.ai_companions.find_one(
            {"is_default": True, "is_active": True},
            {"_id": 0}
        )
        
        if not companion:
            return None
            
        return CompanionService._companion_to_response(companion)

    @staticmethod
    def update_companion(companion_id: str, update_data: AICompanionUpdate) -> Optional[AICompanionResponse]:
        """
        Update an existing companion
        
        Args:
            companion_id: The companion ID to update
            update_data: The update data
            
        Returns:
            The updated companion if found, None otherwise
        """
        db = get_database()
        
        # Check if companion exists
        existing = db.ai_companions.find_one({"companion_id": companion_id})
        if not existing:
            return None
        
        # Build update document with only non-None fields
        update_doc = {k: v for k, v in update_data.dict().items() if v is not None}
        
        if update_doc:
            db.ai_companions.update_one(
                {"companion_id": companion_id},
                {"$set": update_doc}
            )
            
        # Fetch updated companion
        updated = db.ai_companions.find_one({"companion_id": companion_id}, {"_id": 0})
        
        logger.info(f"Updated companion: {companion_id}")
        return CompanionService._companion_to_response(updated)

    @staticmethod
    def delete_companion(companion_id: str) -> bool:
        """
        Delete a companion
        
        Args:
            companion_id: The companion ID to delete
            
        Returns:
            True if deleted, False if not found
        """
        db = get_database()
        
        result = db.ai_companions.delete_one({"companion_id": companion_id})
        
        if result.deleted_count > 0:
            logger.info(f"Deleted companion: {companion_id}")
            return True
        return False

    @staticmethod
    def get_companion_personality(companion_id: str) -> Optional[PersonalityResponse]:
        """
        Get the personality associated with a companion
        
        Args:
            companion_id: The companion ID
            
        Returns:
            The personality if found, None otherwise
        """
        db = get_database()
        
        # Get companion
        companion = db.ai_companions.find_one({"companion_id": companion_id})
        if not companion:
            return None
        
        # Get personality
        personality = db.personalities.find_one(
            {"personality_id": companion["personality_id"]},
            {"_id": 0}
        )
        
        if not personality:
            return None
        
        return PersonalityResponse(
            personality_id=personality["personality_id"],
            personality_name=personality["personality_name"],
            description=personality["description"],
            prompt_modifier=personality["prompt_modifier"],
            created_at=personality["created_at"],
            is_active=personality.get("is_active", True)
        )
