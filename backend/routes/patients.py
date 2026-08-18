from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from db import get_db
from deps import require_role
from schemas import PatientUpdateRequest, SessionCreateRequest

router = APIRouter(prefix="/patients", tags=["patients"])


def _patient_row_for_user(db: Session, user_id: int) -> dict:
    row = db.execute(
        text(
            """
            SELECT id, user_id, patient_code, name, date_of_birth, gender, phone, created_at, updated_at
            FROM patients
            WHERE user_id = :user_id
            """
        ),
        {"user_id": user_id},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient profile not found.")

    return dict(row)


def _session_query_rows(db: Session, patient_id: int) -> list[dict]:
    rows = db.execute(
        text(
            """
            SELECT
                s.id,
                s.patient_id,
                s.exercise_type,
                s.started_at,
                s.completed_at,
                a.movement_status,
                a.confidence_score,
                a.emotion
            FROM exercise_sessions s
            LEFT JOIN analysis_results a ON a.session_id = s.id
            WHERE s.patient_id = :patient_id
            ORDER BY s.started_at DESC
            """
        ),
        {"patient_id": patient_id},
    ).mappings().all()
    return [dict(row) for row in rows]


@router.get("/me")
def get_patient_me(current_user: dict = Depends(require_role("PATIENT")), db: Session = Depends(get_db)) -> dict:
    return _patient_row_for_user(db, int(current_user["id"]))


@router.put("/me")
def update_patient_me(
    payload: PatientUpdateRequest,
    current_user: dict = Depends(require_role("PATIENT")),
    db: Session = Depends(get_db),
) -> dict:
    patient = _patient_row_for_user(db, int(current_user["id"]))

    updated = db.execute(
        text(
            """
            UPDATE patients
            SET name = :name,
                date_of_birth = :date_of_birth,
                gender = :gender,
                phone = :phone
            WHERE id = :id
            RETURNING id, user_id, patient_code, name, date_of_birth, gender, phone, created_at, updated_at
            """
        ),
        {
            "id": patient["id"],
            "name": payload.name,
            "date_of_birth": payload.date_of_birth,
            "gender": payload.gender,
            "phone": payload.phone,
        },
    ).mappings().first()
    db.commit()

    if not updated:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Update failed.")

    return dict(updated)


@router.post("/me/sessions")
def create_patient_session(
    payload: SessionCreateRequest,
    current_user: dict = Depends(require_role("PATIENT")),
    db: Session = Depends(get_db),
) -> dict:
    patient = _patient_row_for_user(db, int(current_user["id"]))

    row = db.execute(
        text(
            """
            INSERT INTO exercise_sessions (patient_id, exercise_type, started_at, completed_at)
            VALUES (:patient_id, :exercise_type, :started_at, :completed_at)
            RETURNING id, patient_id, exercise_type, started_at, completed_at
            """
        ),
        {
            "patient_id": patient["id"],
            "exercise_type": payload.exercise_type,
            "started_at": payload.started_at,
            "completed_at": payload.completed_at,
        },
    ).mappings().first()

    db.commit()
    if not row:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Session creation failed.")

    return dict(row)


@router.get("/me/sessions")
def get_patient_sessions(current_user: dict = Depends(require_role("PATIENT")), db: Session = Depends(get_db)) -> list[dict]:
    patient = _patient_row_for_user(db, int(current_user["id"]))
    rows = _session_query_rows(db, int(patient["id"]))

    if not rows:
        return []

    return [
        {
            "id": row["id"],
            "patient_id": row["patient_id"],
            "exercise_type": row["exercise_type"],
            "started_at": row["started_at"],
            "completed_at": row["completed_at"],
            "analysis": {
                "movement_status": row["movement_status"],
                "confidence_score": float(row["confidence_score"]) if row["confidence_score"] is not None else None,
                "emotion": row["emotion"],
            }
            if row["movement_status"] is not None
            else None,
        }
        for row in rows
    ]


@router.get("/me/progress")
def get_patient_progress(current_user: dict = Depends(require_role("PATIENT")), db: Session = Depends(get_db)) -> dict:
    patient = _patient_row_for_user(db, int(current_user["id"]))
    patient_id = int(patient["id"])

    rows = _session_query_rows(db, patient_id)
    if not rows:
        return {
            "patient_id": patient_id,
            "total_sessions": 0,
            "average_confidence": 0.0,
            "latest_movement_status": "Not Improved",
            "confidence_trend": [],
            "movement_history": [],
            "emotion_history": [],
        }

    confidence_scores = [float(row["confidence_score"]) for row in rows if row["confidence_score"] is not None]
    latest_with_analysis = next((row for row in rows if row["movement_status"] is not None), rows[0])

    movement_history = [
        {
            "date": row["started_at"].date().isoformat() if row["started_at"] else None,
            "status": row["movement_status"] or "Not Improved",
        }
        for row in rows
        if row["started_at"] is not None
    ]

    emotion_history = [
        {
            "date": row["started_at"].date().isoformat() if row["started_at"] else None,
            "emotion": row["emotion"] or "No Face Detected",
        }
        for row in rows
        if row["started_at"] is not None
    ]

    return {
        "patient_id": patient_id,
        "total_sessions": len(rows),
        "average_confidence": round(sum(confidence_scores) / len(confidence_scores), 4) if confidence_scores else 0.0,
        "latest_movement_status": latest_with_analysis["movement_status"] or "Not Improved",
        "confidence_trend": [round(score, 4) for score in reversed(confidence_scores)],
        "movement_history": list(reversed(movement_history)),
        "emotion_history": list(reversed(emotion_history)),
    }
