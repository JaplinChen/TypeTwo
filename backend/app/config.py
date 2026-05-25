from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str = "sqlite:///./typetwo_glossary.db"
    jwt_secret: str = "dev-only-secret"
    access_token_expire_minutes: int = 60 * 24 * 7
    admin_email: str | None = None
    admin_password: str | None = None
    auto_create_tables: bool = True

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
