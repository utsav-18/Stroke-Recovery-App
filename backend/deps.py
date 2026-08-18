from collections.abc import Callable

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import text
from sqlalchemy.orm import Session

from db import get_db
from security import decode_access_token, token_decode_error

bearer_scheme = HTTPBearer(auto_error=True)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> dict:
    token = credentials.credentials

    try:
        payload = decode_access_token(token)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=token_decode_error(exc)) from exc

    sub = payload.get("sub")
    role = payload.get("role")
    if not sub or not role:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload.")

    row = db.execute(
        text("SELECT id, email, role FROM users WHERE id = :id"),
        {"id": int(sub)},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authenticated user not found.")

    return dict(row)


def require_role(expected_role: str) -> Callable:
    def _guard(current_user: dict = Depends(get_current_user)) -> dict:
        if current_user["role"] != expected_role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden for this role.")
        return current_user

    return _guard
