from functools import lru_cache
import os
import sys
from typing import Any

import joblib
import numpy as np
import torch
import torch.nn as nn


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
emotion_model_path = os.path.join(BASE_DIR, "emotion_model.pkl")
stroke_model_path = os.path.join(BASE_DIR, "stroke_recovery_model_synth.pkl")


class ConvBNReLU(nn.Sequential):
    def __init__(self, in_channels: int, out_channels: int, kernel_size: int, stride: int = 1) -> None:
        padding = kernel_size // 2
        super().__init__(
            nn.Conv2d(in_channels, out_channels, kernel_size, stride=stride, padding=padding, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
        )


class ConvBN(nn.Sequential):
    def __init__(self, in_channels: int, out_channels: int, kernel_size: int, stride: int = 1) -> None:
        padding = kernel_size // 2
        super().__init__(
            nn.Conv2d(in_channels, out_channels, kernel_size, stride=stride, padding=padding, bias=False),
            nn.BatchNorm2d(out_channels),
        )


class SqueezeExcite(nn.Module):
    def __init__(self, channels: int, squeeze_channels: int) -> None:
        super().__init__()
        self.fc1 = nn.Conv2d(channels, squeeze_channels, kernel_size=1)
        self.relu = nn.ReLU(inplace=True)
        self.fc2 = nn.Conv2d(squeeze_channels, channels, kernel_size=1)
        self.sigmoid = nn.Sigmoid()

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        scale = inputs.mean(dim=(2, 3), keepdim=True)
        scale = self.fc1(scale)
        scale = self.relu(scale)
        scale = self.fc2(scale)
        scale = self.sigmoid(scale)
        return inputs * scale


class FeatureStage(nn.Module):
    def __init__(self, branches: list[nn.Module], output_branch_index: int) -> None:
        super().__init__()
        self.block = nn.ModuleList(branches)
        self.output_branch_index = output_branch_index

    @staticmethod
    def _first_conv_in_channels(module: nn.Module) -> int | None:
        for child in module.modules():
            if isinstance(child, nn.Conv2d):
                return child.in_channels
        return None

    @staticmethod
    def _match_channels(inputs: torch.Tensor, expected_channels: int) -> torch.Tensor:
        current_channels = inputs.shape[1]
        if current_channels == expected_channels:
            return inputs

        if expected_channels == 1:
            return inputs.mean(dim=1, keepdim=True)

        if current_channels > expected_channels:
            return inputs[:, :expected_channels, :, :]

        repeat_factor = (expected_channels + current_channels - 1) // current_channels
        repeated = inputs.repeat(1, repeat_factor, 1, 1)
        return repeated[:, :expected_channels, :, :]

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        branch = self.block[self.output_branch_index]
        expected_channels = self._first_conv_in_channels(branch)
        if expected_channels is not None:
            inputs = self._match_channels(inputs, expected_channels)
        return branch(inputs)


class EmotionModel(nn.Module):
    def __init__(self) -> None:
        super().__init__()
        self.features = nn.ModuleList(
            [
                ConvBNReLU(3, 16, 3),
                FeatureStage(
                    [
                        ConvBNReLU(1, 16, 3),
                        SqueezeExcite(16, 8),
                        ConvBN(16, 16, 1),
                    ],
                    output_branch_index=2,
                ),
                FeatureStage(
                    [
                        ConvBN(16, 72, 1),
                        ConvBNReLU(1, 72, 3),
                        ConvBN(72, 24, 1),
                    ],
                    output_branch_index=2,
                ),
                FeatureStage(
                    [
                        ConvBN(24, 88, 1),
                        ConvBNReLU(1, 88, 3),
                        ConvBN(88, 24, 1),
                    ],
                    output_branch_index=2,
                ),
                FeatureStage(
                    [
                        ConvBN(24, 96, 1),
                        ConvBNReLU(1, 96, 5),
                        SqueezeExcite(96, 24),
                        ConvBN(96, 40, 1),
                    ],
                    output_branch_index=3,
                ),
                FeatureStage(
                    [
                        ConvBN(40, 240, 1),
                        ConvBNReLU(1, 240, 5),
                        SqueezeExcite(240, 64),
                        ConvBN(240, 40, 1),
                    ],
                    output_branch_index=3,
                ),
                FeatureStage(
                    [
                        ConvBN(40, 240, 1),
                        ConvBNReLU(1, 240, 5),
                        SqueezeExcite(240, 64),
                        ConvBN(240, 40, 1),
                    ],
                    output_branch_index=3,
                ),
                FeatureStage(
                    [
                        ConvBN(40, 120, 1),
                        ConvBNReLU(1, 120, 5),
                        SqueezeExcite(120, 32),
                        ConvBN(120, 48, 1),
                    ],
                    output_branch_index=3,
                ),
                FeatureStage(
                    [
                        ConvBN(48, 144, 1),
                        ConvBNReLU(1, 144, 5),
                        SqueezeExcite(144, 40),
                        ConvBN(144, 48, 1),
                    ],
                    output_branch_index=3,
                ),
                FeatureStage(
                    [
                        ConvBN(48, 288, 1),
                        ConvBNReLU(1, 288, 5),
                        SqueezeExcite(288, 72),
                        ConvBN(288, 96, 1),
                    ],
                    output_branch_index=3,
                ),
                FeatureStage(
                    [
                        ConvBN(96, 576, 1),
                        ConvBNReLU(1, 576, 5),
                        SqueezeExcite(576, 144),
                        ConvBN(576, 96, 1),
                    ],
                    output_branch_index=3,
                ),
                FeatureStage(
                    [
                        ConvBN(96, 576, 1),
                        ConvBNReLU(1, 576, 5),
                        SqueezeExcite(576, 144),
                        ConvBN(576, 96, 1),
                    ],
                    output_branch_index=3,
                ),
                ConvBN(96, 576, 1),
            ]
        )
        self.classifier = nn.Sequential(
            nn.Linear(576, 1024),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.5),
            nn.Linear(1024, 4),
        )

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        if inputs.ndim != 4:
            raise ValueError("EmotionModel expects a 4D tensor with shape [N, C, H, W].")

        if inputs.shape[1] == 1:
            inputs = inputs.repeat(1, 3, 1, 1)

        x = inputs
        for layer in self.features:
            x = layer(x)

        x = torch.nn.functional.adaptive_avg_pool2d(x, (1, 1))
        x = torch.flatten(x, 1)
        return self.classifier(x)


