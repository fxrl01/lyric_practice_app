from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class RecognitionResult:
    status: str
    message: str
    song: dict[str, object] | None = None


class SongRecognitionPort(Protocol):
    async def recognize(
        self,
        *,
        audio_base64: str,
        duration_ms: int,
        is_humming: bool,
    ) -> RecognitionResult:
        """Recognize an audio sample through a configured provider."""
