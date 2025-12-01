from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class BottleStatus(str, Enum):
    """Enum for drift bottle status"""
    AVAILABLE = "available"
    PICKED_UP = "picked_up"
    COMPLETED = "completed"
    EXPIRED = "expired"


class DriftBottle(BaseModel):
    """Drift Bottle model for MongoDB collection"""
    bottle_id: str = Field(..., description="Primary Key (BTL001, BTL002, ...)")
    user_id: str = Field(..., description="Reference to User who created the bottle")
    message: str = Field(..., description="Message contents in the bottle")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: BottleStatus = Field(default=BottleStatus.AVAILABLE, description="Bottle status")
    is_active: bool = Field(default=True)

    class Config:
        json_schema_extra = {
            "example": {
                "bottle_id": "BTL001",
                "user_id": "USER123",
                "message": "Hello, whoever finds this bottle!",
                "status": "available",
                "is_active": True
            }
        }


class DriftBottleCreate(BaseModel):
    """Request model for creating a Drift Bottle"""
    user_id: str
    message: str
    status: BottleStatus = BottleStatus.AVAILABLE
    is_active: bool = True


class DriftBottleUpdate(BaseModel):
    """Request model for updating a Drift Bottle"""
    message: Optional[str] = None
    status: Optional[BottleStatus] = None
    is_active: Optional[bool] = None


class DriftBottleResponse(BaseModel):
    """Response model for Drift Bottle"""
    bottle_id: str
    user_id: str
    message: str
    created_at: datetime
    status: BottleStatus
    is_active: bool
