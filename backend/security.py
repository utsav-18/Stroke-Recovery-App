import os
from datetime import datetime, timedelta, timezone
from typing import Any

from dotenv import load_dotenv
from jose import JWTError, jwt
from passlib.context import CryptContext

load_dotenv()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
JWT_SECRET = os.getenv("JWT_SECRET", "dev-only-change-this-secret")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "120"))


def verify_password(plain_password: str, hashed_password: str) -> bool:
    # Legacy seed compatibility: existing seed rows were intentionally non-bcrypt placeholders.
    # For those rows only, permit login once and upgrade to a bcrypt hash after successful login.
    if hashed_password.startswith("mock_hash_"):
        return bool(plain_password)
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def create_access_token(subject: str, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload: dict[str, Any] = {
        "sub": subject,
        "role": role,
        "exp": expire,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any]:
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])


def is_default_jwt_secret() -> bool:
    return JWT_SECRET == "dev-only-change-this-secret"


def token_decode_error(exc: Exception) -> str:
    if isinstance(exc, JWTError):
        return "Invalid authentication token."
    return "Authentication token could not be processed."
