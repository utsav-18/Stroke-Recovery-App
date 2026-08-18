# RehabTrack API Contract

This contract defines the backend interfaces required for the RehabTrack Flutter apps. The FastAPI implementation is intentionally not included here; it will be built by the backend team.

## Shared conventions

- Base URL is configurable through the Flutter app using `API_BASE_URL`.
- Authentication uses Bearer tokens or an equivalent JWT/session scheme implemented by the backend team.
- All JSON payloads are UTF-8 encoded.
- When the app calls an endpoint that returns a list, the array should be sorted by newest-first where relevant.
- The app must not rely on `_debug` payloads. Handling `_debug` is optional and should never be required for rendering UI.

## Authentication endpoints

### POST /auth/register

Authentication requirement: None
Required role: None

Request body:

```json
{
  "email": "patient@example.com",
  "password": "StrongPassword123",
  "role": "PATIENT",
  "name": "Ava Thompson"
}
```

Response JSON:

```json
{
  "user": {
    "id": 1,
    "email": "patient@example.com",
    "role": "PATIENT",
    "name": "Ava Thompson"
  },
  "token": "jwt-or-session-token"
}
```

Possible errors:
- `400` validation failure
- `409` email already exists
- `500` server error

### POST /auth/login

Authentication requirement: None
Required role: None

Request body:

```json
{
  "email": "patient@example.com",
  "password": "StrongPassword123"
}
```

Response JSON:

```json
{
  "user": {
    "id": 1,
    "email": "patient@example.com",
    "role": "PATIENT",
    "name": "Ava Thompson"
  },
  "token": "jwt-or-session-token"
}
```

Possible errors:
- `401` invalid credentials
- `404` user not found
- `500` server error

### GET /auth/me

Authentication requirement: Required
Required role: PATIENT or DOCTOR

Response JSON:

```json
{
  "id": 1,
  "email": "patient@example.com",
  "role": "PATIENT",
  "name": "Ava Thompson"
}
```

Possible errors:
- `401` missing/invalid token
- `500` server error

## Patient endpoints

### GET /patients/me

Authentication requirement: Required
Required role: PATIENT

Response JSON:

```json
{
  "id": 1,
  "user_id": 10,
  "patient_code": "PT-2001",
  "name": "Ava Thompson",
  "date_of_birth": "1991-04-18",
  "gender": "Female",
  "phone": "+1 (415) 555-0101",
  "created_at": "2026-01-10T08:00:00Z",
  "updated_at": "2026-01-10T08:00:00Z"
}
```

Possible errors:
- `401` unauthorized
- `403` not a patient
- `404` patient profile not found

### PUT /patients/me

Authentication requirement: Required
Required role: PATIENT

Request body:

```json
{
  "name": "Ava Thompson",
  "date_of_birth": "1991-04-18",
  "gender": "Female",
  "phone": "+1 (415) 555-0101"
}
```

Response JSON:

```json
{
  "id": 1,
  "user_id": 10,
  "patient_code": "PT-2001",
  "name": "Ava Thompson",
  "date_of_birth": "1991-04-18",
  "gender": "Female",
  "phone": "+1 (415) 555-0101",
  "updated_at": "2026-08-18T20:00:00Z"
}
```

Possible errors:
- `400` validation failure
- `401` unauthorized
- `500` server error

### GET /patients/me/sessions

Authentication requirement: Required
Required role: PATIENT

Response JSON:

```json
[
  {
    "id": 15,
    "patient_id": 1,
    "exercise_type": "Shoulder Flexion",
    "started_at": "2026-08-18T09:00:00Z",
    "completed_at": "2026-08-18T09:06:00Z",
    "analysis": {
      "movement_status": "Improved",
      "confidence_score": 0.87,
      "emotion": "Happy"
    }
  }
]
```

Possible errors:
- `401` unauthorized
- `404` no sessions found
- `500` server error

### GET /patients/me/progress

Authentication requirement: Required
Required role: PATIENT

Response JSON:

```json
{
  "patient_id": 1,
  "total_sessions": 8,
  "average_confidence": 0.85,
  "latest_movement_status": "Improved",
  "confidence_trend": [0.72, 0.78, 0.81, 0.87],
  "movement_history": [
    { "date": "2026-08-01", "status": "Not Improved" },
    { "date": "2026-08-10", "status": "Improving" },
    { "date": "2026-08-18", "status": "Improved" }
  ],
  "emotion_history": [
    { "date": "2026-08-01", "emotion": "Frustrated" },
    { "date": "2026-08-10", "emotion": "Calm" },
    { "date": "2026-08-18", "emotion": "Happy" }
  ]
}
```

