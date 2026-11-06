from datetime import datetime

from sqlalchemy import DateTime, Float, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from lyricflow_backend.infrastructure.database import Base


class SongModel(Base):
    __tablename__ = "songs"

    id: Mapped[str] = mapped_column(String(512), primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    artist: Mapped[str] = mapped_column(String(200))
    album: Mapped[str | None] = mapped_column(String(200))
    source: Mapped[str] = mapped_column(String(50))
    external_links_json: Mapped[str] = mapped_column(Text, default="{}")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )


class RecognitionModel(Base):
    __tablename__ = "recognitions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    song_id: Mapped[str | None] = mapped_column(String(512))
    status: Mapped[str] = mapped_column(String(30))
    provider: Mapped[str | None] = mapped_column(String(50))
    duration_ms: Mapped[int] = mapped_column(Integer)
    confidence: Mapped[float | None] = mapped_column(Float)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
