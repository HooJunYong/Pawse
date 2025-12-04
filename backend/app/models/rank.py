from pydantic import BaseModel, Field
from typing import Optional


class Rank(BaseModel):
    """Rank model for MongoDB collection"""
    rank_id: str = Field(..., description="Primary Key (rank_bronze, rank_silver, rank_gold)")
    rank_name: str = Field(..., description="Display name of the rank")
    min_points: int = Field(..., description="Minimum points required for this rank")
    max_points: int = Field(..., description="Maximum points for this rank")

    class Config:
        json_schema_extra = {
            "example": {
                "rank_id": "rank_bronze",
                "rank_name": "Bronze",
                "min_points": 0,
                "max_points": 2999
            }
        }


class RankCreate(BaseModel):
    """Request model for creating a Rank"""
    rank_id: str
    rank_name: str
    min_points: int
    max_points: int


class RankUpdate(BaseModel):
    """Request model for updating a Rank"""
    rank_name: Optional[str] = None
    min_points: Optional[int] = None
    max_points: Optional[int] = None


class RankResponse(BaseModel):
    """Response model for Rank"""
    rank_id: str
    rank_name: str
    min_points: int
    max_points: int
