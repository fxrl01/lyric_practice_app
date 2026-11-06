from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from lyricflow_backend.api.schemas.lyrics import LyricsResponse
from lyricflow_backend.domain.lyrics import LyricsProviderPort
from lyricflow_backend.infrastructure.lyrics import (
    LyricsNotFoundError,
    LyricsProviderUnavailableError,
    get_lyrics_provider,
)

router = APIRouter(prefix="/lyrics", tags=["lyrics"])


@router.get("", response_model=LyricsResponse)
async def get_lyrics(
    title: Annotated[str, Query(min_length=1, max_length=200)],
    artist: Annotated[str, Query(min_length=1, max_length=200)],
    provider: Annotated[LyricsProviderPort, Depends(get_lyrics_provider)],
) -> LyricsResponse:
    try:
        result = await provider.get_lyrics(title=title, artist=artist)
    except LyricsNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from exc
    except LyricsProviderUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc

    song_id = f"{artist}_{title}".replace(" ", "_").lower()
    return LyricsResponse(
        song_id=song_id,
        title=result.title,
        artist=result.artist,
        language=result.language,
        source=result.source,
        attribution=result.attribution,
        lines=result.lines,
    )

