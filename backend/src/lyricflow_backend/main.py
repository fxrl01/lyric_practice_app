from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from lyricflow_backend.api.health import router as health_router
from lyricflow_backend.api.lyrics import router as lyrics_router
from lyricflow_backend.api.recognitions import router as recognitions_router
from lyricflow_backend.infrastructure.settings import get_settings


def create_app() -> FastAPI:
    settings = get_settings()

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        yield

    app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)
    origins = [
        origin.strip()
        for origin in settings.app_allowed_origins.split(",")
        if origin.strip()
    ]
    if origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=origins,
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
    app.include_router(health_router)
    app.include_router(
        recognitions_router,
        prefix=settings.app_api_prefix,
    )
    app.include_router(lyrics_router, prefix=settings.app_api_prefix)

    @app.get("/", tags=["health"])
    def root() -> dict[str, str]:
        return {
            "service": settings.app_name,
            "status": "ok",
            "docs": "/docs",
        }

    return app


app = create_app()
