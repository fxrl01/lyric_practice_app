from urllib.parse import quote

import httpx

from lyricflow_backend.domain.lyrics import LyricsProviderPort, LyricsResult


class LyricsNotFoundError(LookupError):
    """Raised when a provider has no lyrics for a song."""


class LyricsProviderUnavailableError(ConnectionError):
    """Raised when the lyrics provider cannot be reached."""


class LyricsOvhProvider:
    def __init__(
        self,
        *,
        base_url: str = "https://api.lyrics.ovh/v1",
        timeout_seconds: float = 10.0,
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._timeout_seconds = timeout_seconds

    async def get_lyrics(self, *, title: str, artist: str) -> LyricsResult:
        url = (
            f"{self._base_url}/{quote(artist.strip(), safe='')}"
            f"/{quote(title.strip(), safe='')}"
        )
        try:
            async with httpx.AsyncClient(timeout=self._timeout_seconds) as client:
                response = await client.get(url)
        except httpx.TimeoutException as exc:
            raise LyricsProviderUnavailableError(
                "The lyrics provider timed out."
            ) from exc
        except httpx.HTTPError as exc:
            raise LyricsProviderUnavailableError(
                "The lyrics provider is unavailable."
            ) from exc

        if response.status_code == 404:
            raise LyricsNotFoundError("No lyrics were found for this song.")
        try:
            response.raise_for_status()
            lyrics = response.json().get("lyrics")
        except (httpx.HTTPError, ValueError) as exc:
            raise LyricsProviderUnavailableError(
                "The lyrics provider returned an invalid response."
            ) from exc

        if not isinstance(lyrics, str) or not lyrics.strip():
            raise LyricsNotFoundError("No lyrics were found for this song.")

        return LyricsResult(
            title=title,
            artist=artist,
            lines=[line.strip() for line in lyrics.splitlines()],
        )


def get_lyrics_provider() -> LyricsProviderPort:
    return LyricsOvhProvider()
