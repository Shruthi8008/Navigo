from __future__ import annotations

from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import Settings

password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
_BCRYPT_MAX_PASSWORD_BYTES = 72


def hash_password(password: str) -> str:
    _ensure_bcrypt_password_length(password)
    return password_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    try:
        _ensure_bcrypt_password_length(password)
        return password_context.verify(password, password_hash)
    except ValueError:
        return False


def ensure_password_length_for_bcrypt(password: str) -> None:
    _ensure_bcrypt_password_length(password)


def _ensure_bcrypt_password_length(value: str) -> None:
    if len(value.encode("utf-8")) > _BCRYPT_MAX_PASSWORD_BYTES:
        raise ValueError(
            "Password must be 72 bytes or fewer when UTF-8 encoded."
        )


def create_access_token(
    *,
    subject: str,
    settings: Settings,
    expires_delta: timedelta | None = None,
) -> str:
    expire_at = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.jwt_access_token_expire_minutes)
    )
    payload = {
        "sub": subject,
        "exp": expire_at,
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str, settings: Settings) -> dict:
    try:
        return jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError as error:
        raise ValueError("Invalid or expired access token.") from error
