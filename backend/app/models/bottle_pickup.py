from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class PickupAction(str, Enum):
    """Enum for pickup action taken"""
    PENDING = "pending"
    PASSED = "passed"
    REPLIED = "replied"
    TIMEOUT = "timeout"


class BottlePickup(BaseModel):
    """Bottle Pickup model for MongoDB collection"""
    pickup_id: str = Field(..., description="Primary Key (PU001, PU002, ...)")
    bottle_id: str = Field(..., description="Reference to Drift Bottle")
    user_id: str = Field(..., description="Reference to User who picked up the bottle")
    pickup_time: datetime = Field(default_factory=datetime.utcnow)
    action_taken: PickupAction = Field(default=PickupAction.PENDING, description="Action taken on the bottle")

    class Config:
        json_schema_extra = {
            "example": {
                "pickup_id": "PU001",
                "bottle_id": "BTL001",
                "user_id": "USER456",
                "action_taken": "pending"
            }
        }


class BottlePickupCreate(BaseModel):
    """Request model for creating a Bottle Pickup"""
    bottle_id: str
    user_id: str
    action_taken: PickupAction = PickupAction.PENDING


class BottlePickupUpdate(BaseModel):
    """Request model for updating a Bottle Pickup"""
    action_taken: Optional[PickupAction] = None


class BottlePickupResponse(BaseModel):
    """Response model for Bottle Pickup"""
    pickup_id: str
    bottle_id: str
    user_id: str
    pickup_time: datetime
    action_taken: PickupAction
