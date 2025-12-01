from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class BreathStepSchema(BaseModel):
    label: str = Field(..., min_length=1, max_length=50)
    seconds: int = Field(..., gt=0, lt=600)


class BreathPatternSchema(BaseModel):
    steps: List[BreathStepSchema] = Field(..., min_length=1)
    cycles: int = Field(default=4, gt=0, lt=100)


class BreathingExerciseCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)
    description: str = Field(..., min_length=1, max_length=300)
    focus_area: Optional[str] = Field(default=None, max_length=80)
    duration_seconds: Optional[int] = Field(default=None, gt=0, lt=3600)
    duration_label: Optional[str] = Field(default=None, max_length=20)
    tags: List[str] = Field(default_factory=list)
    is_active: bool = True
    pattern: BreathPatternSchema
    slug: Optional[str] = Field(default=None, min_length=1, max_length=80)
    audio_url: Optional[str] = Field(default=None, max_length=255)
    metadata: Optional[dict] = None


class BreathingExerciseResponse(BaseModel):
    exercise_id: str
    name: str
    description: str
    focus_area: Optional[str]
    duration_seconds: Optional[int]
    duration_label: Optional[str]
    tags: List[str]
    is_active: bool
    pattern: BreathPatternSchema
    slug: Optional[str]
    audio_url: Optional[str]
    metadata: Optional[dict]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class BreathingSessionCreate(BaseModel):
    user_id: str = Field(..., min_length=1)
    exercise_id: str = Field(..., min_length=1)
    cycles_completed: int = Field(..., gt=0, lt=200)
    duration_seconds: Optional[int] = Field(default=None, gt=0, lt=7200)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    mood_before: Optional[int] = Field(default=None, ge=1, le=10)
    mood_after: Optional[int] = Field(default=None, ge=1, le=10)
    notes: Optional[str] = Field(default=None, max_length=500)


class BreathingSessionResponse(BaseModel):
    session_id: str
    user_id: str
    exercise_id: str
    cycles_completed: int
    duration_seconds: Optional[int]
    started_at: datetime
    completed_at: datetime
    mood_before: Optional[int]
    mood_after: Optional[int]
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class BreathingStatsResponse(BaseModel):
    user_id: str
    total_sessions: int
    total_duration_seconds: int
    average_cycles_completed: float
    last_session_at: Optional[datetime]
