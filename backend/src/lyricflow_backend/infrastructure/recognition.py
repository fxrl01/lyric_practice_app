from base64 import b64decode, binascii
from typing import Any

import httpx

from lyricflow_backend.domain.ports import RecognitionResult, SongRecognitionPort
from lyricflow_backend.infrastructure.settings import Settings, get_settings


class RecognitionConfigurationError(RuntimeError):
    """Raised when a provider cannot be used with the current configuration."""


class AuddSongRecognition:
    def __init__(
        self,
        *,
        api_key: str,
        base_url: str,
        timeout_seconds: float,
    ) -> None:
        self._api_key = api_key
        self._url = f"{base_url.rstrip('/')}/"
        self._timeout = timeout_seconds

    async def recognize(
        self,
        *,
        audio_base64: str,
        duration_ms: int,
        is_humming: bool,
    ) -> RecognitionResult:
        if not self._api_key:
            raise RecognitionConfigurationError(
                "The AudD API key is not configured on the backend."
            )
        try:
            audio = b64decode(audio_base64, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise ValueError("audio_base64 is not valid base64.") from exc

        if not audio:
            raise ValueError("The audio sample is empty.")

        del duration_ms, is_humming
        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(
                    self._url,
                    data={
                        "api_token": self._api_key,
                        "return": "spotify,apple_music,deezer",
                    },
                    files={"audio": ("sample.wav", audio, "audio/wav")},
                )
                response.raise_for_status()
        except httpx.TimeoutException as exc:
            raise TimeoutError("The recognition provider timed out.") from exc
        except httpx.HTTPError as exc:
            raise ConnectionError("The recognition provider is unavailable.") from exc

        payload = response.json()
        if payload.get("status") == "error":
            message = _provider_error_message(payload)
            return RecognitionResult(status="failed", message=message)
        result = payload.get("result")
        if not isinstance(result, dict):
            return RecognitionResult(
                status="not_found",
                message="No song was recognized from the audio sample.",
            )

        return RecognitionResult(
            status="recognized",
            message="Song recognized successfully.",
            song=_normalize_song(result),
        )


class UnconfiguredSongRecognition:
    async def recognize(
        self,
        *,
        audio_base64: str,
        duration_ms: int,
        is_humming: bool,
    ) -> RecognitionResult:
        del audio_base64, duration_ms, is_humming
        return RecognitionResult(
            status="not_configured",
            message=(
                "Song recognition is not configured. "
                "Configure a backend provider before using this endpoint."
            ),
        )


def get_song_recognition_port() -> SongRecognitionPort:
    settings = get_settings()
    if settings.recognition_provider.lower() == "audd":
        return AuddSongRecognition(
            api_key=settings.audd_api_key,
            base_url=settings.audd_base_url,
            timeout_seconds=settings.recognition_timeout_seconds,
        )
    return UnconfiguredSongRecognition()


def build_song_recognition_port(settings: Settings) -> SongRecognitionPort:
    if settings.recognition_provider.lower() == "audd":
        return AuddSongRecognition(
            api_key=settings.audd_api_key,
            base_url=settings.audd_base_url,
            timeout_seconds=settings.recognition_timeout_seconds,
        )
    return UnconfiguredSongRecognition()


def _provider_error_message(payload: dict[str, Any]) -> str:
    error = payload.get("error")
    if isinstance(error, dict) and isinstance(error.get("error_message"), str):
        return error["error_message"]
    return "The recognition provider rejected the request."


def _normalize_song(result: dict[str, Any]) -> dict[str, object]:
    spotify = result.get("spotify")
    external_links: dict[str, str] = {}
    if isinstance(spotify, dict):
        external_urls = spotify.get("external_urls")
        if isinstance(external_urls, dict) and isinstance(
            external_urls.get("spotify"), str
        ):
            external_links["spotify"] = external_urls["spotify"]

    apple_music = result.get("apple_music")
    if isinstance(apple_music, dict) and isinstance(apple_music.get("url"), str):
        external_links["apple_music"] = apple_music["url"]

    deezer = result.get("deezer")
    if isinstance(deezer, dict) and isinstance(deezer.get("link"), str):
        external_links["deezer"] = deezer["link"]

    return {
        "id": f"audd_{result.get('song_link', result.get('title', 'unknown'))}",
        "title": result.get("title", "Unknown title"),
        "artist": result.get("artist", "Unknown artist"),
        "album": result.get("album"),
        "release_date": result.get("release_date"),
        "isrc": result.get("isrc"),
        "source": "audd",
        "has_lyrics": True,
        "external_links": external_links,
    }
