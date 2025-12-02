from __future__ import annotations

import base64
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import httpx


class SpotifyAuthError(RuntimeError):
    pass


class SpotifyClient:
    TOKEN_URL = "https://accounts.spotify.com/api/token"
    BASE_URL = "https://api.spotify.com/v1"

    def __init__(self, client_id: str, client_secret: str, *, timeout: float = 10.0):
        if not client_id or not client_secret:
            raise SpotifyAuthError("Spotify client credentials are not configured.")
        self.client_id = client_id
        self.client_secret = client_secret
        self.timeout = timeout
        self._access_token: str | None = None
        self._token_expiry: datetime | None = None

    def _encoded_credentials(self) -> str:
        credentials = f"{self.client_id}:{self.client_secret}".encode("utf-8")
        return base64.b64encode(credentials).decode("utf-8")

    def _request_access_token(self) -> str:
        headers = {"Authorization": f"Basic {self._encoded_credentials()}", "Content-Type": "application/x-www-form-urlencoded"}
        data = {"grant_type": "client_credentials"}
        with httpx.Client(timeout=self.timeout) as client:
            response = client.post(self.TOKEN_URL, data=data, headers=headers)
        if response.status_code != 200:
            raise SpotifyAuthError(f"Failed to authenticate with Spotify: {response.text}")
        payload = response.json()
        access_token = payload.get("access_token")
        expires_in = payload.get("expires_in", 3600)
        if not access_token:
            raise SpotifyAuthError("Spotify did not return an access token")
        self._access_token = access_token
        self._token_expiry = datetime.utcnow() + timedelta(seconds=int(expires_in) - 60)
        return access_token

    def _get_access_token(self) -> str:
        if self._access_token and self._token_expiry and datetime.utcnow() < self._token_expiry:
            return self._access_token
        return self._request_access_token()

    def _headers(self) -> Dict[str, str]:
        token = self._get_access_token()
        return {"Authorization": f"Bearer {token}"}

    def _get(self, path: str, *, params: Dict[str, str]) -> Dict:
        url = f"{self.BASE_URL}{path}"
        with httpx.Client(timeout=self.timeout) as client:
            response = client.get(url, params=params, headers=self._headers())
        response.raise_for_status()
        return response.json()

    def search_tracks(self, query: str, *, limit: int = 10, market: str = "US") -> List[Dict]:
        payload = self._get(
            "/search",
            params={"q": query, "type": "track", "limit": str(limit), "market": market},
        )
        tracks = payload.get("tracks", {}).get("items", [])
        return tracks

    def get_recommendations(
        self,
        *,
        seed_tracks: Optional[List[str]] = None,
        seed_genres: Optional[List[str]] = None,
        seed_artists: Optional[List[str]] = None,
        limit: int = 10,
        market: str = "US",
        targets: Optional[Dict[str, float]] = None,
    ) -> List[Dict]:
        params: Dict[str, str] = {"limit": str(limit), "market": market}
        if seed_tracks:
            params["seed_tracks"] = ",".join(seed_tracks[:5])
        if seed_genres:
            params["seed_genres"] = ",".join(seed_genres[:5])
        if seed_artists:
            params["seed_artists"] = ",".join(seed_artists[:5])
        if targets:
            for key, value in targets.items():
                params[key] = str(value)
        payload = self._get("/recommendations", params=params)
        return payload.get("tracks", [])