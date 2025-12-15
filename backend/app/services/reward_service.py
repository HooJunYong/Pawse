"""
Reward Service
Handles reward redemption, user inventory, and available rewards
"""
import logging
import uuid
from datetime import datetime
from typing import List, Dict, Any, Optional

from app.models.database import get_database
from app.models.reward import RewardResponse, RewardType
from app.models.user_reward import UserRewardResponse, UserRewardWithDetails

logger = logging.getLogger(__name__)


class RewardService:
    """Service for managing rewards and user redemptions"""

    @staticmethod
    def _generate_user_reward_id() -> str:
        """Generate unique user_reward_id using UUID."""
        return str(uuid.uuid4())

    # ==================== Get All Rewards ====================

    @staticmethod
    def get_all_rewards() -> List[Dict[str, Any]]:
        """
        Get all active rewards from the rewards collection.
        
        Returns:
            List of all active rewards
        """
        db = get_database()
        
        rewards = list(db.rewards.find(
            {"is_active": True},
            {"_id": 0}
        ))
        
        logger.info(f"Retrieved {len(rewards)} active rewards")
        return rewards

    # ==================== Get User Inventory ====================

    @staticmethod
    def get_user_inventory(user_id: str) -> List[Dict[str, Any]]:
        """
        Get all rewards redeemed by a user with full reward details.
        Joins user_rewards with rewards collection.
        
        Args:
            user_id: The user ID
            
        Returns:
            List of redeemed rewards with details
        """
        db = get_database()
        
        # Aggregation pipeline to join user_rewards with rewards
        pipeline = [
            {"$match": {"user_id": user_id}},
            {
                "$lookup": {
                    "from": "rewards",
                    "localField": "reward_id",
                    "foreignField": "reward_id",
                    "as": "reward_details"
                }
            },
            {"$unwind": "$reward_details"},
            {
                "$project": {
                    "_id": 0,
                    "user_reward_id": 1,
                    "user_id": 1,
                    "reward_id": 1,
                    "redeemed_date": 1,
                    "reward_name": "$reward_details.reward_name",
                    "reward_description": "$reward_details.description",
                    "reward_type": "$reward_details.reward_type",
                    "image_path": "$reward_details.image_path"
                }
            },
            {"$sort": {"redeemed_date": -1}}
        ]
        
        inventory = list(db.user_rewards.aggregate(pipeline))
        
        logger.info(f"Retrieved {len(inventory)} redeemed rewards for user {user_id}")
        return inventory

    # ==================== Get Available Rewards ====================

    @staticmethod
    def get_available_rewards(user_id: str) -> List[Dict[str, Any]]:
        """
        Get all rewards that are active and haven't been redeemed by the user.
        
        Args:
            user_id: The user ID
            
        Returns:
            List of available rewards (not yet redeemed)
        """
        db = get_database()
        
        # Get all reward_ids that user has already redeemed
        redeemed_reward_ids = [
            doc["reward_id"] 
            for doc in db.user_rewards.find(
                {"user_id": user_id},
                {"reward_id": 1, "_id": 0}
            )
        ]
        
        # Get all active rewards that are NOT in the redeemed list
        available_rewards = list(db.rewards.find(
            {
                "is_active": True,
                "reward_id": {"$nin": redeemed_reward_ids}
            },
            {"_id": 0}
        ))
        
        logger.info(f"Found {len(available_rewards)} available rewards for user {user_id}")
        return available_rewards

    # ==================== Redeem Reward ====================

    @staticmethod
    def redeem_reward(user_id: str, reward_id: str) -> Dict[str, Any]:
        """
        Redeem a reward for a user.
        Checks if reward exists, is active, user has enough points, and hasn't already redeemed.
        Deducts points and creates user_reward record.
        
        Args:
            user_id: The user ID
            reward_id: The reward ID to redeem
            
        Returns:
            Dict with success status and redeemed reward details
            
        Raises:
            ValueError: If reward not found, user has insufficient points, or already redeemed
        """
        db = get_database()
        
        # 1. Check if reward exists and is active
        reward = db.rewards.find_one({"reward_id": reward_id, "is_active": True})
        if not reward:
            raise ValueError(f"Reward {reward_id} not found or is inactive")
        
        # 2. Check if user has already redeemed this reward
        existing_redemption = db.user_rewards.find_one({
            "user_id": user_id,
            "reward_id": reward_id
        })
        if existing_redemption:
            raise ValueError(f"Reward {reward_id} has already been redeemed by this user")
        
        # 3. Get user's current points
        user_profile = db.user_profile.find_one({"user_id": user_id})
        if not user_profile:
            raise ValueError(f"User profile not found for {user_id}")
        
        current_points = user_profile.get("current_points", 0)
        reward_cost = reward["cost"]
        
        # 4. Check if user has enough points
        if current_points < reward_cost:
            raise ValueError(
                f"Insufficient points. Required: {reward_cost}, Available: {current_points}"
            )
        
        # 5. Deduct points from user
        new_points = current_points - reward_cost
        db.user_profile.update_one(
            {"user_id": user_id},
            {"$set": {"current_points": new_points}}
        )
        
        # 6. Create user_reward record
        user_reward_id = RewardService._generate_user_reward_id()
        user_reward_doc = {
            "user_reward_id": user_reward_id,
            "user_id": user_id,
            "reward_id": reward_id,
            "redeemed_date": datetime.utcnow()
        }
        
        db.user_rewards.insert_one(user_reward_doc)
        
        logger.info(
            f"User {user_id} redeemed reward {reward_id}. "
            f"Points: {current_points} -> {new_points}"
        )
        
        return {
            "success": True,
            "message": "Reward redeemed successfully",
            "user_reward_id": user_reward_id,
            "reward_name": reward["reward_name"],
            "points_deducted": reward_cost,
            "remaining_points": new_points
        }

    # ==================== Get Available Skins ====================

    @staticmethod
    def get_available_skins(user_id: str) -> List[Dict[str, Any]]:
        """
        Get all companion skins that the user can use (has redeemed).
        Returns list of companion_skin rewards from user's inventory.
        
        Args:
            user_id: The user ID
            
        Returns:
            List of companion skin rewards the user owns
        """
        db = get_database()
        
        # Aggregation pipeline to get only companion_skin type rewards
        pipeline = [
            {"$match": {"user_id": user_id}},
            {
                "$lookup": {
                    "from": "rewards",
                    "localField": "reward_id",
                    "foreignField": "reward_id",
                    "as": "reward_details"
                }
            },
            {"$unwind": "$reward_details"},
            {
                "$match": {
                    "reward_details.reward_type": RewardType.COMPANION_SKIN.value
                }
            },
            {
                "$project": {
                    "_id": 0,
                    "reward_id": 1,
                    "reward_name": "$reward_details.reward_name",
                    "image_path": "$reward_details.image_path",
                    "redeemed_date": 1
                }
            },
            {"$sort": {"redeemed_date": -1}}
        ]
        
        skins = list(db.user_rewards.aggregate(pipeline))
        
        logger.info(f"Retrieved {len(skins)} available skins for user {user_id}")
        return skins
