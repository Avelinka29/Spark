from functools import lru_cache
from typing import Literal
from urllib.parse import urlsplit

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_environment: Literal["development", "test", "production"] = "development"
    database_url: str = "postgresql+asyncpg://spark:spark@localhost:5432/spark"
    jwt_secret: str = "development-secret-change-before-deploy"
    access_token_minutes: int = 30
    google_web_client_id: str = ""
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_sender: str = ""
    allow_development_codes: bool = False
    admin_emails: str = ""
    ai_ollama_url: str = ""
    ai_ollama_model: str = ""

    def is_admin_email(self, email: str) -> bool:
        allowed = {item.strip().lower() for item in self.admin_emails.split(",") if item.strip()}
        return email.strip().lower() in allowed

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @model_validator(mode="after")
    def validate_production_settings(self) -> "Settings":
        if bool(self.ai_ollama_url) != bool(self.ai_ollama_model):
            raise ValueError("Set both AI_OLLAMA_URL and AI_OLLAMA_MODEL, or leave both empty")
        if self.ai_ollama_url:
            parsed = urlsplit(self.ai_ollama_url)
            if parsed.scheme not in {"http", "https"} or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
                raise ValueError("AI_OLLAMA_URL must be an HTTP(S) URL without credentials or query parameters")
            if self.app_environment == "production" and parsed.scheme != "https":
                raise ValueError("AI_OLLAMA_URL must use HTTPS in production")
        if self.app_environment != "production":
            return self

        if len(self.jwt_secret) < 32 or "development" in self.jwt_secret:
            raise ValueError("JWT_SECRET must contain at least 32 non-development characters")
        if self.allow_development_codes:
            raise ValueError("ALLOW_DEVELOPMENT_CODES must be false in production")
        if not self.google_web_client_id:
            raise ValueError("GOOGLE_WEB_CLIENT_ID is required in production")

        smtp_values = (
            self.smtp_host,
            self.smtp_username,
            self.smtp_password,
            self.smtp_sender,
        )
        if not all(smtp_values):
            raise ValueError("SMTP configuration is required in production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