def _ensure_numpy_pickle_compat() -> None:
    """Bridge pickle module-path differences across NumPy versions."""
    if "numpy._core" not in sys.modules:
        # Some pickled models reference numpy._core (NumPy 2+); older NumPy exposes numpy.core.
        sys.modules["numpy._core"] = np.core

    # Some pickles reference concrete submodules; map them when available.
    try:
        import numpy.core.multiarray as core_multiarray
        import numpy.core.numerictypes as core_numerictypes
        import numpy.core.umath as core_umath

        sys.modules.setdefault("numpy._core.multiarray", core_multiarray)
        sys.modules.setdefault("numpy._core.numerictypes", core_numerictypes)
        sys.modules.setdefault("numpy._core.umath", core_umath)
    except Exception:
        # Best-effort compatibility shim.
        pass


@lru_cache(maxsize=1)
def load_model(model_filename: str = "stroke_recovery_model_synth.pkl") -> Any:
    """Load and cache the trained model from disk."""
    try:
        model_path = stroke_model_path if model_filename == "stroke_recovery_model_synth.pkl" else os.path.join(BASE_DIR, model_filename)
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")

        _ensure_numpy_pickle_compat()
        return joblib.load(model_path)
    except ModuleNotFoundError as exc:
        if "numpy._core" in str(exc):
            print(
                "Model load failed due to NumPy compatibility. "
                "Try upgrading NumPy in this environment: pip install --upgrade numpy"
            )
            print(f"Model load error: {exc}")
            return None
        print(f"Model load error: {exc}")
        return None
    except Exception as exc:
        print(f"Model load error: {exc}")
        return None


@lru_cache(maxsize=1)
def load_emotion_model(model_filename: str = "emotion_model.pkl") -> Any:
    """Load and cache the emotion model from disk."""
    try:
        model_path = emotion_model_path if model_filename == "emotion_model.pkl" else os.path.join(BASE_DIR, model_filename)
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Emotion model file not found: {model_path}")

        model = EmotionModel()

        try:
            state_dict = torch.load(model_path, map_location="cpu", weights_only=False)
        except Exception:
            _ensure_numpy_pickle_compat()
            state_dict = joblib.load(model_path)

        model.load_state_dict(state_dict)
        model.eval()
        print("Emotion model loaded from:", model_path)
        return model
    except Exception as exc:
        print(f"Emotion model load error: {exc}")
        return None

emotion_model = None

def get_emotion_model():
    global emotion_model
    if emotion_model is None:
        emotion_model = load_emotion_model()
    return emotion_model
