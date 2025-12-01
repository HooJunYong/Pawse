from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from uuid import uuid4

from pymongo.database import Database

from ..models.breathing_schemas import (
    BreathingExerciseCreate,
    BreathingSessionCreate,
    BreathPatternSchema,
    BreathingExerciseResponse,
    BreathingSessionResponse,
    BreathingStatsResponse,
)

DEFAULT_EXERCISES: List[dict] = [
    {
        "name": "Box Breathing",
        "slug": "box-breathing",
        "description": "Steady four-part breathing to calm the nervous system.",
        "focus_area": "relaxation",
        "duration_label": "4 min",
        "tags": ["focus", "calm"],
        "pattern": {
            "steps": [
                {"label": "Inhale", "seconds": 4},
                {"label": "Hold", "seconds": 4},
                {"label": "Exhale", "seconds": 4},
                {"label": "Hold", "seconds": 4},
            ],
            "cycles": 15,
        },
        "metadata": {
            "color_hex": "#FB923C",
            "icon": "crop_square_rounded",
        },
    },
    {
        "name": "4-7-8 Breathing",
        "slug": "four-seven-eight",
        "description": "Deep breathing rhythm to ease anxiety and prepare for sleep.",
        "focus_area": "sleep",
        "duration_label": "5 min",
        "tags": ["sleep", "anxiety"],
        "pattern": {
            "steps": [
                {"label": "Inhale", "seconds": 4},
                {"label": "Hold", "seconds": 7},
                {"label": "Exhale", "seconds": 8},
            ],
            "cycles": 8,
        },
        "metadata": {
            "color_hex": "#60A5FA",
            "icon": "nightlight_round",
        },
    },
    {
        "name": "Diaphragmatic Breathing",
        "slug": "diaphragmatic",
        "description": "Slow belly breathing that strengthens the diaphragm and relaxes.",
        "focus_area": "grounding",
        "duration_label": "6 min",
        "tags": ["grounding", "body"],
        "pattern": {
            "steps": [
                {"label": "Inhale", "seconds": 4},
                {"label": "Exhale", "seconds": 6},
            ],
            "cycles": 36,
        },
        "metadata": {
            "color_hex": "#34D399",
            "icon": "air",
        },
    },
]


class BreathingService:
    def __init__(self, db: Database):
        self.db = db
        self.exercises = db["breathing_exercises"]
        self.sessions = db["user_breathing_sessions"]
        self._seed_defaults()

    def _seed_defaults(self) -> None:
        if self.exercises.count_documents({}) > 0:
            return
        now = datetime.utcnow()
        docs = []
        for entry in DEFAULT_EXERCISES:
            pattern = BreathPatternSchema(**entry["pattern"]).model_dump()
            cycle_seconds = sum(step["seconds"] for step in pattern["steps"])
            total_duration = cycle_seconds * pattern["cycles"]
            docs.append(
                {
                    **entry,
                    "pattern": pattern,
                    "exercise_id": str(uuid4()),
                    "duration_seconds": total_duration,
                    "is_active": True,
                    "created_at": now,
                    "updated_at": now,
                }
            )
        if docs:
            self.exercises.insert_many(docs)

    def list_exercises(self, *, active_only: bool = True) -> List[BreathingExerciseResponse]:
        query = {"is_active": True} if active_only else {}
        cursor = self.exercises.find(query).sort("name")
        return [BreathingExerciseResponse(**self._map_exercise(doc)) for doc in cursor]

    def get_exercise(self, exercise_id: str) -> Optional[dict]:
        doc = self.exercises.find_one({"exercise_id": exercise_id})
        return self._map_exercise(doc) if doc else None

    def get_exercise_by_slug(self, slug: str) -> Optional[dict]:
        doc = self.exercises.find_one({"slug": slug})
        return self._map_exercise(doc) if doc else None

    def create_exercise(self, payload: BreathingExerciseCreate) -> BreathingExerciseResponse:
        data = payload.model_dump()
        pattern = BreathPatternSchema(**data["pattern"]).model_dump()
        cycle_seconds = sum(step["seconds"] for step in pattern["steps"])
        total_duration = cycle_seconds * pattern["cycles"]
        now = datetime.utcnow()
        doc = {
            **data,
            "pattern": pattern,
            "duration_seconds": data.get("duration_seconds") or total_duration,
            "exercise_id": str(uuid4()),
            "created_at": now,
            "updated_at": now,
        }
        self.exercises.insert_one(doc)
        return BreathingExerciseResponse(**self._map_exercise(doc))

    def log_session(self, payload: BreathingSessionCreate) -> BreathingSessionResponse:
        exercise = self.get_exercise(payload.exercise_id)
        if not exercise:
            raise ValueError("Exercise not found")

        data = payload.model_dump()
        now = datetime.utcnow()
        started_at = data.get("started_at") or now
        completed_at = data.get("completed_at") or now
        if completed_at < started_at:
            completed_at = started_at

        duration_seconds = data.get("duration_seconds")
        if not duration_seconds:
            duration_seconds = int(
                (completed_at - started_at).total_seconds()
            ) or exercise.get("duration_seconds")

        doc = {
            "session_id": str(uuid4()),
            "user_id": data["user_id"],
            "exercise_id": data["exercise_id"],
            "cycles_completed": data["cycles_completed"],
            "duration_seconds": duration_seconds,
            "started_at": started_at,
            "completed_at": completed_at,
            "mood_before": data.get("mood_before"),
            "mood_after": data.get("mood_after"),
            "notes": data.get("notes"),
            "created_at": now,
        }
        self.sessions.insert_one(doc)
        return BreathingSessionResponse(**self._map_session(doc))

    def get_user_sessions(
        self,
        user_id: str,
        *,
        limit: int = 50,
        skip: int = 0,
    ) -> List[BreathingSessionResponse]:
        cursor = (
            self.sessions.find({"user_id": user_id})
            .sort("completed_at", -1)
            .skip(skip)
            .limit(limit)
        )
        return [BreathingSessionResponse(**self._map_session(doc)) for doc in cursor]

    def get_user_stats(self, user_id: str) -> BreathingStatsResponse:
        pipeline = [
            {"$match": {"user_id": user_id}},
            {
                "$group": {
                    "_id": "$user_id",
                    "total_sessions": {"$sum": 1},
                    "total_duration_seconds": {"$sum": {"$ifNull": ["$duration_seconds", 0]}},
                    "total_cycles": {"$sum": "$cycles_completed"},
                    "last_session_at": {"$max": "$completed_at"},
                }
            },
        ]
        result = list(self.sessions.aggregate(pipeline))
        if not result:
            return BreathingStatsResponse(
                user_id=user_id,
                total_sessions=0,
                total_duration_seconds=0,
                average_cycles_completed=0.0,
                last_session_at=None,
            )

        summary = result[0]
        total_sessions = summary.get("total_sessions", 0)
        total_cycles = summary.get("total_cycles", 0)
        average_cycles = float(total_cycles) / total_sessions if total_sessions else 0.0
        return BreathingStatsResponse(
            user_id=user_id,
            total_sessions=total_sessions,
            total_duration_seconds=summary.get("total_duration_seconds", 0),
            average_cycles_completed=round(average_cycles, 2),
            last_session_at=summary.get("last_session_at"),
        )

    @staticmethod
    def _map_exercise(doc: Optional[dict]) -> dict:
        if not doc:
            return {}
        data = dict(doc)
        data.pop("_id", None)
        return data

    @staticmethod
    def _map_session(doc: Optional[dict]) -> dict:
        if not doc:
            return {}
        data = dict(doc)
        data.pop("_id", None)
        return data
