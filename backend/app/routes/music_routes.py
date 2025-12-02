from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query

from ..config.settings import SPOTIFY_DEFAULT_MARKET
from ..models.music_schemas import (
    MoodType,
    MusicListeningSessionCreate,
    MusicListeningSessionResponse,
    MusicTrackResponse,
    PlaylistSongRequest,
    UserPlaylistCreate,
    UserPlaylistResponse,
    UserPlaylistUpdate,
)
from ..models.database import db
from ..services.music_service import MusicService
from ..services.spotify_client import SpotifyAuthError
from ..services.user_playlist_service import (
    MusicListeningSessionService,
    UserPlaylistService,
)

router = APIRouter(prefix="/music", tags=["Music"])

music_service = MusicService(db)
playlist_service = UserPlaylistService(db)
session_service = MusicListeningSessionService(db)


@router.get("/recommendations", response_model=List[MusicTrackResponse])
def get_recommendations(
    mood: MoodType = Query(..., description="User mood to tailor recommendations"),
    limit: int = Query(10, ge=1, le=50),
    market: Optional[str] = Query(None, description="Spotify market code, e.g. US"),
):
    try:
        return music_service.recommend_by_mood(mood, limit=limit, market=market or SPOTIFY_DEFAULT_MARKET)
    except SpotifyAuthError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.get("/search", response_model=List[MusicTrackResponse])
def search_music(
    query: str = Query(..., min_length=2, description="Search term sent to Spotify"),
    limit: int = Query(10, ge=1, le=50),
    market: Optional[str] = Query(None, description="Spotify market code, e.g. US"),
):
    try:
        return music_service.search_tracks(query, limit=limit, market=market or SPOTIFY_DEFAULT_MARKET)
    except SpotifyAuthError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.post("/playlists", response_model=UserPlaylistResponse, status_code=201)
def create_playlist(payload: UserPlaylistCreate) -> UserPlaylistResponse:
    return playlist_service.create_playlist(payload)


@router.get("/playlists", response_model=List[UserPlaylistResponse])
def list_playlists(
    user_id: Optional[str] = Query(None, description="Filter playlists by owner"),
    include_public: bool = Query(False, description="Include public playlists when no user is provided"),
) -> List[UserPlaylistResponse]:
    if user_id:
        return playlist_service.list_playlists(user_id)
    if include_public:
        return playlist_service.list_public_playlists()
    raise HTTPException(status_code=400, detail="user_id must be provided unless include_public is true")


@router.get("/playlists/{playlist_id}", response_model=UserPlaylistResponse)
def get_playlist(playlist_id: str) -> UserPlaylistResponse:
    playlist = playlist_service.get_playlist(playlist_id)
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    return playlist


@router.patch("/playlists/{playlist_id}", response_model=UserPlaylistResponse)
def update_playlist(playlist_id: str, payload: UserPlaylistUpdate) -> UserPlaylistResponse:
    updated = playlist_service.update_playlist(playlist_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="Playlist not found")
    return updated


@router.delete("/playlists/{playlist_id}", status_code=204)
def delete_playlist(playlist_id: str) -> None:
    removed = playlist_service.delete_playlist(playlist_id)
    if not removed:
        raise HTTPException(status_code=404, detail="Playlist not found")


@router.post("/playlists/{playlist_id}/songs", response_model=UserPlaylistResponse)
def add_song_to_playlist(playlist_id: str, payload: PlaylistSongRequest) -> UserPlaylistResponse:
    # Ensure the track exists in the central music catalog.
    music_service.ensure_track(payload)
    updated = playlist_service.add_song(playlist_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="Playlist not found")
    return updated


@router.delete("/playlists/{playlist_id}/songs/{music_id}", response_model=UserPlaylistResponse)
def remove_song_from_playlist(playlist_id: str, music_id: str) -> UserPlaylistResponse:
    updated = playlist_service.remove_song(playlist_id, music_id)
    if not updated:
        raise HTTPException(status_code=404, detail="Playlist not found")
    return updated


@router.post("/sessions", response_model=MusicListeningSessionResponse, status_code=201)
def log_listening_session(payload: MusicListeningSessionCreate) -> MusicListeningSessionResponse:
    try:
        return session_service.log_session(payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/sessions", response_model=List[MusicListeningSessionResponse])
def list_listening_sessions(
    user_id: str = Query(..., description="User ID to fetch listening history"),
    limit: int = Query(50, ge=1, le=200),
) -> List[MusicListeningSessionResponse]:
    return session_service.list_sessions(user_id, limit=limit)
