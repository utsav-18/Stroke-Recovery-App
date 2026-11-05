Write-Host "Starting RehabTrack Backend API on http://0.0.0.0:8000 (Local & LAN accessible)..." -ForegroundColor Cyan
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --app-dir backend --reload

