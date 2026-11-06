from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "LyricFlow API"
    app_env: str = "development"
    app_debug: bool = False
    app_api_prefix: str = "/api/v1"
    app_allowed_origins: str = ""
    database_url: str = "sqlite+aiosqlite:///./lyricflow.db"
    recognition_provider: str = ""
    recognition_timeout_seconds: float = 20.0
    audd_api_key: str = ""
    audd_base_url: str = "https://api.audd.io"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
