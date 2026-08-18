from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from db import get_db
from deps import require_role
from schemas import DoctorUpdateRequest

router = APIRouter(prefix="/doctors", tags=["doctors"])


def _doctor_row_for_user(db: Session, user_id: int) -> dict:
    row = db.execute(
        text(
            """
            SELECT id, user_id, doctor_code, name, specialization, phone, created_at, updated_at
            FROM doctors
            WHERE user_id = :user_id
            """
        ),
        {"user_id": user_id},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Doctor profile not found.")

    return dict(row)





def _patient_session_rows(db: Session, patient_id: int) -> list[dict]:
    rows = db.execute(
        text(
            """
            SELECT
                s.id,
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
def get_doctor_me(current_user: dict = Depends(require_role("DOCTOR")), db: Session = Depends(get_db)) -> dict:
    return _doctor_row_for_user(db, int(current_user["id"]))


@router.put("/me")
def update_doctor_me(
    payload: DoctorUpdateRequest,
    current_user: dict = Depends(require_role("DOCTOR")),
    db: Session = Depends(get_db),
) -> dict:
    doctor = _doctor_row_for_user(db, int(current_user["id"]))

    updated = db.execute(
        text(
            """
            UPDATE doctors
            SET name = :name,
                specialization = :specialization,
                phone = :phone
            WHERE id = :id
            RETURNING id, user_id, doctor_code, name, specialization, phone, created_at, updated_at
            """
        ),
        {
            "id": doctor["id"],
            "name": payload.name,
            "specialization": payload.specialization,
            "phone": payload.phone,
        },
    ).mappings().first()
    db.commit()

    if not updated:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Update failed.")

    return dict(updated)


@router.get("/me/patients")
def get_assigned_patients(current_user: dict = Depends(require_role("DOCTOR")), db: Session = Depends(get_db)) -> list[dict]:
    # We still fetch doctor to ensure they exist/are valid
    doctor = _doctor_row_for_user(db, int(current_user["id"]))

    rows = db.execute(
        text(
            """
            SELECT
                p.id,
                p.patient_code,
                p.name,
                latest.movement_status AS latest_movement_status,
                latest.confidence_score AS latest_confidence,
                latest.started_at AS latest_session_date
            FROM patients p
            LEFT JOIN LATERAL (
                SELECT
                    s.started_at,
                    a.movement_status,
                    a.confidence_score
                FROM exercise_sessions s
                LEFT JOIN analysis_results a ON a.session_id = s.id
                WHERE s.patient_id = p.id
                ORDER BY s.started_at DESC
                LIMIT 1
            ) latest ON true
            ORDER BY p.name ASC
            """
        )
    ).mappings().all()

    return [
        {
            "id": row["id"],
            "patient_code": row["patient_code"],
            "name": row["name"],
            "latest_movement_status": row["latest_movement_status"],
            "latest_confidence": float(row["latest_confidence"]) if row["latest_confidence"] is not None else None,
            "latest_session_date": row["latest_session_date"],
        }
        for row in rows
    ]


@router.get("/me/patients/{patient_id}")
def get_patient_detail(
    patient_id: int,
    current_user: dict = Depends(require_role("DOCTOR")),
    db: Session = Depends(get_db),
) -> dict:
    doctor = _doctor_row_for_user(db, int(current_user["id"]))

    patient = db.execute(
        text(
            """
            SELECT id, patient_code, name, date_of_birth, gender, phone
            FROM patients
            WHERE id = :patient_id
            """
        ),
        {"patient_id": patient_id},
    ).mappings().first()

    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found.")

    return dict(patient)


@router.get("/me/patients/{patient_id}/progress")
def get_patient_progress_for_doctor(
    patient_id: int,
    current_user: dict = Depends(require_role("DOCTOR")),
    db: Session = Depends(get_db),
) -> dict:
    doctor = _doctor_row_for_user(db, int(current_user["id"]))

    rows = _patient_session_rows(db, patient_id)
    if not rows:
        return {
            "patient_id": patient_id,
            "total_sessions": 0,
            "improving_patients": 0,
            "average_confidence": 0.0,
            "latest_movement_status": "No analysis yet",
            "movement_history": [],
            "confidence_trend": [],
            "emotion_history": [],
            "sessions": [],
        }

    confidence_scores = [float(row["confidence_score"]) for row in rows if row["confidence_score"] is not None]
    latest_with_analysis = next((row for row in rows if row["movement_status"] is not None), rows[0])
    
    movement_history = [
        {
            "date": row["started_at"].date().isoformat() if row["started_at"] else None,
            "status": row["movement_status"] or "No analysis yet",
        }
        for row in rows
    ]
    emotion_history = [
        {
            "date": row["started_at"].date().isoformat() if row["started_at"] else None,
            "emotion": row["emotion"] or "No Face Detected",
        }
        for row in rows
    ]

    return {
        "patient_id": patient_id,
        "total_sessions": len(rows),
        "improving_patients": sum(1 for row in rows if (row["movement_status"] or "").lower() == "improving"),
        "average_confidence": round(sum(confidence_scores) / len(confidence_scores), 4) if confidence_scores else 0.0,
        "latest_movement_status": latest_with_analysis["movement_status"] or "No analysis yet",
        "movement_history": list(reversed(movement_history)),
        "confidence_trend": list(reversed([round(c, 4) for c in confidence_scores])),
        "emotion_history": list(reversed(emotion_history)),
        "sessions": [
            {
                "id": row["id"],
                "exercise_type": row["exercise_type"],
                "started_at": row["started_at"],
                "movement_status": row["movement_status"] or "Not Improved",
                "confidence_score": float(row["confidence_score"]) if row["confidence_score"] is not None else None,
                "emotion": row["emotion"] or "No Face Detected",
            }
            for row in rows
        ],
    }
