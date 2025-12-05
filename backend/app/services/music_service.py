from __future__ import annotations

import random
from datetime import datetime
from typing import Any, Dict, List, Optional, Set, Tuple, cast
import re
import requests
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
    PlaylistSongRequest,
    MoodTherapyPlaylist,
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

    MOODTYPE_ALIASES: Dict[MoodType, str] = {
        MoodType.sad: "sad",
        MoodType.awful: "stressed",
        MoodType.neutral: "tired",
        MoodType.happy: "happy",
        MoodType.very_happy: "happy",
    }

    PASTEL_COLORS: List[str] = [
        "#FFCDD2", "#F8BBD0", "#E1BEE7", "#D1C4E9", "#C5CAE9", "#B2DFDB", "#FFCCBC", "#FFF9C4", "#FFE082"
    ]

    # Curated blueprints for each mood bracket used when assembling playlists.
    THERAPY_BLUEPRINTS: Dict[str, List[Dict[str, Any]]] = {
        "sad": [
            {
                "playlist_type": "catharsis",
                "title": "Catharsis",
                "icon": "water_drop",
                "strategy": "Match the mood to process emotions safely.",
                "search_terms": [
                    "Blues",
                    "Sentimental Ballad",
                    "Acoustic Folk",
                    "Sad Piano",
                ],
            },
            {
                "playlist_type": "mood_boost",
                "title": "Mood Boost",
                "icon": "wb_sunny",
                "strategy": "Offer uplifting energy without feeling forced.",
                "search_terms": [
                    "Upbeat Pop",
                    "Funk Soul",
                    "Reggae",
                    "Motivating Rock",
                ],
            },
            {
                "playlist_type": "deep_focus",
                "title": "Deep Focus",
                "icon": "book",
                "strategy": "Provide calm, neutral ambience for gentle distraction.",
                "search_terms": [
                    "Dark Classical",
                    "Instrumental",
                    "Ambient",
                    "Cinematic Piano",
                ],
            },
        ],
        "happy": [
            {
                "playlist_type": "celebrate",
                "title": "Celebrate",
                "icon": "celebration",
                "strategy": "Lean into the upbeat mood with vibrant anthems.",
                "search_terms": [
                    "Feel Good Pop",
                    "Dance Hits",
                    "Nu Disco",
                    "Sunshine Indie",
                ],
            },
            {
                "playlist_type": "balanced",
                "title": "Keep Glowing",
                "icon": "spa",
                "strategy": "Sustain positivity with relaxed grooves.",
                "search_terms": [
                    "Chill Pop",
                    "Tropical House",
                    "Bright Acoustic",
                    "Warm Indie",
                ],
            },
            {
                "playlist_type": "share",
                "title": "Throwbacks",
                "icon": "star",
                "strategy": "Invite nostalgia and sing-along moments.",
                "search_terms": [
                    "Sing Along Classics",
                    "Throwback Pop",
                    "Feelgood Rock",
                    "Family Favorites",
                ],
            },
        ],
        "angry": [
            {
                "playlist_type": "release",
                "title": "Release Fire",
                "icon": "local_fire_department",
                "strategy": "Channel intensity through powerful sounds.",
                "search_terms": [
                    "Heavy Metal",
                    "Hard Rock",
                    "Rap Rock",
                    "Industrial",
                ],
            },
            {
                "playlist_type": "calm",
                "title": "Calm Down",
                "icon": "spa",
                "strategy": "Lower the pulse with gentle textures.",
                "search_terms": [
                    "Lo-Fi Beats",
                    "Chillhop",
                    "Neo Classical",
                    "Ambient Guitar",
                ],
            },
            {
                "playlist_type": "channel",
                "title": "Channel Energy",
                "icon": "bolt",
                "strategy": "Transform energy into forward motion.",
                "search_terms": [
                    "Workout Motivation",
                    "Power EDM",
                    "Trap Workout",
                    "High Energy Pop",
                ],
            },
        ],
        "anxious": [
            {
                "playlist_type": "steady",
                "title": "Steady Breath",
                "icon": "air",
                "strategy": "Regulate breathing with guided calm.",
                "search_terms": [
                    "Guided Meditation",
                    "Calming Piano",
                    "Breathwork Ambient",
                    "Soothing Drone",
                ],
            },
            {
                "playlist_type": "lift",
                "title": "Gentle Lift",
                "icon": "spa",
                "strategy": "Introduce hopeful tones without overwhelm.",
                "search_terms": [
                    "Soft Pop",
                    "Positive Acoustic",
                    "Comfort Folk",
                    "Warm Indie",
                ],
            },
            {
                "playlist_type": "focus",
                "title": "Restful Focus",
                "icon": "headphones",
                "strategy": "Offer steady background for mindful tasks.",
                "search_terms": [
                    "Lo-Fi Study",
                    "Instrumental Study",
                    "Binaural Beats",
                    "Ambient Concentration",
                ],
            },
        ],
        "generic": [
            {
                "playlist_type": "reset",
                "title": "Daily Reset",
                "icon": "refresh",
                "strategy": "Balanced mix for any starting point.",
                "search_terms": [
                    "Feel Good Pop",
                    "Indie Chill",
                    "Morning Acoustic",
                    "Lofi Sunshine",
                ],
            },
            {
                "playlist_type": "motivate",
                "title": "Momentum",
                "icon": "trending_up",
                "strategy": "Spark momentum with bright rhythms.",
                "search_terms": [
                    "Confidence Pop",
                    "Workout Pop",
                    "Electro Motivation",
                    "Feelgood EDM",
                ],
            },
            {
                "playlist_type": "unwind",
                "title": "Unwind",
                "icon": "nightlight_round",
                "strategy": "Ease tension with tranquil instrumentals.",
                "search_terms": [
                    "Chillhop",
                    "Peaceful Piano",
                    "Dream Ambient",
                    "Downtempo",
                ],
            },
        ],
    }

    THERAPY_CATEGORY_BY_KEY: Dict[str, Optional[MoodCategory]] = {
        "sad": MoodCategory.comfort,
        "happy": MoodCategory.hopeful,
        "angry": MoodCategory.empowered,
        "anxious": MoodCategory.anxious,
        "generic": MoodCategory.calm,
    }

    MOOD_NORMALIZATION: Dict[str, str] = {
        "sad": "sad",
        "depressed": "sad",
        "down": "sad",
        "low": "sad",
        "blue": "sad",
        "awful": "sad",
        "upset": "sad",
        "crying": "sad",
        "tearful": "sad",
        "happy": "happy",
        "joy": "happy",
        "joyful": "happy",
        "excited": "happy",
        "very happy": "happy",
        "positive": "happy",
        "angry": "angry",
        "mad": "angry",
        "furious": "angry",
        "frustrated": "angry",
        "irritated": "angry",
        "anxious": "anxious",
        "worried": "anxious",
        "nervous": "anxious",
        "stressed": "anxious",
        "overwhelmed": "anxious",
        "neutral": "generic",
        "tired": "generic",
        "calm": "generic",
        "fine": "generic",
    }

    MOOD_TIMESTAMP_FIELDS: Tuple[str, ...] = (
        "recorded_at",
        "created_at",
        "updated_at",
        "timestamp",
        "logged_at",
    )

    DEFAULT_PLAYLIST_SIZE = 10
    REQUEST_TIMEOUT = 10.0

    def __init__(
        self,
        db: Database,
        *,
        country: str = DEFAULT_COUNTRY,
    ) -> None:
        self._db = db
        self.collection: Collection = db["music_tracks"]
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

    def get_mood_playlists(self, user_id: str) -> List[MoodTherapyPlaylist]:
        mood_key, mood_label = self._resolve_user_mood(user_id)
        blueprints = self.THERAPY_BLUEPRINTS.get(mood_key) or self.THERAPY_BLUEPRINTS["generic"]
        category = self.THERAPY_CATEGORY_BY_KEY.get(mood_key) or MoodCategory.calm

        playlists: List[MoodTherapyPlaylist] = []
        global_seen: Set[str] = set()

        for blueprint in blueprints:
            search_terms = [str(term) for term in blueprint.get("search_terms", []) if str(term).strip()]
            playlist_tracks = self._build_playlist_from_terms(search_terms, category, global_seen)

            if len(playlist_tracks) < self.DEFAULT_PLAYLIST_SIZE and category:
                needed = self.DEFAULT_PLAYLIST_SIZE - len(playlist_tracks)
                fallback_tracks = self._fallback_from_cache(category, needed * 3)
                for cached in fallback_tracks:
                    if cached.music_id in global_seen:
                        continue
                    playlist_tracks.append(self._as_playlist_song(cached))
                    global_seen.add(cached.music_id)
                    if len(playlist_tracks) >= self.DEFAULT_PLAYLIST_SIZE:
                        break

            playlists.append(
                MoodTherapyPlaylist(
                    mood_key=mood_key,
                    mood_label=mood_label,
                    playlist_type=str(blueprint.get("playlist_type", "custom")),
                    title=str(blueprint.get("title", "Mood Therapy Mix")),
                    strategy=str(blueprint.get("strategy", "")),
                    search_terms=search_terms,
                    tracks=playlist_tracks[: self.DEFAULT_PLAYLIST_SIZE],
                    icon=str(blueprint.get("icon", "music_note")),
                    color=random.choice(self.PASTEL_COLORS),
                )
            )

        return playlists

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
            raw_tracks = self._search_itunes_via_requests(
                query,
                limit=limit * 2,
            )
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

    def _build_playlist_from_terms(
        self,
        search_terms: List[str],
        category: Optional[MoodCategory],
        global_seen: Set[str],
    ) -> List[PlaylistSong]:
        if not search_terms:
            return []

        tracks: List[PlaylistSong] = []
        local_seen: Set[str] = set()

        for term in search_terms:
            cleaned_term = term.strip()
            if not cleaned_term:
                continue
            try:
                raw_tracks = self._search_itunes_via_requests(
                    cleaned_term,
                    limit=self.DEFAULT_PLAYLIST_SIZE * 4,
                )
            except ITunesAPIError:
                continue

            for raw in raw_tracks:
                try:
                    payload, extra = self._map_itunes_track(raw, category)
                except ValueError:
                    continue

                stored = self._persist_and_response(payload, extra)
                if stored.music_id in global_seen or stored.music_id in local_seen:
                    continue

                tracks.append(self._as_playlist_song(stored))
                local_seen.add(stored.music_id)
                global_seen.add(stored.music_id)

                if len(tracks) >= self.DEFAULT_PLAYLIST_SIZE:
                    return tracks

        return tracks

    def _as_playlist_song(self, track: MusicTrackResponse) -> PlaylistSong:
        return PlaylistSong(
            music_id=track.music_id,
            title=track.title,
            artist=track.artist,
            duration_seconds=track.duration_seconds,
            thumbnail_url=track.thumbnail_url,
            album_image_url=track.album_image_url,
            audio_url=track.audio_url,
            mood_category=track.mood_category,
            is_liked=track.is_liked,
        )

    def _resolve_user_mood(self, user_id: str) -> Tuple[str, str]:
        try:
            mood_collection = self._db["mood_tracking"]
        except Exception:
            return "generic", "Balanced"

        base_query = {"user_id": user_id}
        doc: Optional[dict] = None
        try:
            for field in self.MOOD_TIMESTAMP_FIELDS:
                doc = mood_collection.find_one(
                    {**base_query, field: {"$exists": True}},
                    sort=[(field, -1)],
                )
                if doc:
                    break

            if not doc:
                doc = mood_collection.find_one(base_query, sort=[("created_at", -1)])
            if not doc:
                doc = mood_collection.find_one(base_query, sort=[("_id", -1)])
        except Exception:
            return "generic", "Balanced"

        raw_mood = self._extract_mood_value(doc)
        mood_key = self._normalize_mood_key(raw_mood)
        mood_label = self._display_mood_label(mood_key, raw_mood)
        return mood_key, mood_label

    def _extract_mood_value(self, doc: Optional[dict]) -> Optional[object]:
        if not doc:
            return None

        string_fields = (
            "mood",
            "mood_level",
            "mood_value",
            "mood_label",
            "mood_type",
            "emotion",
            "feeling",
            "state",
            "selected_mood",
            "mood_text",
        )
        numeric_fields = (
            "mood_score",
            "score",
            "rating",
            "value",
        )

        for field in string_fields:
            value = doc.get(field)
            if isinstance(value, str) and value.strip():
                return value
            if isinstance(value, MoodType):
                return value

        for field in numeric_fields:
            value = doc.get(field)
            if isinstance(value, (int, float)):
                return float(value)
            if isinstance(value, str) and value.strip():
                try:
                    return float(value)
                except ValueError:
                    continue

        fallback = doc.get("mood")
        if isinstance(fallback, (int, float)):
            return float(fallback)

        return None

    def _normalize_mood_key(self, raw: Optional[object]) -> str:
        if raw is None:
            return "generic"
        if isinstance(raw, MoodType):
            alias = self.MOODTYPE_ALIASES.get(raw)
            if alias:
                return self.MOOD_NORMALIZATION.get(alias, "generic")
            return self.MOOD_NORMALIZATION.get(raw.value.lower(), "generic")
        if isinstance(raw, str):
            cleaned = raw.strip().lower()
            if not cleaned:
                return "generic"
            if cleaned in self.MOOD_NORMALIZATION:
                return self.MOOD_NORMALIZATION[cleaned]
            base = cleaned.split()[0]
            return self.MOOD_NORMALIZATION.get(base, "generic")
        if isinstance(raw, (int, float)):
            return self._mood_from_score(float(raw))
        return "generic"

    def _display_mood_label(self, mood_key: str, raw: Optional[object]) -> str:
        if isinstance(raw, str) and raw.strip():
            return raw.strip().title()[:64]

        fallback_labels = {
            "sad": "Sad",
            "happy": "Happy",
            "angry": "Angry",
            "anxious": "Anxious",
            "generic": "Balanced",
        }
        return fallback_labels.get(mood_key, "Balanced")

    def _mood_from_score(self, score: float) -> str:
        if score >= 4.0:
            return "happy"
        if score >= 3.0:
            return "generic"
        if score >= 2.0:
            return "sad"
        return "anxious"

    def _search_itunes_via_requests(
        self,
        term: str,
        *,
        limit: int,
    ) -> List[Dict[str, object]]:
        params = {
            "term": term,
            "media": "music",
            "entity": "song",
            "limit": min(max(limit, 1), MAX_ITUNES_LIMIT),
            "country": self._country,
        }

        try:
            response = requests.get(
                ITUNES_SEARCH_URL,
                params=params,
                timeout=self.REQUEST_TIMEOUT,
            )
            response.raise_for_status()
            payload = response.json()
        except requests.RequestException as exc:
            raise ITunesAPIError(f"iTunes API request failed: {exc}") from exc
        except ValueError as exc:
            raise ITunesAPIError(f"Unable to decode iTunes response: {exc}") from exc

        results = payload.get("results") if isinstance(payload, dict) else None
        if not isinstance(results, list):
            raise ITunesAPIError("Unexpected iTunes response structure")
        return cast(List[Dict[str, object]], results)

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

    @staticmethod
    def _normalize_artwork_url(value: Optional[object]) -> Optional[str]:
        if not isinstance(value, str) or not value:
            return None
        return value.replace("100x100", "600x600")