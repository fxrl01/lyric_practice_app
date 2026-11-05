from fastapi import FastAPI

from lyricflow_backend.api.health import router as health_router
from lyricflow_backend.api.recognitions import router as recognitions_router
from lyricflow_backend.infrastructure.settings import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title=settings.app_name, version="0.1.0")
    app.include_router(health_router)
    app.include_router(
        recognitions_router,
        prefix=settings.app_api_prefix,
    )
    return app


app = create_app()

