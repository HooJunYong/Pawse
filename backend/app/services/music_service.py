from __future__ import annotations

from datetime import datetime
from typing import Dict, List, Optional

from pymongo import ReturnDocument
from pymongo.collection import Collection
from pymongo.database import Database

from ..models.music_schemas import (
    MoodCategory,
    MoodType,
    MusicTrackCreate,
    MusicTrackResponse,
    MusicTrackUpdate,
    PlaylistSong,
)
from ..config.settings import (
    SPOTIFY_CLIENT_ID,
    SPOTIFY_CLIENT_SECRET,
    SPOTIFY_DEFAULT_MARKET,
)
from .spotify_client import SpotifyClient, SpotifyAuthError


class MusicService:
    """Service helpers for storing Spotify tracks in MongoDB."""

    MOOD_KEYWORDS: Dict[MoodType, str] = {
        MoodType.very_happy: "feel good happy uplifting playlist",
        MoodType.happy: "happy upbeat pop",
        MoodType.neutral: "focus background chill",
        MoodType.sad: "comfort calm acoustic",
        MoodType.awful: "soothing piano calm",
    }

    MOOD_TO_CATEGORY: Dict[MoodType, MoodCategory] = {
        MoodType.very_happy: MoodCategory.empowered,
        MoodType.happy: MoodCategory.hopeful,
        MoodType.neutral: MoodCategory.calm,
        MoodType.sad: MoodCategory.comfort,
        MoodType.awful: MoodCategory.anxious,
    }

    def __init__(self, db: Database, *, spotify_client: Optional[SpotifyClient] = None):
        self.collection: Collection = db["music_tracks"]
        if spotify_client:
            self.spotify = spotify_client
        else:
            # Attempt to initialise Spotify client; caller should handle missing credentials
            try:
                self.spotify = SpotifyClient(SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
            except SpotifyAuthError:
                self.spotify = None
        self.default_market = SPOTIFY_DEFAULT_MARKET

    def upsert_track(self, payload: MusicTrackCreate) -> MusicTrackResponse:
        data = payload.model_dump()
        added_at = data.pop("added_at", None) or datetime.utcnow()
        update_doc = {
            "$set": data,
            "$setOnInsert": {"added_at": added_at},
        }
        doc = self.collection.find_one_and_update(
            {"music_id": data["music_id"]},
            update_doc,
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )
        if doc is None:
            doc = self.collection.find_one({"music_id": data["music_id"]})
        return MusicTrackResponse(**self._map_doc(doc))

    def ensure_track(self, song: PlaylistSong, *, default_mood: Optional[MoodCategory] = None) -> MusicTrackResponse:
        existing = self.collection.find_one({"music_id": song.music_id})
        if existing:
            return MusicTrackResponse(**self._map_doc(existing))
        create_payload = MusicTrackCreate(
            music_id=song.music_id,
            title=song.title,
            artist=song.artist,
            duration_seconds=song.duration_seconds,
            thumbnail_url=song.thumbnail_url,
            album_image_url=song.album_image_url,
            mood_category=song.mood_category or default_mood,
            is_liked=song.is_liked,
            play_count=0,
        )
        return self.upsert_track(create_payload)

    def update_track(self, music_id: str, payload: MusicTrackUpdate) -> Optional[MusicTrackResponse]:
        update_data = {k: v for k, v in payload.model_dump(exclude_unset=True).items() if v is not None}
        if not update_data:
            existing = self.collection.find_one({"music_id": music_id})
            return MusicTrackResponse(**self._map_doc(existing)) if existing else None

        doc = self.collection.find_one_and_update(
            {"music_id": music_id},
            {"$set": update_data},
            return_document=ReturnDocument.AFTER,
        )
        return MusicTrackResponse(**self._map_doc(doc)) if doc else None

    def increment_play_count(self, music_id: str, increment: int = 1) -> Optional[MusicTrackResponse]:
        doc = self.collection.find_one_and_update(
            {"music_id": music_id},
            {"$inc": {"play_count": max(increment, 0)}},
            return_document=ReturnDocument.AFTER,
        )
        return MusicTrackResponse(**self._map_doc(doc)) if doc else None

    def set_like_status(self, music_id: str, is_liked: bool) -> Optional[MusicTrackResponse]:
        doc = self.collection.find_one_and_update(
            {"music_id": music_id},
            {"$set": {"is_liked": is_liked}},
            return_document=ReturnDocument.AFTER,
        )
        return MusicTrackResponse(**self._map_doc(doc)) if doc else None

    def get_track(self, music_id: str) -> Optional[MusicTrackResponse]:
        doc = self.collection.find_one({"music_id": music_id})
        return MusicTrackResponse(**self._map_doc(doc)) if doc else None

    def list_tracks(
        self,
        *,
        mood: Optional[MoodCategory] = None,
        limit: int = 50,
        skip: int = 0,
    ) -> List[MusicTrackResponse]:
        query = {"mood_category": mood.value} if mood else {}
        cursor = (
            self.collection.find(query)
            .sort("added_at", -1)
            .skip(max(skip, 0))
            .limit(max(limit, 1))
        )
        return [MusicTrackResponse(**self._map_doc(doc)) for doc in cursor]

    def recommend_by_mood(self, mood: MoodType, *, limit: int = 10, market: Optional[str] = None) -> List[MusicTrackResponse]:
        if not self.spotify:
            raise SpotifyAuthError("Spotify client credentials are not set; cannot fetch recommendations.")
        market_code = market or self.default_market
        keyword = self.MOOD_KEYWORDS.get(mood, "calm playlist")
        spotify_tracks = self.spotify.search_tracks(keyword, limit=max(limit * 2, limit), market=market_code)
        mood_category = self.MOOD_TO_CATEGORY.get(mood)
        results: List[MusicTrackResponse] = []
        seen_ids: set[str] = set()
        for track in spotify_tracks:
            try:
                mapped = self._map_spotify_track(track, mood_category)
            except ValueError:
                continue
            response = self.upsert_track(mapped)
            if response.music_id not in seen_ids:
                results.append(response)
                seen_ids.add(response.music_id)
            if len(results) >= limit:
                break
        return results

    def search_tracks(self, query: str, *, limit: int = 10, market: Optional[str] = None) -> List[MusicTrackResponse]:
        if not self.spotify:
            raise SpotifyAuthError("Spotify client credentials are not set; cannot search tracks.")
        market_code = market or self.default_market
        spotify_tracks = self.spotify.search_tracks(query, limit=limit, market=market_code)
        results: List[MusicTrackResponse] = []
        for track in spotify_tracks:
            try:
                mapped = self._map_spotify_track(track, None)
            except ValueError:
                continue
            results.append(self.upsert_track(mapped))
        return results

    def _map_spotify_track(self, track: Dict, mood: Optional[MoodCategory]) -> MusicTrackCreate:
        music_id = track.get("id")
        if not music_id:
            raise ValueError("Spotify track missing id")
        title = track.get("name", "")
        artists = track.get("artists", [])
        artist_name = ", ".join(artist.get("name", "") for artist in artists if artist.get("name"))
        duration_ms = track.get("duration_ms", 0)
        duration_seconds = int(duration_ms / 1000) if duration_ms else 0
        album = track.get("album", {})
        images = album.get("images", []) or []
        thumbnail_url = images[-1]["url"] if images else None
        album_image_url = images[0]["url"] if images else thumbnail_url
        return MusicTrackCreate(
            music_id=music_id,
            title=title,
            artist=artist_name,
            duration_seconds=duration_seconds,
            thumbnail_url=thumbnail_url,
            album_image_url=album_image_url,
            mood_category=mood,
            play_count=0,
        )

    def _map_doc(self, doc: Optional[dict]) -> dict:
        if not doc:
            raise ValueError("Music track not found")
        data = dict(doc)
        data.pop("_id", None)
        if isinstance(data.get("mood_category"), str):
            try:
                data["mood_category"] = MoodCategory(data["mood_category"])
            except ValueError:
                data["mood_category"] = None
        if not isinstance(data.get("added_at"), datetime):
            raw_added = data.get("added_at")
            if raw_added is None:
                data["added_at"] = datetime.utcnow()
        return data
