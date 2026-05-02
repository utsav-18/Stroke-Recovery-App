from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List

import cv2
import mediapipe as mp
import numpy as np


@dataclass
class PoseSeries:
    left_shoulder: np.ndarray
    left_elbow: np.ndarray
    left_wrist: np.ndarray
    left_index: np.ndarray
    left_hip: np.ndarray
    right_shoulder: np.ndarray
    right_elbow: np.ndarray
    right_wrist: np.ndarray
    right_index: np.ndarray
    right_hip: np.ndarray


def _compute_angle(point_a: np.ndarray, point_b: np.ndarray, point_c: np.ndarray) -> float:
    """Compute angle ABC in degrees using 2D coordinates."""
    ba = point_a[:2] - point_b[:2]
    bc = point_c[:2] - point_b[:2]

    denom = (np.linalg.norm(ba) * np.linalg.norm(bc))
    if denom <= 1e-8:
        return 0.0

    cosine = float(np.dot(ba, bc) / denom)
    cosine = float(np.clip(cosine, -1.0, 1.0))
    return float(np.degrees(np.arccos(cosine)))


def _extract_pose_series(video_path: str, min_visibility: float = 0.4) -> PoseSeries:
    """Extract required pose landmarks across all valid frames."""
    pose_landmarks = mp.solutions.pose.PoseLandmark

    capture = cv2.VideoCapture(video_path)
    if not capture.isOpened():
        raise ValueError("Unable to open video file.")

    left_shoulder: List[np.ndarray] = []
    left_elbow: List[np.ndarray] = []
    left_wrist: List[np.ndarray] = []
    left_index: List[np.ndarray] = []
    left_hip: List[np.ndarray] = []

    right_shoulder: List[np.ndarray] = []
    right_elbow: List[np.ndarray] = []
    right_wrist: List[np.ndarray] = []
    right_index: List[np.ndarray] = []
    right_hip: List[np.ndarray] = []

    with mp.solutions.pose.Pose(
        static_image_mode=False,
        model_complexity=1,
        enable_segmentation=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ) as pose:
        while True:
            ok, frame = capture.read()
            if not ok:
                break

            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb_frame)
            if not results.pose_landmarks:
                continue

            lm = results.pose_landmarks.landmark

            left_points = [
                lm[pose_landmarks.LEFT_SHOULDER.value],
                lm[pose_landmarks.LEFT_ELBOW.value],
                lm[pose_landmarks.LEFT_WRIST.value],
                lm[pose_landmarks.LEFT_INDEX.value],
                lm[pose_landmarks.LEFT_HIP.value],
            ]
            right_points = [
                lm[pose_landmarks.RIGHT_SHOULDER.value],
                lm[pose_landmarks.RIGHT_ELBOW.value],
                lm[pose_landmarks.RIGHT_WRIST.value],
                lm[pose_landmarks.RIGHT_INDEX.value],
                lm[pose_landmarks.RIGHT_HIP.value],
            ]

            min_visible = min(p.visibility for p in left_points + right_points)
            if min_visible < min_visibility:
                continue

            left_shoulder.append(np.array([left_points[0].x, left_points[0].y, left_points[0].z], dtype=float))
            left_elbow.append(np.array([left_points[1].x, left_points[1].y, left_points[1].z], dtype=float))
            left_wrist.append(np.array([left_points[2].x, left_points[2].y, left_points[2].z], dtype=float))
            left_index.append(np.array([left_points[3].x, left_points[3].y, left_points[3].z], dtype=float))
            left_hip.append(np.array([left_points[4].x, left_points[4].y, left_points[4].z], dtype=float))

            right_shoulder.append(np.array([right_points[0].x, right_points[0].y, right_points[0].z], dtype=float))
            right_elbow.append(np.array([right_points[1].x, right_points[1].y, right_points[1].z], dtype=float))
            right_wrist.append(np.array([right_points[2].x, right_points[2].y, right_points[2].z], dtype=float))
            right_index.append(np.array([right_points[3].x, right_points[3].y, right_points[3].z], dtype=float))
            right_hip.append(np.array([right_points[4].x, right_points[4].y, right_points[4].z], dtype=float))

    capture.release()

    if not left_wrist or not right_wrist:
        raise ValueError("No reliable pose landmarks detected in video.")

    return PoseSeries(
        left_shoulder=np.vstack(left_shoulder),
        left_elbow=np.vstack(left_elbow),
        left_wrist=np.vstack(left_wrist),
        left_index=np.vstack(left_index),
        left_hip=np.vstack(left_hip),
        right_shoulder=np.vstack(right_shoulder),
        right_elbow=np.vstack(right_elbow),
        right_wrist=np.vstack(right_wrist),
        right_index=np.vstack(right_index),
        right_hip=np.vstack(right_hip),
    )


def extract_features_from_video(video_path: str) -> np.ndarray:
    """Build model-ready features from pose keypoints in a video."""
    series = _extract_pose_series(video_path)

    left_shoulder_angles = [
        _compute_angle(series.left_hip[i], series.left_shoulder[i], series.left_elbow[i])
        for i in range(len(series.left_shoulder))
    ]
    right_shoulder_angles = [
        _compute_angle(series.right_hip[i], series.right_shoulder[i], series.right_elbow[i])
        for i in range(len(series.right_shoulder))
    ]

    left_elbow_angles = [
        _compute_angle(series.left_shoulder[i], series.left_elbow[i], series.left_wrist[i])
        for i in range(len(series.left_elbow))
    ]
    right_elbow_angles = [
        _compute_angle(series.right_shoulder[i], series.right_elbow[i], series.right_wrist[i])
        for i in range(len(series.right_elbow))
    ]

    left_wrist_angles = [
        _compute_angle(series.left_elbow[i], series.left_wrist[i], series.left_index[i])
        for i in range(len(series.left_wrist))
    ]
    right_wrist_angles = [
        _compute_angle(series.right_elbow[i], series.right_wrist[i], series.right_index[i])
        for i in range(len(series.right_wrist))
    ]

    left_wrist_path = np.linalg.norm(np.diff(series.left_wrist[:, :2], axis=0), axis=1)
    right_wrist_path = np.linalg.norm(np.diff(series.right_wrist[:, :2], axis=0), axis=1)

    left_motion_consistency = 1.0 / (1.0 + float(np.std(left_wrist_path))) if len(left_wrist_path) else 0.0
    right_motion_consistency = 1.0 / (1.0 + float(np.std(right_wrist_path))) if len(right_wrist_path) else 0.0

    features = np.array(
        [
            float(np.mean(left_shoulder_angles)),
            float(np.mean(right_shoulder_angles)),
            float(np.mean(left_elbow_angles)),
            float(np.mean(right_elbow_angles)),
            float(np.mean(left_wrist_angles)),
            float(np.mean(right_wrist_angles)),
            float(np.ptp(left_shoulder_angles)),
            float(np.ptp(right_shoulder_angles)),
            float(np.ptp(left_elbow_angles)),
            float(np.ptp(right_elbow_angles)),
            float(np.ptp(left_wrist_angles)),
            float(np.ptp(right_wrist_angles)),
            float(np.ptp(series.left_wrist[:, 0])),
            float(np.ptp(series.left_wrist[:, 1])),
            float(np.ptp(series.right_wrist[:, 0])),
            float(np.ptp(series.right_wrist[:, 1])),
            left_motion_consistency,
            right_motion_consistency,
            float(np.mean(left_wrist_path)) if len(left_wrist_path) else 0.0,
            float(np.mean(right_wrist_path)) if len(right_wrist_path) else 0.0,
        ],
        dtype=float,
    )

    return features
