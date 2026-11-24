import pytest
from pydantic import ValidationError

from app.config import Settings


def test_production_rejects_development_configuration() -> None:
    with pytest.raises(ValidationError):
        Settings(app_environment="production")


def test_production_accepts_complete_secure_configuration() -> None:
    settings = Settings(
        app_environment="production",
        database_url="postgresql+asyncpg://spark:secret@postgres:5432/spark",
        jwt_secret="a-secure-production-secret-with-32-characters",
        google_web_client_id="client.apps.googleusercontent.com",
        smtp_host="smtp.example.com",
        smtp_username="spark",
        smtp_password="secret",
        smtp_sender="support@example.com",
        allow_development_codes=False,
    )

    assert settings.app_environment == "production"


def test_ai_configuration_must_be_complete() -> None:
    with pytest.raises(ValidationError):
        Settings(ai_ollama_url="http://localhost:11434", ai_ollama_model="")


def test_ai_url_rejects_embedded_credentials() -> None:
    with pytest.raises(ValidationError):
        Settings(ai_ollama_url="https://user:secret@example.com", ai_ollama_model="model")
