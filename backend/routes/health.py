from datetime import datetime, timezone

from fastapi import APIRouter
import importlib

from typing import Any

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    return {
        "status": "ok",
        "service": "stroke-recovery-monitoring-backend",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/debug/mediapipe")
async def debug_mediapipe() -> dict:
    """Return basic diagnostics about the installed mediapipe package."""
    try:
        mp = importlib.import_module("mediapipe")
    except Exception as exc:  # pragma: no cover - diagnostic
        return {"error": f"import failed: {exc}"}

    has_solutions = hasattr(mp, "solutions")
    # Provide a short listing of top-level attributes that may help debugging
    attrs = [a for a in dir(mp) if not a.startswith("_")][:40]

    return {
        "has_solutions": has_solutions,
        "top_level_attributes_sample": attrs,
    }
