from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


class RewardType(str, Enum):
    """Enum for reward types"""
    COMPANION_SKIN = "companion_skin"
    VOUCHER = "voucher"


class Reward(BaseModel):
    """Reward model for MongoDB collection - defines items users can redeem with points"""
    reward_id: str = Field(..., description="Primary Key (REW001, REW002, ...)")
    reward_name: str = Field(..., description="Display name of the reward")
    description: str = Field(..., description="Description of the reward")
    cost: int = Field(..., description="Points required to redeem this reward")
    reward_type: RewardType = Field(..., description="Type of reward (companion_skin, voucher, etc.)")
    image_path: Optional[str] = Field(None, description="Path to reward image asset")
    is_active: bool = Field(True, description="Whether this reward is available for redemption")

    class Config:
        json_schema_extra = {
            "example": {
                "reward_id": "REW001",
                "reward_name": "Siamese Cat",
                "description": "A Siamese appearance for your AI companion.",
                "cost": 2000,
                "reward_type": "companion_skin",
                "image_path": "siamese1.png",
                "is_active": True
            }
        }


class RewardCreate(BaseModel):
    """Request model for creating a Reward"""
    reward_id: str
    reward_name: str
    description: str
    cost: int
    reward_type: RewardType
    image_path: Optional[str] = None
    is_active: bool = True


class RewardUpdate(BaseModel):
    """Request model for updating a Reward"""
    reward_name: Optional[str] = None
    description: Optional[str] = None
    cost: Optional[int] = None
    reward_type: Optional[RewardType] = None
    image_path: Optional[str] = None
    is_active: Optional[bool] = None


class RewardResponse(BaseModel):
    """Response model for Reward"""
    reward_id: str
    reward_name: str
    description: str
    cost: int
    reward_type: RewardType
    image_path: Optional[str] = None
    is_active: bool

    class Config:
        json_schema_extra = {
            "example": {
                "reward_id": "REW001",
                "reward_name": "Siamese Cat",
                "description": "A Siamese appearance for your AI companion.",
                "cost": 2000,
                "reward_type": "companion_skin",
                "image_path": "siamese1.png",
                "is_active": True
            }
        }
