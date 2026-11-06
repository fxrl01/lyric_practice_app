from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from lyricflow_backend.infrastructure.settings import get_settings


class Base(DeclarativeBase):
    pass


def create_database_engine() -> AsyncEngine:
    return create_async_engine(get_settings().database_url, echo=False)


engine = create_database_engine()
session_factory = async_sessionmaker(engine, expire_on_commit=False)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with session_factory() as session:
        yield session

