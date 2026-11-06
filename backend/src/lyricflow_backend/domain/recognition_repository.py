from typing import Protocol

from lyricflow_backend.domain.ports import RecognitionResult


class RecognitionRepository(Protocol):
    async def save(
        self,
        *,
        result: RecognitionResult,
        duration_ms: int,
    ) -> None:
        """Persist a normalized recognition result."""

    async def history(self, *, limit: int, offset: int) -> tuple[list[dict[str, object]], int]:
        """Return recent recognition records and the total count."""
