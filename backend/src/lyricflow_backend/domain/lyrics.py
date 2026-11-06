from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class LyricsResult:
    title: str
    artist: str
    lines: list[str]
    language: str = "unknown"
    source: str = "lyrics_ovh"
    attribution: str = "Lyrics via lyrics.ovh"


class LyricsProviderPort(Protocol):
    async def get_lyrics(self, *, title: str, artist: str) -> LyricsResult:
        """Return pass-through lyrics from a configured provider."""

