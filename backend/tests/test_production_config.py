import pytest

from app.config import Settings, validate_production_settings


def production_settings(**overrides: object) -> Settings:
    values: dict[str, object] = {
        "environment": "production",
        "database_url": "postgresql+psycopg://typetwo:strong-password@db:5432/typetwo",
        "postgres_password": "strong-postgres-password",
        "jwt_secret": "x" * 32,
        "admin_email": "admin@example.com",
        "admin_password": "strong-admin-password",
        "auto_create_tables": False,
        "public_base_url": "https://typetwo-glossary.example.test",
    }
    values.update(overrides)
    return Settings(**values)


def test_development_allows_default_values() -> None:
    validate_production_settings(Settings())


def test_production_rejects_unsafe_defaults() -> None:
    settings = production_settings(
        jwt_secret="change-this-secret-before-production",
        postgres_password="change-me",
        admin_password="admin",
        auto_create_tables=True,
        public_base_url="http://typetwo.example.test",
    )

    with pytest.raises(RuntimeError) as exc_info:
        validate_production_settings(settings)

    message = str(exc_info.value)
    assert "JWT_SECRET" in message
    assert "POSTGRES_PASSWORD" in message
    assert "ADMIN_PASSWORD" in message
    assert "AUTO_CREATE_TABLES=true" in message
    assert "PUBLIC_BASE_URL" in message


def test_production_accepts_hardened_settings() -> None:
    validate_production_settings(production_settings())


def test_cors_origins_are_parsed_from_comma_list() -> None:
    settings = Settings(
        cors_allowed_origins="https://app.example.test, https://admin.example.test"
    )

    assert settings.cors_origins == [
        "https://app.example.test",
        "https://admin.example.test",
    ]


def test_production_rejects_wildcard_cors_origin() -> None:
    settings = production_settings(cors_allowed_origins="*")

    with pytest.raises(RuntimeError) as exc_info:
        validate_production_settings(settings)

    assert "CORS_ALLOWED_ORIGINS=*" in str(exc_info.value)


def test_production_rejects_non_https_cors_origin() -> None:
    settings = production_settings(
        cors_allowed_origins="https://app.example.test,http://localhost:5173"
    )

    with pytest.raises(RuntimeError) as exc_info:
        validate_production_settings(settings)

    assert "CORS_ALLOWED_ORIGINS 只允許 https:// origin" in str(exc_info.value)
