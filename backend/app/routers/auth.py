from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import current_user
from ..models import User
from ..models import utc_now
from ..schemas import ChangePasswordRequest, CurrentUserResponse, LoginRequest, TokenResponse
from ..security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


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
    db: Annotated[Session, Depends(get_db)],
) -> TokenResponse:
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "帳號或密碼錯誤")
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "帳號或密碼錯誤")
    user.last_login_at = utc_now()
    db.commit()
    return TokenResponse(
        accessToken=create_access_token(user.id, user.role),
        role=user.role,
        mustChangePassword=user.must_change_password,
    )


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
