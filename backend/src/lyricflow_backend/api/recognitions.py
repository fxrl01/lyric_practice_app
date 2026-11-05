from typing import Annotated

from fastapi import APIRouter, Depends

from lyricflow_backend.api.schemas.recognitions import (
    RecognitionCapabilitiesResponse,
    RecognitionRequest,
    RecognitionResponse,
)
from lyricflow_backend.application.recognize_song import (
    RecognizeSong,
    get_recognize_song,
)
from lyricflow_backend.infrastructure.recognition import (
    RecognitionConfigurationError,
)

router = APIRouter(prefix="/recognitions", tags=["recognitions"])


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
