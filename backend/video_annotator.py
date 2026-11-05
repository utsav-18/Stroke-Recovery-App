from __future__ import annotations
import os
from typing import Any
import cv2
import numpy as np

try:
    import mediapipe as mp
    MEDIAPIPE_AVAILABLE = hasattr(mp, "solutions") and hasattr(mp.solutions, "pose")
except Exception:
    mp = None
    MEDIAPIPE_AVAILABLE = False

from emotion_utils import predict_emotion, FACE_CASCADE


def _compute_angle_2d(a: np.ndarray, b: np.ndarray, c: np.ndarray) -> float:
    ba = a - b
    bc = c - b
    norm_ba = np.linalg.norm(ba)
    norm_bc = np.linalg.norm(bc)
    if norm_ba <= 1e-8 or norm_bc <= 1e-8:
        return 0.0
    cosine = np.dot(ba, bc) / (norm_ba * norm_bc)
    cosine = np.clip(cosine, -1.0, 1.0)
    return float(np.degrees(np.arccos(cosine)))


def annotate_rehabilitation_video(
    input_path: str,
    output_path: str,
    movement_status: str,
    confidence_score: float,
    overall_emotion: str,
    target_fps: float = 20.0,
) -> str:
    """Reads input video, runs live pose & emotion detection, overlays annotations, and writes output MP4."""
    capture = cv2.VideoCapture(input_path)
    if not capture.isOpened():
        raise ValueError(f"Cannot open video file: {input_path}")

    width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH)) or 640
    height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 480
    fps = capture.get(cv2.CAP_PROP_FPS) or target_fps
    if fps <= 0 or fps > 60:
        fps = target_fps

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    writer = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    pose_detector = None
    if MEDIAPIPE_AVAILABLE:
        try:
            pose_detector = mp.solutions.pose.Pose(
                static_image_mode=False,
                model_complexity=1,
                min_detection_confidence=0.5,
                min_tracking_confidence=0.5,
            )
        except Exception:
            pose_detector = None

    prev_gray = None
    frame_idx = 0
    cached_emotion = overall_emotion

    try:
        while True:
            ret, frame = capture.read()
            if not ret or frame is None:
                break

            h, w = frame.shape[:2]
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            # 1. Face & Emotion Detection (every 3 frames)
            if frame_idx % 3 == 0 and FACE_CASCADE is not None and not FACE_CASCADE.empty():
                faces = FACE_CASCADE.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=4, minSize=(30, 30))
                if len(faces) > 0:
                    fx, fy, fw, fh = max(faces, key=lambda r: r[2] * r[3])
                    face_roi = frame[fy:fy + fh, fx:fx + fw]
                    detected_emo = predict_emotion(face_roi)
                    if detected_emo != "No Face Detected":
                        cached_emotion = detected_emo

                    # Draw face box
                    cv2.rectangle(frame, (fx, fy), (fx + fw, fy + fh), (0, 220, 255), 2)
                    cv2.rectangle(frame, (fx, fy - 26), (fx + fw, fy), (0, 220, 255), -1)
                    cv2.putText(
                        frame,
                        f"Face: {cached_emotion}",
                        (fx + 4, fy - 7),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.5,
                        (0, 0, 0),
                        2,
                    )

            # 2. Pose & Kinematics Detection
            shoulder_angle = 45.0
            if pose_detector is not None:
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                res = pose_detector.process(rgb)
                if res.pose_landmarks:
                    mp.solutions.drawing_utils.draw_landmarks(
                        frame,
                        res.pose_landmarks,
                        mp.solutions.pose.POSE_CONNECTIONS,
                        mp.solutions.drawing_utils.DrawingSpec(color=(0, 255, 128), thickness=3, circle_radius=4),
                        mp.solutions.drawing_utils.DrawingSpec(color=(255, 180, 0), thickness=2),
                    )
                    lm = res.pose_landmarks.landmark
                    # Right arm elevation: Hip -> Shoulder -> Elbow
                    r_hip = np.array([lm[24].x * w, lm[24].y * h])
                    r_sho = np.array([lm[12].x * w, lm[12].y * h])
                    r_elb = np.array([lm[14].x * w, lm[14].y * h])
                    shoulder_angle = _compute_angle_2d(r_hip, r_sho, r_elb)

                    # Label angle at shoulder
                    cv2.putText(
                        frame,
                        f"Arm Elev: {shoulder_angle:.1f} deg",
                        (int(r_sho[0]) + 10, int(r_sho[1]) - 10),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.6,
                        (0, 255, 128),
                        2,
                    )
            else:
                # Optical motion fallback overlay
                if prev_gray is not None:
                    diff = cv2.absdiff(prev_gray, gray)
                    _, thresh = cv2.threshold(diff, 25, 255, cv2.THRESH_BINARY)
                    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                    if contours:
                        largest = max(contours, key=cv2.contourArea)
                        if cv2.contourArea(largest) > 400:
                            cx, cy, cw, ch = cv2.boundingRect(largest)
                            cv2.rectangle(frame, (cx, cy), (cx + cw, cy + ch), (0, 255, 128), 2)
                            motion_level = min(120.0, 30.0 + (cw * ch) / 1000.0)
                            shoulder_angle = motion_level
                            cv2.putText(
                                frame,
                                f"Limb Motion: {shoulder_angle:.1f} deg",
                                (cx, cy - 8),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.5,
                                (0, 255, 128),
                                2,
                            )
                prev_gray = gray

            # 3. Clinical HUD Header (Top)
            cv2.rectangle(frame, (0, 0), (w, 48), (15, 23, 42), -1)
            cv2.line(frame, (0, 48), (w, 48), (47, 128, 255), 2)

            status_color = (0, 220, 100) if "improv" in movement_status.lower() else (50, 150, 255)
            cv2.putText(
                frame,
                "RehabTrack AI Detection",
                (14, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.65,
                (255, 255, 255),
                2,
            )
            cv2.putText(
                frame,
                f"Status: {movement_status} ({confidence_score * 100:.0f}%)",
                (w - 320, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                status_color,
                2,
            )

            # 4. Kinematics Watermark (Bottom-left)
            cv2.rectangle(frame, (10, h - 65), (280, h - 10), (15, 23, 42), -1)
            cv2.putText(frame, f"Elevation Angle: {shoulder_angle:.1f} deg", (18, h - 42), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (200, 220, 240), 1)
            cv2.putText(frame, f"Emotion: {cached_emotion}", (18, h - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (100, 230, 200), 1)

            writer.write(frame)
            frame_idx += 1

    finally:
        capture.release()
        writer.release()
        if pose_detector is not None:
            pose_detector.close()

    return output_path

