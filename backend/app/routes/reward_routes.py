"""
Reward Routes
API endpoints for rewards, redemptions, and user inventory
"""
from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from pydantic import BaseModel
import logging

from app.services.reward_service import RewardService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/rewards", tags=["Rewards"])


# ==================== Request Models ====================

class RedeemRewardRequest(BaseModel):
    """Request model for redeeming a reward"""
    user_id: str
    reward_id: str


# ==================== Get All Rewards ====================

@router.get("/all")
async def get_all_rewards():
    """
    Get all active rewards available in the system.
    
    Returns:
        List of all active rewards
    """
    try:
        rewards = RewardService.get_all_rewards()
        return {
            "success": True,
            "count": len(rewards),
            "rewards": rewards
        }
    except Exception as e:
        logger.error(f"Error getting all rewards: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve rewards: {str(e)}"
        )


# ==================== Get User Inventory ====================

@router.get("/inventory/{user_id}")
async def get_user_inventory(user_id: str):
    """
    Get all rewards that a user has redeemed (user's inventory).
    Includes full reward details.
    
    - **user_id**: The user ID
    
    Returns:
        List of redeemed rewards with details
    """
    try:
        inventory = RewardService.get_user_inventory(user_id)
        return {
            "success": True,
            "user_id": user_id,
            "count": len(inventory),
            "inventory": inventory
        }
    except Exception as e:
        logger.error(f"Error getting inventory for user {user_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve user inventory: {str(e)}"
        )


# ==================== Get Available Rewards ====================

@router.get("/available/{user_id}")
async def get_available_rewards(user_id: str):
    """
    Get all rewards that are available and haven't been redeemed by the user.
    
    - **user_id**: The user ID
    
    Returns:
        List of rewards the user can still redeem
    """
    try:
        available_rewards = RewardService.get_available_rewards(user_id)
        return {
            "success": True,
            "user_id": user_id,
            "count": len(available_rewards),
            "available_rewards": available_rewards
        }
    except Exception as e:
        logger.error(f"Error getting available rewards for user {user_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve available rewards: {str(e)}"
        )


# ==================== Redeem Reward ====================

@router.post("/redeem")
async def redeem_reward(request: RedeemRewardRequest):
    """
    Redeem a reward for a user.
    Checks if user has enough points and hasn't already redeemed the reward.
    Deducts points and adds reward to user's inventory.
    
    - **user_id**: The user ID
    - **reward_id**: The reward ID to redeem
    
    Returns:
        Redemption details and remaining points
    """
    try:
        result = RewardService.redeem_reward(
            user_id=request.user_id,
            reward_id=request.reward_id
        )
        return result
    except ValueError as e:
        # Business logic errors (insufficient points, already redeemed, etc.)
        logger.warning(f"Redemption validation failed: {str(e)}")
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error redeeming reward: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to redeem reward: {str(e)}"
        )


# ==================== Get Available Skins ====================

@router.get("/skins/{user_id}")
async def get_available_skins(user_id: str):
    """
    Get all companion skins that the user can use (has redeemed).
    Only returns companion_skin type rewards from user's inventory.
    
    - **user_id**: The user ID
    
    Returns:
        List of companion skin rewards the user owns
    """
    try:
        skins = RewardService.get_available_skins(user_id)
        return {
            "success": True,
            "user_id": user_id,
            "count": len(skins),
            "skins": skins
        }
    except Exception as e:
        logger.error(f"Error getting available skins for user {user_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve available skins: {str(e)}"
        )
