"""
Drift Bottle Service
Handles all business logic for drift bottles, pickups, and replies
"""
import uuid
import logging
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

from app.models.drift_bottle import (
    DriftBottle, DriftBottleCreate, DriftBottleResponse, BottleStatus
)
from app.models.bottle_pickup import (
    BottlePickup, BottlePickupCreate, BottlePickupResponse, PickupAction
)
from app.models.bottle_reply import (
    BottleReply, BottleReplyCreate, BottleReplyResponse
)
from app.models.database import get_database
from app.services.activity_service import ActivityService

# Configure logging
logger = logging.getLogger(__name__)


class DriftBottleService:
    """Service class for drift bottle operations"""

    # ==================== Helper Methods ====================

    @staticmethod
    def _generate_bottle_id() -> str:
        """Generate a unique bottle ID using UUID"""
        return str(uuid.uuid4())

    @staticmethod
    def _generate_pickup_id() -> str:
        """Generate a unique pickup ID using UUID"""
        return str(uuid.uuid4())

    @staticmethod
    def _generate_reply_id() -> str:
        """Generate a unique reply ID using UUID"""
        return str(uuid.uuid4())

    @staticmethod
    def _bottle_to_response(bottle: dict) -> DriftBottleResponse:
        """Convert database bottle document to response model"""
        return DriftBottleResponse(
            bottle_id=bottle["bottle_id"],
            user_id=bottle["user_id"],
            message=bottle["message"],
            created_at=bottle["created_at"],
            status=bottle["status"],
            is_active=bottle["is_active"]
        )

    @staticmethod
    def _pickup_to_response(pickup: dict) -> BottlePickupResponse:
        """Convert database pickup document to response model"""
        return BottlePickupResponse(
            pickup_id=pickup["pickup_id"],
            bottle_id=pickup["bottle_id"],
            user_id=pickup["user_id"],
            pickup_time=pickup["pickup_time"],
            action_taken=pickup["action_taken"]
        )

    @staticmethod
    def _reply_to_response(reply: dict) -> BottleReplyResponse:
        """Convert database reply document to response model"""
        return BottleReplyResponse(
            reply_id=reply["reply_id"],
            bottle_id=reply["bottle_id"],
            user_id=reply["user_id"],
            reply_content=reply["reply_content"],
            reply_time=reply["reply_time"]
        )

    # ==================== Core Methods ====================

    @staticmethod
    def throw_bottle(user_id: str, message: str) -> DriftBottleResponse:
        """
        Create a new drift bottle and throw it into the ocean
        
        Args:
            user_id: The user who is throwing the bottle
            message: The message content in the bottle
            
        Returns:
            The created bottle response
        """
        db = get_database()

        # Generate bottle ID
        bottle_id = DriftBottleService._generate_bottle_id()

        # Build bottle document
        bottle_doc = {
            "bottle_id": bottle_id,
            "user_id": user_id,
            "message": message,
            "created_at": datetime.utcnow(),
            "status": BottleStatus.AVAILABLE.value,
            "is_active": True
        }

        # Insert into database
        db.drift_bottles.insert_one(bottle_doc)

        logger.info(f"User {user_id} threw bottle {bottle_id}")

        try:
            track_result = ActivityService.track_activity(
                user_id=user_id,
                action_key="throw_bottle"
            )
            if track_result:
                logger.info(f"Tracked throw_bottle activity for user {user_id}")
        except Exception as e:
            logger.error(f"Error tracking throw_bottle activity for user {user_id}: {e}")

        return DriftBottleService._bottle_to_response(bottle_doc)

    @staticmethod
    def pickup_bottle(user_id: str) -> Optional[DriftBottleResponse]:
        """
        Pick up a random available bottle from the ocean
        
        Args:
            user_id: The user who is picking up the bottle
            
        Returns:
            The picked up bottle if found, None otherwise
        """
        db = get_database()

        # Get all bottle_ids that this user has already picked up
        user_pickups = db.bottle_pickups.find(
            {"user_id": user_id},
            {"bottle_id": 1}
        )
        picked_up_bottle_ids = [p["bottle_id"] for p in user_pickups]

        # Find a random available bottle that:
        # - status is 'available'
        # - is_active is True
        # - user_id is not the current user (not own bottle)
        # - bottle_id is not in the list of already picked up bottles
        pipeline = [
            {
                "$match": {
                    "status": BottleStatus.AVAILABLE.value,
                    "is_active": True,
                    "user_id": {"$ne": user_id},
                    "bottle_id": {"$nin": picked_up_bottle_ids}
                }
            },
            {"$sample": {"size": 1}}  # Get one random bottle
        ]

        result = list(db.drift_bottles.aggregate(pipeline))

        if not result:
            logger.info(f"No available bottle found for user {user_id}")
            return None

        bottle = result[0]

        # Update bottle status to 'picked_up'
        db.drift_bottles.update_one(
            {"bottle_id": bottle["bottle_id"]},
            {"$set": {"status": BottleStatus.PICKED_UP.value}}
        )

        # Create bottle pickup record
        pickup_id = DriftBottleService._generate_pickup_id()
        pickup_doc = {
            "pickup_id": pickup_id,
            "bottle_id": bottle["bottle_id"],
            "user_id": user_id,
            "pickup_time": datetime.utcnow(),
            "action_taken": PickupAction.PENDING.value
        }

        db.bottle_pickups.insert_one(pickup_doc)

        # Update the bottle object with new status before returning
        bottle["status"] = BottleStatus.PICKED_UP.value

        logger.info(f"User {user_id} picked up bottle {bottle['bottle_id']}")
        return DriftBottleService._bottle_to_response(bottle)

    @staticmethod
    def pass_bottle(user_id: str, bottle_id: str) -> bool:
        """
        Pass a bottle back into the ocean without replying
        
        Args:
            user_id: The user who is passing the bottle
            bottle_id: The bottle to pass
            
        Returns:
            True if successful, raises exception otherwise
        """
        db = get_database()

        # Validate that this user has a 'pending' action for this bottle
        pickup = db.bottle_pickups.find_one({
            "bottle_id": bottle_id,
            "user_id": user_id,
            "action_taken": PickupAction.PENDING.value
        })

        if not pickup:
            raise ValueError("You don't have a pending action for this bottle")

        # Update action_taken to 'passed'
        db.bottle_pickups.update_one(
            {"pickup_id": pickup["pickup_id"]},
            {"$set": {"action_taken": PickupAction.PASSED.value}}
        )

        # Update bottle status back to 'available'
        db.drift_bottles.update_one(
            {"bottle_id": bottle_id},
            {"$set": {"status": BottleStatus.AVAILABLE.value}}
        )

        logger.info(f"User {user_id} passed bottle {bottle_id}")
        return True

    @staticmethod
    def reply_to_bottle(user_id: str, bottle_id: str, reply_content: str) -> BottleReplyResponse:
        """
        Reply to a bottle
        
        Args:
            user_id: The user who is replying
            bottle_id: The bottle to reply to
            reply_content: The reply message content
            
        Returns:
            The created reply response
        """
        db = get_database()

        # Validate that this user has a 'pending' action for this bottle
        pickup = db.bottle_pickups.find_one({
            "bottle_id": bottle_id,
            "user_id": user_id,
            "action_taken": PickupAction.PENDING.value
        })

        if not pickup:
            raise ValueError("You don't have a pending action for this bottle")

        # Create bottle reply record
        reply_id = DriftBottleService._generate_reply_id()
        reply_doc = {
            "reply_id": reply_id,
            "bottle_id": bottle_id,
            "user_id": user_id,
            "reply_content": reply_content,
            "reply_time": datetime.utcnow()
        }

        db.bottle_replies.insert_one(reply_doc)

        # Update action_taken to 'replied'
        db.bottle_pickups.update_one(
            {"pickup_id": pickup["pickup_id"]},
            {"$set": {"action_taken": PickupAction.REPLIED.value}}
        )

        # Update bottle status back to 'available'
        db.drift_bottles.update_one(
            {"bottle_id": bottle_id},
            {"$set": {"status": BottleStatus.AVAILABLE.value}}
        )

        logger.info(f"User {user_id} replied to bottle {bottle_id}")

        try:
            track_result = ActivityService.track_activity(
                user_id=user_id,
                action_key="reply_bottle"
            )
            if track_result:
                logger.info(f"Tracked reply_bottle activity for user {user_id}")
        except Exception as e:
            logger.error(f"Error tracking reply_bottle activity for user {user_id}: {e}")
            
        return DriftBottleService._reply_to_response(reply_doc)

    @staticmethod
    def get_thrown_history(user_id: str) -> List[DriftBottleResponse]:
        """
        Get all bottles that the user has thrown
        
        Args:
            user_id: The user ID
            
        Returns:
            List of bottles thrown by the user
        """
        db = get_database()

        bottles = list(db.drift_bottles.find(
            {"user_id": user_id},
            {"_id": 0}
        ).sort("created_at", -1))

        logger.info(f"Retrieved {len(bottles)} thrown bottles for user {user_id}")
        return [DriftBottleService._bottle_to_response(b) for b in bottles]

    @staticmethod
    def get_pickup_history(user_id: str) -> List[Dict[str, Any]]:
        """
        Get all bottles that the user has picked up with pickup details
        
        Args:
            user_id: The user ID
            
        Returns:
            List of pickup records with bottle details
        """
        db = get_database()

        # Get all pickups for this user
        pickups = list(db.bottle_pickups.find(
            {"user_id": user_id},
            {"_id": 0}
        ).sort("pickup_time", -1))

        # Enrich with bottle details
        result = []
        for pickup in pickups:
            bottle = db.drift_bottles.find_one(
                {"bottle_id": pickup["bottle_id"]},
                {"_id": 0}
            )
            if bottle:
                result.append({
                    "pickup": DriftBottleService._pickup_to_response(pickup),
                    "bottle": DriftBottleService._bottle_to_response(bottle)
                })

        logger.info(f"Retrieved {len(result)} pickup history for user {user_id}")
        return result

    @staticmethod
    def get_bottle_detail(bottle_id: str) -> Optional[Dict[str, Any]]:
        """
        Get bottle message and all replies
        
        Args:
            bottle_id: The bottle ID
            
        Returns:
            Bottle details with message and replies
        """
        db = get_database()

        # Get bottle
        bottle = db.drift_bottles.find_one(
            {"bottle_id": bottle_id},
            {"_id": 0}
        )

        if not bottle:
            return None

        # Get all replies for this bottle
        replies = list(db.bottle_replies.find(
            {"bottle_id": bottle_id},
            {"_id": 0}
        ).sort("reply_time", 1))

        logger.info(f"Retrieved bottle {bottle_id} with {len(replies)} replies")
        return {
            "bottle": DriftBottleService._bottle_to_response(bottle),
            "replies": [DriftBottleService._reply_to_response(r) for r in replies]
        }

    @staticmethod
    def check_stuck_bottles() -> int:
        """
        Check for bottles that have been pending for more than 24 hours
        and release them back to the ocean
        
        Returns:
            Number of bottles released
        """
        db = get_database()

        # Find pickups that are pending for more than 24 hours
        cutoff_time = datetime.utcnow() - timedelta(hours=24)

        stuck_pickups = list(db.bottle_pickups.find({
            "action_taken": PickupAction.PENDING.value,
            "pickup_time": {"$lt": cutoff_time}
        }))

        count = 0
        for pickup in stuck_pickups:
            # Update action_taken to 'timeout'
            db.bottle_pickups.update_one(
                {"pickup_id": pickup["pickup_id"]},
                {"$set": {"action_taken": PickupAction.TIMEOUT.value}}
            )

            # Update bottle status back to 'available'
            db.drift_bottles.update_one(
                {"bottle_id": pickup["bottle_id"]},
                {"$set": {"status": BottleStatus.AVAILABLE.value}}
            )
            count += 1

        logger.info(f"Released {count} stuck bottles back to the ocean")
        return count

    @staticmethod
    def expire_old_bottles() -> int:
        """
        Expire bottles that have been in the ocean for more than 14 days
        
        Returns:
            Number of bottles expired
        """
        db = get_database()

        # Find bottles older than 14 days
        cutoff_time = datetime.utcnow() - timedelta(days=14)

        result = db.drift_bottles.update_many(
            {
                "created_at": {"$lt": cutoff_time},
                "is_active": True,
                "status": {"$ne": BottleStatus.COMPLETED.value}
            },
            {
                "$set": {
                    "status": BottleStatus.EXPIRED.value,
                    "is_active": False
                }
            }
        )

        logger.info(f"Expired {result.modified_count} old bottles")
        return result.modified_count

    @staticmethod
    def end_bottle(user_id: str, bottle_id: str) -> bool:
        """
        Manually end a bottle (only the owner can do this)
        
        Args:
            user_id: The user who is ending the bottle
            bottle_id: The bottle to end
            
        Returns:
            True if successful, raises exception otherwise
        """
        db = get_database()

        # Validate that this user owns the bottle
        bottle = db.drift_bottles.find_one({
            "bottle_id": bottle_id,
            "user_id": user_id
        })

        if not bottle:
            raise ValueError("You don't own this bottle or it doesn't exist")

        # Update bottle status to 'completed' and is_active to False
        db.drift_bottles.update_one(
            {"bottle_id": bottle_id},
            {
                "$set": {
                    "status": BottleStatus.COMPLETED.value,
                    "is_active": False
                }
            }
        )

        logger.info(f"User {user_id} ended bottle {bottle_id}")
        return True
