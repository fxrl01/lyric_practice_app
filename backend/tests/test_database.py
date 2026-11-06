import pytest
from sqlalchemy import inspect, select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from lyricflow_backend.domain.ports import RecognitionResult
from lyricflow_backend.infrastructure import models
from lyricflow_backend.infrastructure.database import Base
from lyricflow_backend.infrastructure.recognition_repository import (
    SqlAlchemyRecognitionRepository,
)


@pytest.mark.asyncio
async def test_database_schema_contains_song_and_recognition_tables() -> None:
    assert models.SongModel.__tablename__ == "songs"
    assert models.RecognitionModel.__tablename__ == "recognitions"
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    async with engine.connect() as connection:
        table_names = await connection.run_sync(
            lambda sync_connection: inspect(sync_connection).get_table_names()
        )
        assert {"songs", "recognitions"} <= set(table_names)
        await connection.execute(text("SELECT 1"))

    await engine.dispose()


@pytest.mark.asyncio
async def test_repository_persists_song_and_recognition() -> None:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    async with session_factory() as session:
        repository = SqlAlchemyRecognitionRepository(session)
        await repository.save(
            result=RecognitionResult(
                status="recognized",
                message="ok",
                song={
                    "id": "song-1",
                    "title": "Test song",
                    "artist": "Test artist",
                    "source": "test",
                },
            ),
            duration_ms=3_000,
        )
        songs = (await session.scalars(select(models.SongModel))).all()
        recognitions = (
            await session.scalars(select(models.RecognitionModel))
        ).all()

    assert len(songs) == 1
    assert songs[0].title == "Test song"
    assert len(recognitions) == 1
    assert recognitions[0].status == "recognized"
    await engine.dispose()


@pytest.mark.asyncio
async def test_repository_history_orders_and_paginates_records() -> None:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    async with session_factory() as session:
        repository = SqlAlchemyRecognitionRepository(session)
        for index in range(3):
            await repository.save(
                result=RecognitionResult(
                    status="recognized",
                    message="ok",
                    song={
                        "id": f"song-{index}",
                        "title": f"Song {index}",
                        "artist": "Test artist",
                        "source": "test",
                    },
                ),
                duration_ms=3_000 + index,
            )

        page, total = await repository.history(limit=2, offset=1)

    assert total == 3
    assert [item["song"]["id"] for item in page] == ["song-1", "song-0"]
    assert [item["duration_ms"] for item in page] == [3_001, 3_000]
    await engine.dispose()
