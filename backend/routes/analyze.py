from __future__ import annotations

import os
import tempfile
from collections import Counter
from typing import Any

import cv2
import numpy as np
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from db import get_db
from emotion_utils import predict_emotion
from model_loader import load_model
from pose_utils import extract_features_from_video

router = APIRouter(tags=["analysis"])


def _normalize_status(raw_prediction: Any) -> str:
    if isinstance(raw_prediction, str):
        text = raw_prediction.strip().lower().replace("_", " ")
        if "not" in text and "improv" in text:
            return "Not Improved"
        if text in {"no improvement", "no change", "stable"}:
            return "Not Improved"
        if "improving" in text:
            return "Improving"
        if "improved" in text:
            return "Improved"

    if isinstance(raw_prediction, (int, float, np.integer, np.floating)):
        value = int(round(float(raw_prediction)))
        mapping = {
            2: "Improved",
            1: "Improving",
            0: "Not Improved",
            -1: "Not Improved",
        }
        return mapping.get(value, "Not Improved")

    return "Not Improved"


def _extract_confidence(model: Any, sample: np.ndarray) -> float:
    if hasattr(model, "predict_proba"):
        proba = model.predict_proba(sample)
        return float(np.max(proba[0]))

    if hasattr(model, "decision_function"):
        decision = model.decision_function(sample)
        decision_value = float(np.ravel(decision)[0])
        return float(1.0 / (1.0 + np.exp(-abs(decision_value))))

    return 1.0


def _align_feature_vector(model: Any, feature_vector: np.ndarray) -> np.ndarray:
    expected = getattr(model, "n_features_in_", None)
    current = feature_vector.shape[0]

    if expected is None or expected == current:
        return feature_vector

    if current < expected:
        padded = np.zeros(expected, dtype=float)
        padded[:current] = feature_vector
        return padded

    return feature_vector[:expected]


def _is_low_motion(feature_vector: np.ndarray) -> bool:
    # Indices follow pose_utils.extract_features_from_video() output order.
    shoulder_range = float(np.mean(feature_vector[6:8]))
    elbow_range = float(np.mean(feature_vector[8:10]))
    wrist_angle_range = float(np.mean(feature_vector[10:12]))

    wrist_xy_range_max = float(np.max(feature_vector[12:16]))
    mean_wrist_step = float(np.mean(feature_vector[18:20]))

    # Relaxed thresholds: must exceed most to detect actual movement exercise.
    # These are based on typical recovery exercise ranges.
    return (
        shoulder_range < 35.0
        and elbow_range < 40.0
        and wrist_angle_range < 35.0
        and wrist_xy_range_max < 0.25
        and mean_wrist_step < 0.015
    )


def _is_high_quality_motion(feature_vector: np.ndarray) -> bool:
    # Detect excellent, full-range recovery exercises.
    shoulder_range = float(np.mean(feature_vector[6:8]))
    elbow_range = float(np.mean(feature_vector[8:10]))
    wrist_xy_range_max = float(np.max(feature_vector[12:16]))

    return shoulder_range > 100.0 and elbow_range > 100.0 and wrist_xy_range_max > 0.5


def _extract_frames_from_video(video_path: str) -> list[np.ndarray]:
    capture = cv2.VideoCapture(video_path)
    if not capture.isOpened():
        return []

    frames: list[np.ndarray] = []

    while True:
        ok, frame = capture.read()
        if not ok:
            break
        frames.append(frame)

    capture.release()
    return frames


@router.post("/analyze")
async def analyze_video(
    file: UploadFile = File(...),
    debug: bool = Query(False),
    session_id: int | None = Form(None),
    db: Session = Depends(get_db),
) -> dict:
    if not file.filename:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing filename.")

    if file.content_type and not file.content_type.startswith("video/"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Uploaded file must be a video.")

    suffix = os.path.splitext(file.filename)[1] or ".mp4"
    temp_path = ""

    try:
        print("Processing started")
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_file:
            temp_path = temp_file.name

            while True:
                chunk = await file.read(1024 * 1024)
                if not chunk:
                    break
                temp_file.write(chunk)

        features, frames_processed = extract_features_from_video(
            temp_path,
            max_frames=30,
            frame_skip=5,
        )
        print("Frames processed:", frames_processed)

        frames = _extract_frames_from_video(temp_path)
        detected_emotions = []
        for frame in frames[::5]:
            emotion = predict_emotion(frame)
            if emotion != "No Face Detected":
                detected_emotions.append(emotion)

        if detected_emotions:
            final_emotion = Counter(detected_emotions).most_common(1)[0][0]
        else:
            final_emotion = "No Face Detected"

        model = load_model()

        aligned_features = _align_feature_vector(model, features)
        sample = aligned_features.reshape(1, -1)

        prediction = model.predict(sample)
        movement_status = _normalize_status(prediction[0])
        confidence_score = _extract_confidence(model, sample)

        low_motion_flag = _is_low_motion(features)
        if low_motion_flag:
            movement_status = "Not Improved"
            confidence_score = max(0.75, confidence_score)
        elif movement_status == "Improving" and _is_high_quality_motion(features):
            movement_status = "Improved"
            confidence_score = max(0.85, confidence_score)

        response = {
            "movement_status": movement_status,
            "confidence_score": round(float(confidence_score), 4),
            "emotion": final_emotion,
        }

        if session_id is not None:
            db.execute(
                text("""
                INSERT INTO analysis_results (session_id, movement_status, confidence_score, emotion, analyzed_at)
                VALUES (:session_id, :movement_status, :confidence_score, :emotion, NOW())
                ON CONFLICT (session_id) DO UPDATE SET 
                    movement_status = EXCLUDED.movement_status,
                    confidence_score = EXCLUDED.confidence_score,
                    emotion = EXCLUDED.emotion,
                    analyzed_at = NOW()
                """),
                {
                    "session_id": session_id,
                    "movement_status": movement_status,
                    "confidence_score": round(float(confidence_score), 4),
                    "emotion": final_emotion,
                }
            )
            db.commit()

        if debug:
            shoulder_range = float(np.mean(features[6:8]))
            elbow_range = float(np.mean(features[8:10]))
            wrist_angle_range = float(np.mean(features[10:12]))
            wrist_xy_range_max = float(np.max(features[12:16]))
            mean_wrist_step = float(np.mean(features[18:20]))

            response["_debug"] = {
                "raw_prediction": str(prediction[0]),
                "low_motion_detected": low_motion_flag,
                "high_quality_motion_detected": _is_high_quality_motion(features),
                "motion_metrics": {
                    "shoulder_angle_range": round(shoulder_range, 4),
                    "elbow_angle_range": round(elbow_range, 4),
                    "wrist_angle_range": round(wrist_angle_range, 4),
                    "wrist_xy_range_max": round(wrist_xy_range_max, 6),
                    "mean_wrist_step": round(mean_wrist_step, 6),
                },
                "thresholds": {
                    "shoulder_range_threshold": 5.0,
                    "elbow_range_threshold": 5.0,
                    "wrist_angle_range_threshold": 6.0,
                    "wrist_xy_range_threshold": 0.03,
                    "mean_wrist_step_threshold": 0.003,
                    "high_quality_shoulder_threshold": 100.0,
                    "high_quality_elbow_threshold": 100.0,
                    "high_quality_wrist_xy_threshold": 0.5,
                },
            }

        return response

    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Analysis failed: {exc}") from exc
    finally:
        await file.close()
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
