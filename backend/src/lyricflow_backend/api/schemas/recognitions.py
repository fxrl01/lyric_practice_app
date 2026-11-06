from base64 import b64decode, binascii
from typing import Literal

from pydantic import BaseModel, Field, field_validator


class RecognitionRequest(BaseModel):
    audio_base64: str = Field(
        min_length=1,
        description="Audio sample encoded as base64.",
    )
    duration_ms: int = Field(ge=2_000, le=30_000)
    is_humming: bool = False

    @field_validator("audio_base64")
    @classmethod
    def validate_audio_base64(cls, value: str) -> str:
        try:
            b64decode(value, validate=True)
        except (binascii.Error, ValueError) as exc:
            raise ValueError("audio_base64 must contain valid base64.") from exc
        return value


class RecognitionCapabilitiesResponse(BaseModel):
    available: bool
    provider: str | None
    reason: str | None


class RecognitionResponse(BaseModel):
    status: Literal["not_configured", "recognized", "not_found", "failed"]
    message: str
    song: dict[str, object] | None = None


class RecognitionHistoryResponse(BaseModel):
    items: list[dict[str, object]]
    limit: int
    offset: int
    total: int
