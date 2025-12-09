from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from uuid import uuid4

from pymongo import ReturnDocument
from pymongo.collection import Collection
from pymongo.database import Database

from ..models.music_schemas import (
    MusicListeningSessionCreate,
    MusicListeningSessionResponse,
    PlaylistSong,
    UserPlaylistCreate,
    UserPlaylistResponse,
    UserPlaylistUpdate,
)


class UserPlaylistService:
    def __init__(self, db: Database):
        self._db = db
        self.collection: Collection = db["user_playlists"]

    def create_playlist(self, payload: UserPlaylistCreate) -> UserPlaylistResponse:
        now = datetime.utcnow()
        doc = {
            **payload.model_dump(),
            "user_playlist_id": str(uuid4()),
            "created_at": now,
            "updated_at": now,
        }
        self.collection.insert_one(doc)
        return UserPlaylistResponse(**self._map_doc(doc))

    def list_playlists(self, user_id: str) -> List[UserPlaylistResponse]:
        cursor = self.collection.find({"user_id": user_id}).sort("created_at", -1)
        return [UserPlaylistResponse(**self._map_doc(doc)) for doc in cursor]

    def list_public_playlists(self) -> List[UserPlaylistResponse]:
        cursor = self.collection.find({"is_public": True}).sort("updated_at", -1)
        return [UserPlaylistResponse(**self._map_doc(doc)) for doc in cursor]

    def get_playlist(self, playlist_id: str) -> Optional[UserPlaylistResponse]:
        doc = self.collection.find_one({"user_playlist_id": playlist_id})
        return UserPlaylistResponse(**self._map_doc(doc)) if doc else None

    def update_playlist(self, playlist_id: str, payload: UserPlaylistUpdate) -> Optional[UserPlaylistResponse]:
        update_data = payload.model_dump(exclude_unset=True)
        if not update_data:
            return self.get_playlist(playlist_id)
        update_data["updated_at"] = datetime.utcnow()
        doc = self.collection.find_one_and_update(
            {"user_playlist_id": playlist_id},
            {"$set": update_data},
            return_document=ReturnDocument.AFTER,
        )
        return UserPlaylistResponse(**self._map_doc(doc)) if doc else None

    def add_song(self, playlist_id: str, song: PlaylistSong) -> Optional[UserPlaylistResponse]:
        doc = self.collection.find_one({"user_playlist_id": playlist_id})
        if not doc:
            return None
        
        # Check if this is the Favorites playlist
        is_favorites = doc.get("is_favorite", False) or doc.get("playlist_name") == "Favorites"
        
        songs: List[dict] = doc.get("songs", [])
        if not any(existing.get("music_id") == song.music_id for existing in songs):
            songs.append(song.model_dump())
            
        # If adding to Favorites playlist, also set is_liked flag on the track
        if is_favorites:
            music_col = self._db["music_tracks"]
            music_col.update_one(
                {"music_id": song.music_id},
                {"$set": {"is_liked": True}},
                upsert=False
            )
            
        updated = self.collection.find_one_and_update(
            {"user_playlist_id": playlist_id},
            {
                "$set": {
                    "songs": songs,
                    "updated_at": datetime.utcnow(),
                }
            },
            return_document=ReturnDocument.AFTER,
        )
        return UserPlaylistResponse(**self._map_doc(updated)) if updated else None

    def remove_song(self, playlist_id: str, music_id: str) -> Optional[UserPlaylistResponse]:
        doc = self.collection.find_one({"user_playlist_id": playlist_id})
        if not doc:
            return None
        
        # Check if this is the Favorites playlist
        is_favorites = doc.get("is_favorite", False) or doc.get("playlist_name") == "Favorites"
        
        songs: List[dict] = doc.get("songs", [])
        songs = [song for song in songs if song.get("music_id") != music_id]
        
        # If removing from Favorites playlist, also set is_liked flag to False on the track
        if is_favorites:
            music_col = self._db["music_tracks"]
            music_col.update_one(
                {"music_id": music_id},
                {"$set": {"is_liked": False}},
                upsert=False
            )
            
        updated = self.collection.find_one_and_update(
            {"user_playlist_id": playlist_id},
            {
                "$set": {
                    "songs": songs,
                    "updated_at": datetime.utcnow(),
                }
            },
            return_document=ReturnDocument.AFTER,
        )
        return UserPlaylistResponse(**self._map_doc(updated)) if updated else None

    def delete_playlist(self, playlist_id: str) -> bool:
        result = self.collection.delete_one({"user_playlist_id": playlist_id})
        return result.deleted_count > 0

    @staticmethod
    def _map_doc(doc: Optional[dict]) -> dict:
        if not doc:
            raise ValueError("Playlist not found")
        data = dict(doc)
        data.pop("_id", None)
        return data


class MusicListeningSessionService:
    def __init__(self, db: Database):
        self.collection: Collection = db["music_listening_sessions"]

    def log_session(self, payload: MusicListeningSessionCreate) -> MusicListeningSessionResponse:
        data = payload.model_dump()
        if not data.get("playlist_id") and not data.get("user_playlist_id"):
            raise ValueError("A playlist_id or user_playlist_id must be provided")
        now = datetime.utcnow()
        data.setdefault("music_session_id", str(uuid4()))
        data.setdefault("started_at", now)
        data.setdefault("ended_at", None)
        self.collection.insert_one(data)
        stored = self.collection.find_one({"music_session_id": data["music_session_id"]})
        return MusicListeningSessionResponse(**self._map_doc(stored))

    def list_sessions(self, user_id: str, *, limit: int = 50) -> List[MusicListeningSessionResponse]:
        cursor = (
            self.collection.find({"user_id": user_id})
            .sort("started_at", -1)
            .limit(max(limit, 1))
        )
        return [MusicListeningSessionResponse(**self._map_doc(doc)) for doc in cursor]

    @staticmethod
    def _map_doc(doc: Optional[dict]) -> dict:
        if not doc:
            raise ValueError("Music listening session not found")
        data = dict(doc)
        data.pop("_id", None)
        return data