Possible errors:
- `401` unauthorized
- `404` no progress available
- `500` server error

### POST /patients/me/sessions

Authentication requirement: Required
Required role: PATIENT

Request body:

```json
{
  "exercise_type": "Shoulder Flexion",
  "started_at": "2026-08-18T09:00:00Z",
  "completed_at": "2026-08-18T09:06:00Z"
}
```

Response JSON:

```json
{
  "id": 15,
  "patient_id": 1,
  "exercise_type": "Shoulder Flexion",
  "started_at": "2026-08-18T09:00:00Z",
  "completed_at": "2026-08-18T09:06:00Z"
}
```

Possible errors:
- `400` invalid payload
- `401` unauthorized
- `500` server error

## Exercise analysis endpoint

### POST /analyze

Authentication requirement: Required for production
Required role: PATIENT

Request body:

- `multipart/form-data`
- field: `file` (video file)
- optional: `debug=false` query parameter (not required by the app)

The current backend contract must remain compatible with the following response:

```json
{
  "movement_status": "Improved",
  "confidence_score": 0.86,
  "emotion": "Happy"
}
```

This response should be returned as JSON. The Flutter app must not depend on an `_debug` field. `_debug` is optional metadata for developer inspection only.

Possible errors:
- `400` invalid or missing video file
- `401` unauthorized
- `422` bad video or processing error
- `500` analysis failure

## Doctor endpoints

### GET /doctors/me

Authentication requirement: Required
Required role: DOCTOR

Response JSON:

```json
{
  "id": 2,
  "user_id": 12,
  "doctor_code": "DOC-1001",
  "name": "Dr. Emma Smith",
  "specialization": "Neurological Rehabilitation",
  "phone": "+1 (415) 555-0101"
}
```

Possible errors:
- `401` unauthorized
- `403` not a doctor
- `404` doctor profile not found

### GET /doctors/me/patients

Authentication requirement: Required
Required role: DOCTOR

Response JSON:

```json
[
  {
    "id": 1,
    "patient_code": "PT-2001",
    "name": "Ava Thompson",
    "latest_movement_status": "Improved",
    "latest_confidence": 0.87,
    "latest_session_date": "2026-08-18T09:06:00Z"
  }
]
```

Possible errors:
- `401` unauthorized
- `500` server error

### GET /doctors/me/patients/{patient_id}

Authentication requirement: Required
Required role: DOCTOR

Response JSON:

```json
{
  "id": 1,
  "patient_code": "PT-2001",
  "name": "Ava Thompson",
  "date_of_birth": "1991-04-18",
  "gender": "Female",
  "phone": "+1 (415) 555-0101"
}
```

Possible errors:
- `401` unauthorized
- `403` patient not assigned to doctor
- `404` patient not found

### GET /doctors/me/patients/{patient_id}/progress

Authentication requirement: Required
Required role: DOCTOR

Response JSON:

```json
{
  "patient_id": 1,
  "total_sessions": 8,
  "improving_patients": 3,
  "average_confidence": 0.85,
  "movement_trend": [
    { "date": "2026-08-01", "status": "Not Improved" },
    { "date": "2026-08-10", "status": "Improving" },
    { "date": "2026-08-18", "status": "Improved" }
  ],
  "confidence_trend": [0.72, 0.78, 0.81, 0.87],
  "emotion_history": [
    { "date": "2026-08-01", "emotion": "Frustrated" },
    { "date": "2026-08-10", "emotion": "Calm" },
    { "date": "2026-08-18", "emotion": "Happy" }
  ],
  "sessions": [
    {
      "id": 15,
      "exercise_type": "Shoulder Flexion",
      "started_at": "2026-08-18T09:00:00Z",
      "movement_status": "Improved",
      "confidence_score": 0.87,
      "emotion": "Happy"
    }
  ]
}
```

Possible errors:
- `401` unauthorized
- `403` patient not assigned to doctor
- `404` patient not found
- `500` server error

## Authorization rules

- `PATIENT` users can only access their own patient profile and session data.
- `DOCTOR` users can only access assigned patients.
- `users` table stores the roles; `patients` and `doctors` tables contain the role-specific profile rows.
- All endpoints should enforce that a `PATIENT` cannot access another patient’s records and a `DOCTOR` cannot access unassigned patients.

## Video handling requirement

This application intentionally does not store exercise videos permanently. After the backend receives an upload, it should process the video, save only the final metadata to PostgreSQL, and delete the temporary video file immediately after analysis.
