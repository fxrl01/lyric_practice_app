import json
from typing import Annotated

from fastapi import Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from lyricflow_backend.domain.ports import RecognitionResult
from lyricflow_backend.domain.recognition_repository import RecognitionRepository
from lyricflow_backend.infrastructure.database import get_session
from lyricflow_backend.infrastructure.models import RecognitionModel, SongModel


class SqlAlchemyRecognitionRepository(RecognitionRepository):
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def save(
        self,
        *,
        result: RecognitionResult,
        duration_ms: int,
    ) -> None:
        song_id: str | None = None
        confidence: float | None = None
        provider: str | None = None

        if result.song is not None:
            song_id = str(result.song["id"])
            provider = str(result.song.get("source", "unknown"))
            raw_confidence = result.song.get("confidence")
            confidence = (
                float(raw_confidence)
                if isinstance(raw_confidence, (int, float))
                else None
            )
            await self._session.merge(
                SongModel(
                    id=song_id,
                    title=str(result.song.get("title", "")),
                    artist=str(result.song.get("artist", "")),
                    album=_optional_string(result.song.get("album")),
                    source=provider,
                    external_links_json=json.dumps(
                        result.song.get("external_links", {})
                    ),
                )
            )

        self._session.add(
            RecognitionModel(
                song_id=song_id,
                status=result.status,
                provider=provider,
                duration_ms=duration_ms,
                confidence=confidence,
            )
        )
        await self._session.commit()

    async def history(
        self,
        *,
        limit: int,
        offset: int,
    ) -> tuple[list[dict[str, object]], int]:
        total = await self._session.scalar(
            select(func.count()).select_from(RecognitionModel)
        )
        rows = (
            await self._session.execute(
                select(RecognitionModel, SongModel)
                .outerjoin(SongModel, RecognitionModel.song_id == SongModel.id)
                .order_by(RecognitionModel.created_at.desc(), RecognitionModel.id.desc())
                .offset(offset)
                .limit(limit)
            )
        ).all()
        return [
            {
                "id": recognition.id,
                "status": recognition.status,
                "provider": recognition.provider,
                "duration_ms": recognition.duration_ms,
                "confidence": recognition.confidence,
                "created_at": recognition.created_at,
                "song": (
                    {
                        "id": song.id,
                        "title": song.title,
                        "artist": song.artist,
                        "album": song.album,
                        "source": song.source,
                    }
                    if song is not None
                    else None
                ),
            }
            for recognition, song in rows
        ], int(total or 0)


def _optional_string(value: object) -> str | None:
    return value if isinstance(value, str) else None


def get_recognition_repository(
    session: Annotated[
        AsyncSession,
        Depends(get_session),
    ],
) -> RecognitionRepository:
    return SqlAlchemyRecognitionRepository(session)
