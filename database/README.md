# RehabTrack Database Setup

This directory contains the PostgreSQL schema and development seed data for the RehabTrack platform.

## Purpose

The database stores authentication records, patient/doctor profiles, assignments, exercise sessions, and ML analysis results. It does not store videos or file URLs because the system is designed to process an uploaded exercise video, save only the analysis metadata, and then delete the temporary video after processing.

## Core tables

- `users`: shared authentication table for patient/doctor accounts
- `patients`: patient profile details
- `doctors`: doctor profile details
- `doctor_patients`: assignment linking doctors to patients
- `exercise_sessions`: exercise attempts performed by patients
- `analysis_results`: the ML-based movement and emotion outcome for each session

## Relationships

- `users` is the parent table for both `patients` and `doctors`.
- `doctors` has many-to-many relationships with `patients` through `doctor_patients`.
- `patients` has many `exercise_sessions`.
- Each `exercise_session` has one `analysis_result`.

## Initialization

Create the database and run the schema script:

```bash
createdb rehabtrack_dev
psql -d rehabtrack_dev -f database/schema.sql
psql -d rehabtrack_dev -f database/seed.sql
```

## Seed data

The seed data creates several demo users, doctors, patients, assignments, session history, and movement/emotion results. This gives the Flutter doctor app realistic mock trends without needing live backend data.

## Notes

- Video files are never stored in PostgreSQL.
- Only analysis metadata is persisted for later patient and doctor dashboards.
- The `role` field is restricted to `PATIENT` and `DOCTOR`.
- Passwords are expected to be stored as hashed values in FastAPI, never in Flutter.
