from __future__ import annotations

from datetime import datetime
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple, Union, cast
import re

import httpx
from pymongo import ReturnDocument
from pymongo.collection import Collection
from pymongo.database import Database

from ..models.music_schemas import (
    MoodCategory,
    MoodType,
    MusicAlbumResponse,
    MusicTrackCreate,
    MusicTrackResponse,
    MusicTrackUpdate,
    PlaylistSong,
    PlaylistSongRequest,
)


ITUNES_SEARCH_URL = "https://itunes.apple.com/search"
DEFAULT_COUNTRY = "US"
MAX_ITUNES_LIMIT = 200


class ITunesAPIError(RuntimeError):
    """Raised when the iTunes Search API returns an error or unreadable payload."""


class MusicService:
    """Serve iTunes-powered music recommendations with MongoDB caching."""

    # Mood → local cache category (used for fallbacks and playlist ops)
    CATEGORY_BY_MOOD: Dict[MoodType, MoodCategory] = {
        MoodType.very_happy: MoodCategory.empowered,
        MoodType.happy: MoodCategory.hopeful,
        MoodType.neutral: MoodCategory.calm,
        MoodType.sad: MoodCategory.comfort,
        MoodType.awful: MoodCategory.anxious,
    }

    # Mood repair search terms (case-insensitive keys)
    MOOD_REPAIR_TERMS: Dict[str, str] = {
        "sad": "happy upbeat uplifting",
        "angry": "calm relaxing piano",
        "stressed": "healing ambient meditation",
        "tired": "high energy workout rock",
        "happy": "party dance hits",
    }

    # Map existing MoodType enum values onto the new mood repair labels
    MOODTYPE_ALIASES: Dict[MoodType, str] = {
        MoodType.sad: "sad",
        MoodType.awful: "stressed",
        MoodType.neutral: "tired",
        MoodType.happy: "happy",
        MoodType.very_happy: "happy",
    }

    def __init__(
        self,
        db: Database,
        *,
        http_client: Optional[httpx.Client] = None,
        country: str = DEFAULT_COUNTRY,
    ) -> None:
        self.collection: Collection = db["music_tracks"]
        self._http = http_client
        self._country = country

    # ------------------------------------------------------------------ #
    # CRUD helpers                                                       #
    # ------------------------------------------------------------------ #

    def upsert_track(
        self,
        payload: MusicTrackCreate,
        extra: Optional[Dict[str, object]] = None,
    ) -> MusicTrackResponse:
        """Persist or update a track document, merging any auxiliary fields."""
        data = payload.model_dump()
        if extra:
            data.update(extra)

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

    def ensure_track(
        self,
        song: PlaylistSong | PlaylistSongRequest,
        *,
        default_mood: Optional[MoodCategory] = None,
    ) -> MusicTrackResponse:
        existing = self.collection.find_one({"music_id": song.music_id})
        if existing:
            return MusicTrackResponse(**self._map_doc(existing))
        create_payload = MusicTrackCreate.model_validate(
            {
                "music_id": song.music_id,
                "title": song.title,
                "artist": song.artist,
                "duration_seconds": song.duration_seconds,
                "thumbnail_url": song.thumbnail_url,
                "album_image_url": song.album_image_url,
                "audio_url": song.audio_url,
                "mood_category": song.mood_category or default_mood,
                "is_liked": song.is_liked,
                "play_count": 0,
            }
        )
        return self.upsert_track(create_payload)

    def update_track(self, music_id: str, payload: MusicTrackUpdate) -> Optional[MusicTrackResponse]:
        update_data = {
            key: value
            for key, value in payload.model_dump(exclude_unset=True).items()
            if value is not None
        }
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

    # ------------------------------------------------------------------ #
    # Recommendation entry points                                       #
    # ------------------------------------------------------------------ #

    def recommend_by_mood(
        self,
        mood: Union[MoodType, str],
        *,
        limit: int = 10,
    ) -> List[MusicTrackResponse]:
        search_term = self._search_term_for_mood(mood)
        mood_category = self._category_for_mood(mood)
        try:
            raw_tracks = self._fetch_itunes_tracks(search_term, limit * 2)
        except ITunesAPIError:
            fallback = self._fallback_from_cache(mood_category, limit)
            if fallback:
                return fallback
            raise

        results: List[MusicTrackResponse] = []
        seen: Set[str] = set()
        for raw in raw_tracks:
            try:
                payload, extra = self._map_itunes_track(raw, mood_category)
            except ValueError:
                continue
            stored = self._persist_and_response(payload, extra)
            if stored.music_id in seen:
                continue
            seen.add(stored.music_id)
            results.append(stored)
            if len(results) >= limit:
                break

        if results:
            return results
        return self._fallback_from_cache(mood_category, limit)

    def recommend_albums_by_mood(
        self,
        mood: Union[MoodType, str],
        *,
        album_limit: int = 3,
        min_tracks_per_album: int = 5,
        max_tracks_per_album: int = 8,
    ) -> List[MusicAlbumResponse]:
        album_limit = max(1, min(album_limit, 5))
        min_tracks_per_album = max(1, min(min_tracks_per_album, max_tracks_per_album))
        max_tracks_per_album = max(min_tracks_per_album, min(max_tracks_per_album, 12))

        search_term = self._search_term_for_mood(mood)
        mood_category = self._category_for_mood(mood)

        try:
            raw_tracks = self._fetch_itunes_tracks(
                search_term,
                album_limit * max_tracks_per_album * 4,
            )
        except ITunesAPIError:
            fallback = self._fallback_albums_from_cache(
                mood_category,
                album_limit,
                min_tracks_per_album,
                max_tracks_per_album,
            )
            if fallback:
                return fallback
            raise

        albums_map: Dict[str, Dict[str, object]] = {}
        track_seen: Set[str] = set()

        for raw in raw_tracks:
            try:
                payload, extra = self._map_itunes_track(raw, mood_category)
            except ValueError:
                continue
            if payload.music_id in track_seen:
                continue

            stored = self._persist_and_response(payload, extra)
            track_seen.add(stored.music_id)

            album_id = raw.get("collectionId")
            album_id_str = str(album_id) if album_id is not None else f"mix-{stored.music_id}"
            album_title = raw.get("collectionName") or stored.title
            album_image_raw = raw.get("artworkUrl100") or stored.album_image_url or stored.thumbnail_url
            album_image_url = self._normalize_artwork_url(album_image_raw)

            album_entry = albums_map.setdefault(
                album_id_str,
                {
                    "title": album_title,
                    "image": album_image_url,
                    "tracks": [],
                },
            )
            tracks_list = cast(List[MusicTrackResponse], album_entry["tracks"])
            if len(tracks_list) >= max_tracks_per_album:
                continue
            tracks_list.append(stored)

        albums: List[MusicAlbumResponse] = []
        for album_id, data in albums_map.items():
            tracks_list = cast(List[MusicTrackResponse], data["tracks"])
            if len(tracks_list) < min_tracks_per_album:
                continue
            albums.append(
                MusicAlbumResponse(
                    album_id=album_id,
                    album_title=str(data["title"]) if data.get("title") else "Mood Mix",
                    album_image_url=str(data["image"]) if data.get("image") else None,
                    tracks=tracks_list[:max_tracks_per_album],
                )
            )
            if len(albums) >= album_limit:
                break

        if len(albums) < album_limit:
            fallback = self._fallback_albums_from_cache(
                mood_category,
                album_limit,
                min_tracks_per_album,
                max_tracks_per_album,
            )
            seen_albums = {album.album_id for album in albums}
            for album in fallback:
                if album.album_id in seen_albums:
                    continue
                albums.append(album)
                if len(albums) >= album_limit:
                    break

        return albums

    def search_tracks(
        self,
        query: str,
        *,
        limit: int = 10,
    ) -> List[MusicTrackResponse]:
        query = query.strip()
        if not query:
            return []
        try:
            raw_tracks = self._fetch_itunes_tracks(query, limit * 2, entity="song")
        except ITunesAPIError:
            fallback = self._search_cache(query, limit)
            return fallback if fallback else []
        results: List[MusicTrackResponse] = []
        seen: Set[str] = set()
        for raw in raw_tracks:
            try:
                payload, extra = self._map_itunes_track(raw, None)
            except ValueError:
                continue
            stored = self._persist_and_response(payload, extra)
            if stored.music_id in seen:
                continue
            seen.add(stored.music_id)
            results.append(stored)
            if len(results) >= limit:
                break
        return results

    def _search_cache(
        self,
        query: str,
        limit: int,
    ) -> List[MusicTrackResponse]:
        if not query:
            return []
        pattern = {"$regex": re.escape(query), "$options": "i"}
        cursor = (
            self.collection.find(
                {"$or": [{"title": pattern}, {"artist": pattern}]}
            )
            .sort("added_at", -1)
            .limit(max(limit, 1))
        )
        return [MusicTrackResponse(**self._map_doc(doc)) for doc in cursor]

    # ------------------------------------------------------------------ #
    # Internal helpers                                                   #
    # ------------------------------------------------------------------ #

    def _persist_and_response(
        self,
        payload: MusicTrackCreate,
        extra: Optional[Dict[str, object]],
    ) -> MusicTrackResponse:
        return self.upsert_track(payload, extra)

    def _fallback_from_cache(
        self,
        mood: Optional[MoodCategory],
        limit: int,
    ) -> List[MusicTrackResponse]:
        if not mood:
            return []
        cursor = (
            self.collection.find({"mood_category": mood.value})
            .sort("added_at", -1)
            .limit(max(limit, 1))
        )
        return [MusicTrackResponse(**self._map_doc(doc)) for doc in cursor]

    def _fallback_albums_from_cache(
        self,
        mood: Optional[MoodCategory],
        album_limit: int,
        min_tracks_per_album: int,
        max_tracks_per_album: int,
    ) -> List[MusicAlbumResponse]:
        if not mood:
            return []
        cached_tracks = self._fallback_from_cache(mood, album_limit * max_tracks_per_album)
        if not cached_tracks:
            return []

        albums: List[MusicAlbumResponse] = []
        for index in range(0, len(cached_tracks), max_tracks_per_album):
            chunk = cached_tracks[index : index + max_tracks_per_album]
            if len(chunk) < min_tracks_per_album:
                break
            album_number = len(albums) + 1
            albums.append(
                MusicAlbumResponse(
                    album_id=f"cached-{mood.value}-{album_number}",
                    album_title=f"{mood.value.title()} Mix {album_number}",
                    album_image_url=chunk[0].album_image_url or chunk[0].thumbnail_url,
                    tracks=chunk,
                )
            )
            if len(albums) >= album_limit:
                break
        return albums

    def _map_itunes_track(
        self,
        track: Dict[str, object],
        mood: Optional[MoodCategory],
    ) -> Tuple[MusicTrackCreate, Dict[str, object]]:
        track_id_raw = track.get("trackId") or track.get("collectionId")
        track_id = str(track_id_raw).strip() if track_id_raw is not None else ""
        if not track_id:
            raise ValueError("iTunes track missing identifier")

        title_raw = track.get("trackName") or track.get("collectionName")
        title = str(title_raw).strip() if title_raw else ""
        if not title:
            raise ValueError("iTunes track missing title")

        artist_raw = track.get("artistName")
        artist = str(artist_raw).strip() if artist_raw else "Unknown Artist"

        duration_ms = track.get("trackTimeMillis")
        duration_seconds = 0
        if isinstance(duration_ms, (int, float)):
            duration_seconds = int(duration_ms / 1000)
        elif isinstance(duration_ms, str):
            try:
                duration_seconds = int(float(duration_ms) / 1000)
            except ValueError:
                duration_seconds = 0
        duration_seconds = max(duration_seconds, 0)

        artwork_raw = track.get("artworkUrl100") or track.get("artworkUrl60")
        artwork_url = self._normalize_artwork_url(artwork_raw)

        preview_url = track.get("previewUrl")

        payload = MusicTrackCreate.model_validate(
            {
                "music_id": track_id,
                "title": title,
                "artist": artist,
                "duration_seconds": duration_seconds,
                "thumbnail_url": artwork_url,
                "album_image_url": artwork_url,
                "audio_url": preview_url,
                "mood_category": mood,
                "added_at": datetime.utcnow(),
                "play_count": 0,
            }
        )
        extra = {"audio_url": preview_url} if preview_url else {}
        return payload, extra

    def _map_doc(self, doc: Optional[dict]) -> dict:
        if not doc:
            raise ValueError("Music track not found")
        data = dict(doc)
        data.pop("_id", None)

        mood_value = data.get("mood_category")
        if isinstance(mood_value, str):
            try:
                data["mood_category"] = MoodCategory(mood_value)
            except ValueError:
                data["mood_category"] = None

        added_at = data.get("added_at")
        if isinstance(added_at, str):
            try:
                data["added_at"] = datetime.fromisoformat(added_at)
            except ValueError:
                data["added_at"] = datetime.utcnow()
        elif not isinstance(added_at, datetime):
            data["added_at"] = datetime.utcnow()

        # Normalize artwork if previously stored with other sizes
        for key in ("thumbnail_url", "album_image_url"):
            if isinstance(data.get(key), str):
                data[key] = self._normalize_artwork_url(data[key])

        return data

    def _fetch_itunes_tracks(
        self,
        term: str,
        limit: int,
        *,
        entity: str = "song",
    ) -> List[Dict[str, object]]:
        params = {
            "term": term,
            "media": "music",
            "entity": entity,
            "limit": min(max(limit, 1), MAX_ITUNES_LIMIT),
            "country": self._country,
        }

        close_client = False
        client: httpx.Client
        if self._http is None:
            client = httpx.Client(timeout=10.0)
            close_client = True
        else:
            client = self._http

        try:
            response = client.get(ITUNES_SEARCH_URL, params=params)
            response.raise_for_status()
            payload = response.json()
        except httpx.HTTPError as exc:
            raise ITunesAPIError(f"iTunes API request failed: {exc}") from exc
        except ValueError as exc:
            raise ITunesAPIError(f"Unable to decode iTunes response: {exc}") from exc
        finally:
            if close_client:
                client.close()

        results = payload.get("results")
        if not isinstance(results, list):
            raise ITunesAPIError("Unexpected iTunes response structure")
        return cast(List[Dict[str, object]], results)

    def _search_term_for_mood(self, mood: Union[MoodType, str]) -> str:
        key = ""
        if isinstance(mood, MoodType):
            key = self.MOODTYPE_ALIASES.get(mood, mood.value).lower()
        else:
            key = str(mood).strip().lower()

        return self.MOOD_REPAIR_TERMS.get(key, "feel good happy uplifting")

    def _category_for_mood(self, mood: Union[MoodType, str]) -> Optional[MoodCategory]:
        if isinstance(mood, MoodType):
            return self.CATEGORY_BY_MOOD.get(mood)
        try:
            mood_type = MoodType(str(mood).lower())
            return self.CATEGORY_BY_MOOD.get(mood_type)
        except ValueError:
            return None

    @staticmethod
    def _normalize_artwork_url(value: Optional[object]) -> Optional[str]:
        if not isinstance(value, str) or not value:
            return None
        return value.replace("100x100", "600x600")