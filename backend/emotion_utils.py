from __future__ import annotations

from typing import Any

import cv2
import numpy as np
import torch

from model_loader import get_emotion_model

EMOTION_LABELS = ["Angry", "Happy", "Neutral", "Sad"]
FACE_CASCADE = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")


def _to_numpy(input_data: Any) -> np.ndarray:
    if hasattr(input_data, "detach"):
        input_data = input_data.detach()

    if hasattr(input_data, "cpu"):
        input_data = input_data.cpu()

    if hasattr(input_data, "numpy"):
        try:
            input_data = input_data.numpy()
        except TypeError:
            pass

    return np.asarray(input_data)


def _prepare_face_tensor(input_data: Any) -> torch.Tensor | None:
    frame = _to_numpy(input_data)
    if frame.size == 0:
        return None

    if frame.ndim == 3 and frame.shape[-1] == 3:
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    elif frame.ndim == 2:
        gray_frame = frame
    else:
        return None

    if FACE_CASCADE.empty():
        face_region = gray_frame
    else:
        faces = FACE_CASCADE.detectMultiScale(gray_frame, scaleFactor=1.1, minNeighbors=5, minSize=(24, 24))
        if len(faces) == 0:
            return None

        x, y, width, height = max(faces, key=lambda rect: rect[2] * rect[3])
        face_region = gray_frame[y : y + height, x : x + width]

    face_region = cv2.resize(face_region, (48, 48), interpolation=cv2.INTER_AREA)
    face_region = face_region.astype(np.float32) / 255.0

    input_tensor = torch.from_numpy(face_region).unsqueeze(0).unsqueeze(0)
    input_tensor = input_tensor.repeat(1, 3, 1, 1)
    return input_tensor


def predict_emotion(input_data: Any) -> str:
    input_tensor = _prepare_face_tensor(input_data)
    if input_tensor is None:
        return "No Face Detected"

    model = get_emotion_model()

    with torch.no_grad():
        output = model(input_tensor)
        prediction = torch.argmax(output, dim=1).item()

    if 0 <= prediction < len(EMOTION_LABELS):
        return EMOTION_LABELS[prediction]

    return "No Face Detected"