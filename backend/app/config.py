from functools import lru_cache
from urllib.parse import urlparse

from pydantic_settings import BaseSettings, SettingsConfigDict


WEAK_JWT_SECRETS = {
    "change-this-secret",
    "change-this-secret-before-production",
    "dev-only-secret",
}
WEAK_POSTGRES_PASSWORDS = {
    "change-me",
}
WEAK_ADMIN_PASSWORDS = {
    "change-me-now",
    "password",
    "admin",
    "secret",
}


class Settings(BaseSettings):
    environment: str = "development"
    database_url: str = "sqlite:///./typetwo_glossary.db"
    jwt_secret: str = "dev-only-secret"
    access_token_expire_minutes: int = 60 * 24 * 7
    admin_email: str | None = None
    admin_password: str | None = None
    postgres_password: str | None = None
    auto_create_tables: bool = True
    public_base_url: str | None = None
    cors_allowed_origins: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"

    @property
    def cors_origins(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.cors_allowed_origins.split(",")
            if origin.strip()
        ]


def validate_production_settings(settings: Settings) -> None:
    if not settings.is_production:
        return

    errors: list[str] = []

    if settings.jwt_secret in WEAK_JWT_SECRETS or len(settings.jwt_secret) < 32:
        errors.append("JWT_SECRET 不可使用預設值，且長度至少需要 32 個字元")

    if settings.postgres_password in WEAK_POSTGRES_PASSWORDS:
        errors.append("POSTGRES_PASSWORD 不可使用開發預設值")

    if not settings.admin_password:
        errors.append("ADMIN_PASSWORD 必須設定")
    elif (
        settings.admin_password in WEAK_ADMIN_PASSWORDS
        or len(settings.admin_password) < 12
    ):
        errors.append("ADMIN_PASSWORD 不可使用弱密碼，且長度至少需要 12 個字元")

    if settings.auto_create_tables:
        errors.append("production 禁止 AUTO_CREATE_TABLES=true，請先執行 Alembic migration")

    if not settings.public_base_url:
        errors.append("PUBLIC_BASE_URL 必須設定")
    else:
        parsed = urlparse(settings.public_base_url)
        if parsed.scheme != "https" or not parsed.netloc:
            errors.append("PUBLIC_BASE_URL 必須是 https:// 開頭的完整網址")

    if errors:
        raise RuntimeError("正式環境設定不安全：" + "；".join(errors))


@lru_cache
def get_settings() -> Settings:
    return Settings()
