from __future__ import annotations

from typing import Dict, List, Optional

import httpx


class JamendoError(RuntimeError):
    "Base class for Jamendo related errors."


class JamendoAuthError(JamendoError):
    "Raised when Jamendo credentials are missing or invalid."


class JamendoServiceError(JamendoError):
    "Raised when Jamendo returns an unexpected response."


class JamendoClient:
    base_url = "https://api.jamendo.com/v3.0"

    def __init__(
        self,
        client_id: str,
        *,
        timeout: float = 10.0,
        default_lang: str = "en",
        default_order: str = "popularity_total",
    ) -> None:
        if not client_id:
            raise JamendoAuthError("Jamendo client id is not configured.")
        self.client_id = client_id
        self.timeout = timeout
        self.default_lang = default_lang
        self.default_order = default_order

    def _request(
        self,
        endpoint: str,
        params: Dict[str, object],
        *,
        lang: Optional[str] = None,
    ) -> List[Dict]:
        request_params: Dict[str, object] = {
            "client_id": self.client_id,
            "format": "json",
            "include": "musicinfo",
            "lang": (lang or self.default_lang) or "en",
            **params,
        }
        url = f"{self.base_url}{endpoint}"
        try:
            response = httpx.get(url, params=request_params, timeout=self.timeout)
        except httpx.HTTPError as exc:  # pragma: no cover - network failure
            raise JamendoServiceError("Unable to reach Jamendo API") from exc
        if response.status_code != httpx.codes.OK:
            raise JamendoServiceError(
                f"Jamendo error {response.status_code}: {response.text[:200]}"
            )
        payload = response.json()
        headers = payload.get("headers", {})
        if headers.get("status") != "success":
            message = headers.get("error_message") or "Jamendo request failed"
            raise JamendoServiceError(message)
        results = payload.get("results")
        if not isinstance(results, list):
            raise JamendoServiceError("Jamendo response missing results list")
        return results

    def search_tracks(
        self,
        query: str,
        *,
        limit: int = 20,
        language: Optional[str] = None,
        order: Optional[str] = None,
    ) -> List[Dict]:
        if not query.strip():
            return []
        params: Dict[str, object] = {
            "search": query,
            "limit": max(1, min(limit, 50)),
            "fuzzysearch": True,
            "audioformat": "mp32",
            "order": order or self.default_order,
        }
        return self._request("/tracks", params, lang=language)

    def get_tracks_by_tags(
        self,
        tags: List[str],
        *,
        limit: int = 20,
        language: Optional[str] = None,
        order: Optional[str] = None,
    ) -> List[Dict]:
        if not tags:
            return []
        params: Dict[str, object] = {
            "tags": ",".join(tags),
            "limit": max(1, min(limit, 50)),
            "audioformat": "mp32",
            "order": order or self.default_order,
        }
        return self._request("/tracks", params, lang=language)
