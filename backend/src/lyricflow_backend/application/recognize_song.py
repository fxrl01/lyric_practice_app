from typing import Annotated

from fastapi import Depends

from lyricflow_backend.api.schemas.recognitions import (
    RecognitionRequest,
    RecognitionResponse,
)
from lyricflow_backend.domain.ports import SongRecognitionPort
from lyricflow_backend.infrastructure.recognition import (
    get_song_recognition_port,
)


class RecognizeSong:
    def __init__(self, port: SongRecognitionPort) -> None:
        self._port = port

    async def execute(self, request: RecognitionRequest) -> RecognitionResponse:
        result = await self._port.recognize(
            audio_base64=request.audio_base64,
            duration_ms=request.duration_ms,
            is_humming=request.is_humming,
        )
        return RecognitionResponse(
            status=result.status,
            message=result.message,
            song=result.song,
        )


def get_recognize_song(
    port: Annotated[SongRecognitionPort, Depends(get_song_recognition_port)],
) -> RecognizeSong:
    return RecognizeSong(port)
