from fastapi.testclient import TestClient

from lyricflow_backend.api import recognitions
from lyricflow_backend.main import app

client = TestClient(app)


def test_root() -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_health() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "lyricflow-api"}


def test_readiness_is_explicit_about_missing_provider() -> None:
    response = client.get("/ready")

    assert response.status_code == 200
    assert response.json()["recognition_provider"] == "not_configured"


def test_recognition_does_not_return_fake_song() -> None:
    with TestClient(app) as test_client:
        response = test_client.post(
            "/api/v1/recognitions",
            json={
                "audio_base64": "dGVzdA==",
                "duration_ms": 3_000,
                "is_humming": False,
            },
        )

    assert response.status_code == 200
    assert response.json()["status"] == "not_configured"
    assert response.json()["song"] is None


def test_recognition_rejects_audio_shorter_than_two_seconds() -> None:
    response = client.post(
        "/api/v1/recognitions",
        json={"audio_base64": "dGVzdA==", "duration_ms": 1_999},
    )

    assert response.status_code == 422


def test_recognition_rejects_invalid_base64() -> None:
    response = client.post(
        "/api/v1/recognitions",
        json={"audio_base64": "not-base64", "duration_ms": 3_000},
    )

    assert response.status_code == 422


def test_recognition_history_returns_empty_page() -> None:
    class EmptyRepository:
        async def history(
            self, *, limit: int, offset: int
        ) -> tuple[list[dict[str, object]], int]:
            return [], 0

    app.dependency_overrides[recognitions.get_recognition_repository] = (
        lambda: EmptyRepository()
    )
    try:
        response = client.get("/api/v1/recognitions/history")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json() == {
        "items": [],
        "limit": 20,
        "offset": 0,
        "total": 0,
    }


def test_recognition_history_rejects_invalid_pagination() -> None:
    assert client.get(
        "/api/v1/recognitions/history", params={"limit": 0}
    ).status_code == 422
    assert client.get(
        "/api/v1/recognitions/history", params={"limit": 101}
    ).status_code == 422
    assert client.get(
        "/api/v1/recognitions/history", params={"offset": -1}
    ).status_code == 422


def test_lyrics_endpoint_returns_not_found_without_calling_real_provider() -> None:
    from lyricflow_backend.api import lyrics

    class NotFoundProvider:
        async def get_lyrics(self, *, title: str, artist: str):
            from lyricflow_backend.infrastructure.lyrics import LyricsNotFoundError

            raise LyricsNotFoundError("No lyrics")

    app.dependency_overrides[lyrics.get_lyrics_provider] = lambda: NotFoundProvider()
    try:
        response = client.get(
            "/api/v1/lyrics",
            params={"title": "Unknown", "artist": "Unknown"},
        )
        assert response.status_code == 404
    finally:
        app.dependency_overrides.clear()
