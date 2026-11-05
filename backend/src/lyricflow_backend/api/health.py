from fastapi import APIRouter

from lyricflow_backend.infrastructure.settings import get_settings

router = APIRouter(tags=["health"])


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "lyricflow-api"}


@router.get("/ready")
def readiness() -> dict[str, str]:
    settings = get_settings()
    return {
        "status": "ready",
        "environment": settings.app_env,
        "recognition_provider": "not_configured",
    }

