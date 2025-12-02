from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class MoodCategory(str, Enum):
    calm = "calm"
    focus = "focus"
    empowered = "empowered"
    comfort = "comfort"
    anxious = "anxious"
    hopeful = "hopeful"
    lonely = "lonely"


class MoodType(str, Enum):
    very_happy = "very happy"
    happy = "happy"
    neutral = "neutral"
    sad = "sad"
    awful = "awful"


class MusicTrackBase(BaseModel):
    title: str = Field(..., max_length=150)
    artist: str = Field(..., max_length=100)
    duration_seconds: int = Field(..., ge=0)
    thumbnail_url: Optional[str] = Field(None, max_length=255)
    album_image_url: Optional[str] = Field(None, max_length=255)
    mood_category: Optional[MoodCategory] = None
    is_liked: bool = False
    play_count: int = Field(0, ge=0)


class MusicTrackCreate(MusicTrackBase):
    music_id: str = Field(..., max_length=64)
    added_at: Optional[datetime] = None


class MusicTrackUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=150)
    artist: Optional[str] = Field(None, max_length=100)
    duration_seconds: Optional[int] = Field(None, ge=0)
    thumbnail_url: Optional[str] = Field(None, max_length=255)
    album_image_url: Optional[str] = Field(None, max_length=255)
    mood_category: Optional[MoodCategory] = None
    is_liked: Optional[bool] = None
    play_count: Optional[int] = Field(None, ge=0)


class MusicTrackResponse(MusicTrackBase):
    music_id: str
    added_at: datetime

    class Config:
        from_attributes = True


class PlaylistSong(BaseModel):
    music_id: str = Field(..., max_length=64)
    title: str = Field(..., max_length=150)
    artist: str = Field(..., max_length=100)
    duration_seconds: int = Field(..., ge=0)
    thumbnail_url: Optional[str] = Field(None, max_length=255)
    album_image_url: Optional[str] = Field(None, max_length=255)
    mood_category: Optional[MoodCategory] = None
    is_liked: bool = False


class UserPlaylistBase(BaseModel):
    playlist_name: str = Field(..., max_length=100)
    custom_tags: List[str] = Field(default_factory=list)
    songs: List[PlaylistSong] = Field(default_factory=list)
    is_public: bool = False


class UserPlaylistCreate(UserPlaylistBase):
    user_id: str = Field(..., max_length=64)


class UserPlaylistUpdate(BaseModel):
    playlist_name: Optional[str] = Field(None, max_length=100)
    custom_tags: Optional[List[str]] = None
    is_public: Optional[bool] = None


class UserPlaylistResponse(UserPlaylistBase):
    user_playlist_id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlaylistSongRequest(PlaylistSong):
    pass


class MusicListeningSessionBase(BaseModel):
    user_id: str = Field(..., max_length=64)
    playlist_id: Optional[str] = Field(None, max_length=64)
    user_playlist_id: Optional[str] = Field(None, max_length=64)
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None


class MusicListeningSessionCreate(MusicListeningSessionBase):
    music_session_id: Optional[str] = None


class MusicListeningSessionResponse(MusicListeningSessionBase):
    music_session_id: str

    class Config:
        from_attributes = True
