from typing import Annotated

from fastapi import APIRouter, Depends, Query

from lyricflow_backend.api.schemas.recognitions import (
    RecognitionCapabilitiesResponse,
    RecognitionHistoryResponse,
    RecognitionRequest,
    RecognitionResponse,
)
from lyricflow_backend.application.recognize_song import (
    RecognizeSong,
    get_recognize_song,
)
from lyricflow_backend.domain.recognition_repository import RecognitionRepository
from lyricflow_backend.infrastructure.recognition import (
    RecognitionConfigurationError,
)
from lyricflow_backend.infrastructure.recognition_repository import (
    get_recognition_repository,
)

router = APIRouter(prefix="/recognitions", tags=["recognitions"])


@router.get("/history", response_model=RecognitionHistoryResponse)
async def history(
    repository: Annotated[
        RecognitionRepository,
        Depends(get_recognition_repository),
    ],
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> RecognitionHistoryResponse:
    items, total = await repository.history(limit=limit, offset=offset)
    return RecognitionHistoryResponse(
        items=items,
        limit=limit,
        offset=offset,
        total=total,
    )


@router.get(
    "/capabilities",
    response_model=RecognitionCapabilitiesResponse,
)
def capabilities() -> RecognitionCapabilitiesResponse:
    from lyricflow_backend.infrastructure.settings import get_settings

    settings = get_settings()
    provider = (
        settings.recognition_provider
        if settings.recognition_provider and settings.audd_api_key
        else None
    )
    return RecognitionCapabilitiesResponse(
        available=provider is not None,
        provider=provider,
        reason=None if provider else "No recognition provider is configured yet.",
    )


@router.post(
    "",
    response_model=RecognitionResponse,
)
async def recognize(
    request: RecognitionRequest,
    use_case: Annotated[RecognizeSong, Depends(get_recognize_song)],
) -> RecognitionResponse:
    try:
        return await use_case.execute(request)
    except RecognitionConfigurationError as exc:
        return RecognitionResponse(status="not_configured", message=str(exc))
    except (ConnectionError, TimeoutError) as exc:
        return RecognitionResponse(status="failed", message=str(exc))
