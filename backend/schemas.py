from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    role: Literal["PATIENT", "DOCTOR"]
    name: str = Field(min_length=1, max_length=255)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserResponse(BaseModel):
    id: int
    email: str
    role: str
    name: str


class AuthResponse(BaseModel):
    user: UserResponse
    token: str


class PatientUpdateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    date_of_birth: str | None = None
    gender: str | None = None
    phone: str | None = None


class DoctorUpdateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    specialization: str | None = None
    phone: str | None = None


class SessionCreateRequest(BaseModel):
    exercise_type: str = Field(min_length=1, max_length=120)
    started_at: datetime
    completed_at: datetime | None = None


class SessionResponse(BaseModel):
    id: int
    patient_id: int
    exercise_type: str
    started_at: datetime
    completed_at: datetime | None


class AnalyzeResponse(BaseModel):
    movement_status: str
    confidence_score: float
    emotion: str
