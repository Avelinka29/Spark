from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://spark:spark@localhost:5432/spark"
    jwt_secret: str = "development-secret-change-before-deploy"
    access_token_minutes: int = 30
    google_web_client_id: str = ""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
