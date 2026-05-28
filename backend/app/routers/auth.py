import time
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import current_user
from ..models import User
from ..models import utc_now
from ..schemas import ChangePasswordRequest, CurrentUserResponse, LoginRequest, TokenResponse
from ..security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])

LOGIN_FAILURE_LIMIT = 5
LOGIN_FAILURE_WINDOW_SECONDS = 60
_login_failures: dict[str, list[float]] = {}


def current_user_response(user: User) -> CurrentUserResponse:
    return CurrentUserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        isActive=user.is_active,
        mustChangePassword=user.must_change_password,
        createdAt=user.created_at,
        updatedAt=user.updated_at,
        lastLoginAt=user.last_login_at,
    )


@router.post("/login")
def login(
    payload: LoginRequest,
    request: Request,
    db: Annotated[Session, Depends(get_db)],
) -> TokenResponse:
    rate_limit_key = login_rate_limit_key(request, payload.email)
    guard_login_rate_limit(rate_limit_key)
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None or not user.is_active:
        record_login_failure(rate_limit_key)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "帳號或密碼錯誤")
    if not verify_password(payload.password, user.password_hash):
        record_login_failure(rate_limit_key)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "帳號或密碼錯誤")
    clear_login_failures(rate_limit_key)
    user.last_login_at = utc_now()
    db.commit()
    return TokenResponse(
        accessToken=create_access_token(user.id, user.role),
        role=user.role,
        mustChangePassword=user.must_change_password,
    )


def login_rate_limit_key(request: Request, email: str) -> str:
    forwarded_for = request.headers.get("X-Forwarded-For", "")
    client_host = forwarded_for.split(",", 1)[0].strip()
    if not client_host and request.client is not None:
        client_host = request.client.host
    return f"{client_host or 'unknown'}:{email.lower()}"


def guard_login_rate_limit(key: str) -> None:
    attempts = _recent_login_failures(key)
    if len(attempts) >= LOGIN_FAILURE_LIMIT:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            "登入失敗次數過多，請稍後再試",
        )


def record_login_failure(key: str) -> None:
    attempts = _recent_login_failures(key)
    attempts.append(time.monotonic())
    _login_failures[key] = attempts


def clear_login_failures(key: str) -> None:
    _login_failures.pop(key, None)


def _recent_login_failures(key: str) -> list[float]:
    threshold = time.monotonic() - LOGIN_FAILURE_WINDOW_SECONDS
    attempts = [item for item in _login_failures.get(key, []) if item >= threshold]
    _login_failures[key] = attempts
    return attempts


@router.get("/me")
def me(user: Annotated[User, Depends(current_user)]) -> CurrentUserResponse:
    return current_user_response(user)


@router.post("/change-password")
def change_password(
    payload: ChangePasswordRequest,
    user: Annotated[User, Depends(current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> CurrentUserResponse:
    if not verify_password(payload.currentPassword, user.password_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "目前密碼錯誤")
    user.password_hash = hash_password(payload.newPassword)
    user.must_change_password = False
    db.commit()
    db.refresh(user)
    return current_user_response(user)
