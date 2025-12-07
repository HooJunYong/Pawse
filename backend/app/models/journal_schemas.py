from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class PromptType(str, Enum):
    reflection = "reflection"
    gratitude = "gratitude"
    expressive = "expressive"


class JournalEntryCreate(BaseModel):
    title: str = Field(..., max_length=255)
    content: str
    prompt_type: PromptType
    emotional_tags: Optional[List[str]] = []


class JournalEntryUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=255)
    content: Optional[str] = None
    emotional_tags: Optional[List[str]] = None


class JournalEntryResponse(BaseModel):
    entry_id: str
    user_id: str
    title: str
    content: str
    prompt_type: str
    emotional_tags: List[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PromptResponse(BaseModel):
    prompt: str
    prompt_type: str
