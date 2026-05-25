from datetime import datetime
from pydantic import BaseModel, Field, field_validator


class ApiModel(BaseModel):
    pass


ALLOWED_ROLES = {"admin", "editor", "user"}
ALLOWED_TERM_STATUSES = {"approved", "pending", "rejected"}


def _trimmed(value: str) -> str:
    return value.strip()


def _non_empty(value: str, field_name: str) -> str:
    trimmed = value.strip()
    if not trimmed:
        raise ValueError(f"{field_name}不可為空")
    return trimmed


class LoginRequest(ApiModel):
    email: str
    password: str

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return _non_empty(value, "Email").lower()


class TokenResponse(ApiModel):
    accessToken: str
    tokenType: str = "bearer"
    role: str


class UserCreate(ApiModel):
    email: str
    password: str
    role: str = "user"

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return _non_empty(value, "Email").lower()

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        if len(value) < 6:
            raise ValueError("密碼至少需要 6 個字元")
        return value

    @field_validator("role")
    @classmethod
    def validate_role(cls, value: str) -> str:
        role = value.strip().lower()
        if role not in ALLOWED_ROLES:
            raise ValueError("角色不合法")
        return role


class UserUpdate(ApiModel):
    role: str | None = None
    isActive: bool | None = None
    password: str | None = None

    @field_validator("role")
    @classmethod
    def validate_role(cls, value: str | None) -> str | None:
        if value is None:
            return None
        role = value.strip().lower()
        if role not in ALLOWED_ROLES:
            raise ValueError("角色不合法")
        return role

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str | None) -> str | None:
        if value is None:
            return None
        if len(value) < 6:
            raise ValueError("密碼至少需要 6 個字元")
        return value


class UserOut(ApiModel):
    id: str
    email: str
    role: str
    isActive: bool
    createdAt: datetime


class GlossaryTermCreate(ApiModel):
    sourceText: str
    targetText: str = ""
    sourceLang: str | None = None
    targetLang: str | None = None
    contextKey: str = "global"
    status: str = "approved"

    @field_validator("sourceText")
    @classmethod
    def validate_source_text(cls, value: str) -> str:
        return _non_empty(value, "原文")

    @field_validator("targetText", "sourceLang", "targetLang")
    @classmethod
    def trim_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return _trimmed(value)

    @field_validator("contextKey")
    @classmethod
    def normalize_context_key(cls, value: str) -> str:
        return value.strip() or "global"

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        status = value.strip().lower()
        if status not in ALLOWED_TERM_STATUSES:
            raise ValueError("詞彙狀態不合法")
        return status


class GlossaryTermUpdate(ApiModel):
    sourceText: str | None = None
    targetText: str | None = None
    sourceLang: str | None = None
    targetLang: str | None = None
    contextKey: str | None = None
    status: str | None = None

    @field_validator("sourceText")
    @classmethod
    def validate_source_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return _non_empty(value, "原文")

    @field_validator("targetText", "sourceLang", "targetLang")
    @classmethod
    def trim_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return _trimmed(value)

    @field_validator("contextKey")
    @classmethod
    def normalize_context_key(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return value.strip() or "global"

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str | None) -> str | None:
        if value is None:
            return None
        status = value.strip().lower()
        if status not in ALLOWED_TERM_STATUSES:
            raise ValueError("詞彙狀態不合法")
        return status


class GlossaryTermOut(ApiModel):
    id: str
    sourceText: str
    targetText: str
    sourceLang: str | None
    targetLang: str | None
    contextKey: str
    status: str
    version: int
    updatedAt: datetime
    deletedAt: datetime | None = None


class GlossaryTermHistoryOut(ApiModel):
    id: str
    termId: str
    sourceText: str
    targetText: str
    sourceLang: str | None
    targetLang: str | None
    contextKey: str
    status: str
    version: int
    operation: str
    changedAt: datetime


class GlossaryBundle(ApiModel):
    glossary: dict[str, str]
    langGlossary: dict[str, dict[str, str]]
    syncedAt: datetime


class GlossaryImportRequest(ApiModel):
    glossary: dict[str, str] = Field(default_factory=dict)
    langGlossary: dict[str, dict[str, str]] = Field(default_factory=dict)
    status: str = "approved"

    @field_validator("status")
    @classmethod
    def validate_status(cls, value: str) -> str:
        status = value.strip().lower()
        if status not in ALLOWED_TERM_STATUSES:
            raise ValueError("詞彙狀態不合法")
        return status


class GlossaryImportResponse(ApiModel):
    imported: int
    updated: int
