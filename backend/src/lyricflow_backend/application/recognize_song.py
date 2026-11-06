from typing import Annotated

from fastapi import Depends

from lyricflow_backend.api.schemas.recognitions import (
    RecognitionRequest,
    RecognitionResponse,
)
from lyricflow_backend.domain.ports import SongRecognitionPort
from lyricflow_backend.domain.recognition_repository import RecognitionRepository
from lyricflow_backend.infrastructure.recognition import (
    get_song_recognition_port,
)
from lyricflow_backend.infrastructure.recognition_repository import (
    get_recognition_repository,
)


class RecognizeSong:
    def __init__(
        self,
        port: SongRecognitionPort,
        repository: RecognitionRepository,
    ) -> None:
        self._port = port
        self._repository = repository

    async def execute(self, request: RecognitionRequest) -> RecognitionResponse:
        result = await self._port.recognize(
            audio_base64=request.audio_base64,
            duration_ms=request.duration_ms,
            is_humming=request.is_humming,
        )
        await self._repository.save(
            result=result,
            duration_ms=request.duration_ms,
        )
        return RecognitionResponse(
            status=result.status,
            message=result.message,
            song=result.song,
        )


def get_recognize_song(
    port: Annotated[SongRecognitionPort, Depends(get_song_recognition_port)],
    repository: Annotated[
        RecognitionRepository,
        Depends(get_recognition_repository),
    ],
) -> RecognizeSong:
    return RecognizeSong(port, repository)
