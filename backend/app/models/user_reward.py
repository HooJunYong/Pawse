from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class UserReward(BaseModel):
    """UserReward model for MongoDB collection - tracks rewards redeemed by users"""
    user_reward_id: str = Field(..., description="Primary Key (UR001, UR002, ...)")
    user_id: str = Field(..., description="Reference to user who redeemed the reward")
    reward_id: str = Field(..., description="Reference to the reward that was redeemed")
    redeemed_date: datetime = Field(..., description="Date and time when the reward was redeemed")

    class Config:
        json_schema_extra = {
            "example": {
                "user_reward_id": "UR001",
                "user_id": "fefde540-85da-49de-ab03-c7e1a99e0a08",
                "reward_id": "REW001",
                "redeemed_date": "2025-12-07T10:30:00"
            }
        }


class UserRewardCreate(BaseModel):
    """Request model for creating a UserReward (redeeming a reward)"""
    user_id: str
    reward_id: str
    redeemed_date: Optional[datetime] = None  # If not provided, will use current time

    class Config:
        json_schema_extra = {
            "example": {
                "user_id": "fefde540-85da-49de-ab03-c7e1a99e0a08",
                "reward_id": "REW001"
            }
        }


class UserRewardResponse(BaseModel):
    """Response model for UserReward"""
    user_reward_id: str
    user_id: str
    reward_id: str
    redeemed_date: datetime

    class Config:
        json_schema_extra = {
            "example": {
                "user_reward_id": "UR001",
                "user_id": "fefde540-85da-49de-ab03-c7e1a99e0a08",
                "reward_id": "REW001",
                "redeemed_date": "2025-12-07T10:30:00"
            }
        }


class UserRewardWithDetails(BaseModel):
    """Response model for UserReward with full reward details"""
    user_reward_id: str
    user_id: str
    reward_id: str
    redeemed_date: datetime
    reward_name: str = Field(..., description="Name of the redeemed reward")
    reward_description: str = Field(..., description="Description of the reward")
    reward_type: str = Field(..., description="Type of reward")
    image_path: Optional[str] = Field(None, description="Path to reward image")

    class Config:
        json_schema_extra = {
            "example": {
                "user_reward_id": "UR001",
                "user_id": "fefde540-85da-49de-ab03-c7e1a99e0a08",
                "reward_id": "REW001",
                "redeemed_date": "2025-12-07T10:30:00",
                "reward_name": "Siamese Cat",
                "reward_description": "A Siamese appearance for your AI companion.",
                "reward_type": "companion_skin",
                "image_path": "siamese1.png"
            }
        }
