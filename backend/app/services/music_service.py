from __future__ import annotations

from datetime import datetime
from typing import Dict, List, Optional, Sequence, Set, cast

from pymongo import ReturnDocument
from pymongo.collection import Collection
from pymongo.database import Database

from ..config.settings import (
    JAMENDO_CLIENT_ID,
    JAMENDO_DEFAULT_LANGUAGE,
    JAMENDO_DEFAULT_ORDER,
)
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
from .jamendo_client import JamendoClient, JamendoError


class MusicService:
    """Serve Jamendo powered music recommendations with MongoDB caching."""

    TAGS_BY_MOOD: Dict[MoodType, Sequence[str]] = {
        MoodType.very_happy: ("upbeat", "dance", "electro"),
        MoodType.happy: ("pop", "feelgood", "sunny"),
        MoodType.neutral: ("ambient", "chill", "instrumental"),
        MoodType.sad: ("acoustic", "piano", "soft"),
        MoodType.awful: ("calm", "soothing", "relax"),
    }

    CATEGORY_BY_MOOD: Dict[MoodType, MoodCategory] = {
        MoodType.very_happy: MoodCategory.empowered,
        MoodType.happy: MoodCategory.hopeful,
        MoodType.neutral: MoodCategory.calm,
        MoodType.sad: MoodCategory.comfort,
        MoodType.awful: MoodCategory.anxious,
    }

    def __init__(self, db: Database, *, jamendo_client: Optional[JamendoClient] = None) -> None:
        self.collection: Collection = db["music_tracks"]
        self.jamendo = jamendo_client or JamendoClient(
            JAMENDO_CLIENT_ID,
            default_lang=JAMENDO_DEFAULT_LANGUAGE,
            default_order=JAMENDO_DEFAULT_ORDER,
        )

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

    def recommend_by_mood(
        self,
        mood: MoodType,
        *,
        limit: int = 10,
        language: Optional[str] = None,
        order: Optional[str] = None,
    ) -> List[MusicTrackResponse]:
        tags = list(self.TAGS_BY_MOOD.get(mood, (mood.value,)))
        mood_category = self.CATEGORY_BY_MOOD.get(mood)
        try:
            jamendo_tracks = self.jamendo.get_tracks_by_tags(
                tags,
                limit=max(limit * 2, limit),
                language=language or JAMENDO_DEFAULT_LANGUAGE,
                order=order or JAMENDO_DEFAULT_ORDER,
            )
        except JamendoError as exc:
            fallback = self._fallback_from_cache(mood_category, limit)
            if fallback:
                return fallback
            raise exc

        results: List[MusicTrackResponse] = []
        seen: Set[str] = set()
        for track in jamendo_tracks:
            try:
                create_payload = self._map_jamendo_track(track, mood_category)
            except ValueError:
                continue
            stored = self._persist_and_response(create_payload)
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
        mood: MoodType,
        *,
        album_limit: int = 3,
        min_tracks_per_album: int = 5,
        max_tracks_per_album: int = 8,
        language: Optional[str] = None,
        order: Optional[str] = None,
    ) -> List[MusicAlbumResponse]:
        album_limit = max(1, min(album_limit, 5))
        min_tracks_per_album = max(1, min(min_tracks_per_album, max_tracks_per_album))
        max_tracks_per_album = max(min_tracks_per_album, min(max_tracks_per_album, 12))

        tags = list(self.TAGS_BY_MOOD.get(mood, (mood.value,)))
        mood_category = self.CATEGORY_BY_MOOD.get(mood)
        try:
            jamendo_tracks = self.jamendo.get_tracks_by_tags(
                tags,
                limit=max(album_limit * max_tracks_per_album * 4, 40),
                language=language or JAMENDO_DEFAULT_LANGUAGE,
                order=order or JAMENDO_DEFAULT_ORDER,
            )
        except JamendoError as exc:
            fallback = self._fallback_albums_from_cache(
                mood_category,
                album_limit,
                min_tracks_per_album,
                max_tracks_per_album,
            )
            if fallback:
                return fallback
            raise exc

        albums_map: Dict[str, Dict[str, object]] = {}
        track_seen: Set[str] = set()

        for raw_track in jamendo_tracks:
            track_id_raw = raw_track.get("id") or raw_track.get("track_id")
            track_id = str(track_id_raw).strip() if track_id_raw is not None else ""
            if not track_id or track_id in track_seen:
                continue

            album_id_raw = (
                raw_track.get("album_id")
                or raw_track.get("albumid")
                or raw_track.get("album")
            )
            album_id = str(album_id_raw).strip() if album_id_raw else f"mix-{track_id}"

            album_name_raw = raw_track.get("album_name") or raw_track.get("album")
            album_title = str(album_name_raw).strip() if album_name_raw else "Mood Mix"
            album_image_value = raw_track.get("album_image") or raw_track.get("image")
            album_image_url = str(album_image_value) if album_image_value else None

            try:
                create_payload = self._map_jamendo_track(raw_track, mood_category)
            except ValueError:
                continue

            stored = self._persist_and_response(create_payload)
            track_seen.add(stored.music_id)

            album_entry = albums_map.setdefault(
                album_id,
                {
                    "title": album_title or stored.title,
                    "image": album_image_url or stored.album_image_url or stored.thumbnail_url,
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
        language: Optional[str] = None,
        order: Optional[str] = None,
    ) -> List[MusicTrackResponse]:
        jamendo_tracks = self.jamendo.search_tracks(
            query,
            limit=limit,
            language=language or JAMENDO_DEFAULT_LANGUAGE,
            order=order or JAMENDO_DEFAULT_ORDER,
        )

        results: List[MusicTrackResponse] = []
        seen: Set[str] = set()
        for track in jamendo_tracks:
            try:
                create_payload = self._map_jamendo_track(track, None)
            except ValueError:
                continue
            stored = self._persist_and_response(create_payload)
            if stored.music_id in seen:
                continue
            seen.add(stored.music_id)
            results.append(stored)
            if len(results) >= limit:
                break
        return results

    def _persist_and_response(self, payload: MusicTrackCreate) -> MusicTrackResponse:
        return self.upsert_track(payload)

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

    def _map_jamendo_track(
        self,
        track: Dict[str, object],
        mood: Optional[MoodCategory],
    ) -> MusicTrackCreate:
        track_id_raw = track.get("id") or track.get("track_id")
        track_id = str(track_id_raw).strip() if track_id_raw is not None else ""
        if not track_id:
            raise ValueError("Jamendo track missing id")

        name_raw = track.get("name") or track.get("title")
        name = str(name_raw).strip() if name_raw else ""
        if not name:
            raise ValueError("Jamendo track missing name")

        artist_raw = track.get("artist_name") or track.get("artist")
        artist = str(artist_raw).strip() if artist_raw else "Unknown Artist"

        duration_raw = track.get("duration") or 0
        duration_seconds = 0
        if isinstance(duration_raw, (int, float)):
            duration_seconds = int(duration_raw)
        elif isinstance(duration_raw, str):
            try:
                duration_seconds = int(float(duration_raw))
            except ValueError:
                duration_seconds = 0

        album_image = track.get("album_image") or track.get("image")
        thumbnail = track.get("image") or album_image

        return MusicTrackCreate.model_validate(
            {
                "music_id": track_id,
                "title": name,
                "artist": artist,
                "duration_seconds": max(duration_seconds, 0),
                "thumbnail_url": str(thumbnail) if thumbnail else None,
                "album_image_url": str(album_image) if album_image else None,
                "mood_category": mood,
                "added_at": datetime.utcnow(),
                "play_count": 0,
            }
        )

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
        return data
