from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from db import get_db
from deps import get_current_user
from schemas import AuthResponse, LoginRequest, RegisterRequest, UserResponse
from security import create_access_token, get_password_hash, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


def _upsert_profile_for_user(db: Session, user_id: int, role: str, name: str) -> None:
    if role == "PATIENT":
        patient_code = f"PT-{2000 + user_id}"
        db.execute(
            text(
                """
                INSERT INTO patients (user_id, patient_code, name)
                VALUES (:user_id, :patient_code, :name)
                ON CONFLICT (user_id) DO NOTHING
                """
            ),
            {"user_id": user_id, "patient_code": patient_code, "name": name},
        )
    elif role == "DOCTOR":
        doctor_code = f"DOC-{1000 + user_id}"
        db.execute(
            text(
                """
                INSERT INTO doctors (user_id, doctor_code, name)
                VALUES (:user_id, :doctor_code, :name)
                ON CONFLICT (user_id) DO NOTHING
                """
            ),
            {"user_id": user_id, "doctor_code": doctor_code, "name": name},
        )


def _get_display_name(db: Session, user_id: int, role: str) -> str:
    if role == "PATIENT":
        row = db.execute(text("SELECT name FROM patients WHERE user_id = :id"), {"id": user_id}).first()
    else:
        row = db.execute(text("SELECT name FROM doctors WHERE user_id = :id"), {"id": user_id}).first()
    if row and row[0]:
        return str(row[0])
    return "User"


@router.post("/register", response_model=AuthResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> AuthResponse:
    normalized_email = payload.email.lower().strip()
    password_hash = get_password_hash(payload.password)

    try:
        user_row = db.execute(
            text(
                """
                INSERT INTO users (email, password_hash, role)
                VALUES (:email, :password_hash, :role)
                RETURNING id, email, role
                """
            ),
            {
                "email": normalized_email,
                "password_hash": password_hash,
                "role": payload.role,
            },
        ).mappings().first()
        if not user_row:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not create user.")

        _upsert_profile_for_user(db, int(user_row["id"]), str(user_row["role"]), payload.name)
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists.") from exc

    token = create_access_token(subject=str(user_row["id"]), role=str(user_row["role"]))
    return AuthResponse(
        user=UserResponse(
            id=int(user_row["id"]),
            email=str(user_row["email"]),
            role=str(user_row["role"]),
            name=payload.name,
        ),
        token=token,
    )


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    normalized_email = payload.email.lower().strip()

    user_row = db.execute(
        text("SELECT id, email, role, password_hash FROM users WHERE email = :email"),
        {"email": normalized_email},
    ).mappings().first()

    if not user_row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    stored_hash = str(user_row["password_hash"])
    if not verify_password(payload.password, stored_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials.")

    if stored_hash.startswith("mock_hash_"):
        db.execute(
            text("UPDATE users SET password_hash = :password_hash WHERE id = :id"),
            {"password_hash": get_password_hash(payload.password), "id": int(user_row["id"])},
        )
        db.commit()

    name = _get_display_name(db, int(user_row["id"]), str(user_row["role"]))
    token = create_access_token(subject=str(user_row["id"]), role=str(user_row["role"]))

    return AuthResponse(
        user=UserResponse(
            id=int(user_row["id"]),
            email=str(user_row["email"]),
            role=str(user_row["role"]),
            name=name,
        ),
        token=token,
    )


@router.get("/me", response_model=UserResponse)
def auth_me(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)) -> UserResponse:
    user_id = int(current_user["id"])
    role = str(current_user["role"])
    name = _get_display_name(db, user_id, role)

    return UserResponse(
        id=user_id,
        email=str(current_user["email"]),
        role=role,
        name=name,
    )
