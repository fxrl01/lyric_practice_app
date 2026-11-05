from fastapi.testclient import TestClient

from lyricflow_backend.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "lyricflow-api"}


def test_readiness_is_explicit_about_missing_provider() -> None:
    response = client.get("/ready")

    assert response.status_code == 200
    assert response.json()["recognition_provider"] == "not_configured"


def test_recognition_does_not_return_fake_song() -> None:
    response = client.post(
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
