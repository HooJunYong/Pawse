from typing import List

from fastapi import APIRouter, Depends, HTTPException

from ..models.database import db
from ..models.breathing_schemas import (
    BreathingExerciseCreate,
    BreathingExerciseResponse,
    BreathingSessionCreate,
    BreathingSessionResponse,
    BreathingStatsResponse,
)
from ..services.breathing_service import BreathingService

router = APIRouter(prefix="/breathing", tags=["Breathing"])


def get_breathing_service() -> BreathingService:
    return BreathingService(db)


@router.get("/exercises", response_model=List[BreathingExerciseResponse])
async def list_breathing_exercises(
    active_only: bool = True,
    service: BreathingService = Depends(get_breathing_service),
):
    try:
        return service.list_exercises(active_only=active_only)
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=500, detail=f"Error listing exercises: {exc}") from exc


@router.get("/exercises/{exercise_id}", response_model=BreathingExerciseResponse)
async def get_breathing_exercise(
    exercise_id: str,
    service: BreathingService = Depends(get_breathing_service),
):
    exercise = service.get_exercise(exercise_id)
    if not exercise:
        raise HTTPException(status_code=404, detail="Breathing exercise not found")
    return exercise


@router.post("/exercises", response_model=BreathingExerciseResponse)
async def create_breathing_exercise(
    exercise_data: BreathingExerciseCreate,
    service: BreathingService = Depends(get_breathing_service),
):
    try:
        return service.create_exercise(exercise_data)
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=500, detail=f"Error creating exercise: {exc}") from exc


@router.post("/sessions", response_model=BreathingSessionResponse)
async def log_breathing_session(
    session_data: BreathingSessionCreate,
    service: BreathingService = Depends(get_breathing_service),
):
    try:
        return service.log_session(session_data)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=500, detail=f"Error logging session: {exc}") from exc


@router.get("/sessions/{user_id}", response_model=List[BreathingSessionResponse])
async def get_user_breathing_sessions(
    user_id: str,
    limit: int = 50,
    skip: int = 0,
    service: BreathingService = Depends(get_breathing_service),
):
    try:
        return service.get_user_sessions(user_id, limit=limit, skip=skip)
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=500, detail=f"Error getting sessions: {exc}") from exc


@router.get("/stats/{user_id}", response_model=BreathingStatsResponse)
async def get_breathing_stats(
    user_id: str,
    service: BreathingService = Depends(get_breathing_service),
):
    try:
        return service.get_user_stats(user_id)
    except Exception as exc:  # pragma: no cover - defensive
        raise HTTPException(status_code=500, detail=f"Error getting stats: {exc}") from exc
