from pydantic import BaseModel, Field


class LyricsResponse(BaseModel):
    song_id: str
    title: str
    artist: str
    language: str
    source: str
    attribution: str
    lines: list[str] = Field(min_length=1)

