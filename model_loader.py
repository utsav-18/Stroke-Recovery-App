from functools import lru_cache
from pathlib import Path
import sys
from typing import Any

import joblib
import numpy as np


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
    model_path = Path(__file__).resolve().parent / model_filename
    if not model_path.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")

    _ensure_numpy_pickle_compat()

    try:
        return joblib.load(model_path)
    except ModuleNotFoundError as exc:
        if "numpy._core" in str(exc):
            raise RuntimeError(
                "Model load failed due to NumPy compatibility. "
                "Try upgrading NumPy in this environment: pip install --upgrade numpy"
            ) from exc
        raise
