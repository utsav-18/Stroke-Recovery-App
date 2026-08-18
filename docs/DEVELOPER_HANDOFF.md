# RehabTrack Developer Handoff

## Overview

RehabTrack is a patient-first stroke recovery monitoring workflow with a matching doctor dashboard. The Flutter apps are intentionally separated from the data layer and will connect to FastAPI, which in turn talks to PostgreSQL. The app does not store videos permanently.

## Database structure

The PostgreSQL schema is defined in `database/schema.sql` and includes the following tables:

- `users`
- `patients`
- `doctors`
- `doctor_patients`
- `exercise_sessions`
- `analysis_results`

The relationships are:

- `users` -> `patients`
- `users` -> `doctors`
- `doctors` -> `doctor_patients` -> `patients`
- `patients` -> `exercise_sessions` -> `analysis_results`

## Key business rules

- `users.role` is restricted to `PATIENT` or `DOCTOR`.
- `patients.user_id` and `doctors.user_id` must refer to a row in `users`.
- `doctor_patients` links a doctor to a patient and records assignment status.
- `exercise_sessions` stores the session metadata only; no video file is saved.
- `analysis_results` stores movement status, confidence score, and emotion only.

## API expectations

The required endpoints are documented in `docs/API_CONTRACT.md`.

Important backend requirements:

- `POST /analyze`: accept a video upload and return a payload with `movement_status`, `confidence_score`, and `emotion`.
- `GET /patients/me` and `/doctors/me` must return the authenticated user’s profile.
- `GET /doctors/me/patients/{patient_id}/progress` must return patient progress and session history grouped for doctor review.
- All patient and doctor endpoints are authenticated.

## Authentication rules

- Patient accounts should only access their own patient profile and sessions.
- Doctor accounts should only access assigned patients.
- Firebase/Auth-style patterns are not required; this can be implemented with JWT or session auth in FastAPI.

## No video storage requirement

The backend must process the uploaded exercise video and save only the result metadata in PostgreSQL. Temporary files should be deleted after analysis. The Flutter app does not persist exercise videos after the session is analyzed.

## Flutter app expectations

The Flutter apps are prepared for backend integration with a central `API_BASE_URL` value. The current app uses mock/local data until the FastAPI endpoints are available.

- Frontend should never connect directly to PostgreSQL.
- The app should call FastAPI endpoints through a service layer.
- Mock data should be isolated and easy to replace.
- UI must not depend on `_debug` data from the analysis endpoint.

## Relevant files

- `database/schema.sql`
- `database/seed.sql`
- `database/README.md`
- `docs/API_CONTRACT.md`
- `flutter_app/lib/services/api_service.dart`
- `flutter_app/lib/services/mock_data_service.dart`
