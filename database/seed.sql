-- Seed data for local RehabTrack development
-- Fictional but realistic data for patient and doctor dashboards.

INSERT INTO users (email, password_hash, role) VALUES
    ('dr.smith@rehabtrack.dev', 'mock_hash_doctor_1', 'DOCTOR'),
    ('dr.rivera@rehabtrack.dev', 'mock_hash_doctor_2', 'DOCTOR'),
    ('mia.chen@rehabtrack.dev', 'mock_hash_patient_1', 'PATIENT'),
    ('omar.hassan@rehabtrack.dev', 'mock_hash_patient_2', 'PATIENT'),
    ('nina.patel@rehabtrack.dev', 'mock_hash_patient_3', 'PATIENT'),
    ('leo.martin@rehabtrack.dev', 'mock_hash_patient_4', 'PATIENT'),
    ('alina.garcia@rehabtrack.dev', 'mock_hash_patient_5', 'PATIENT');

INSERT INTO doctors (user_id, doctor_code, name, specialization, phone) VALUES
    (1, 'DOC-1001', 'Dr. Emma Smith', 'Neurological Rehabilitation', '+1 (415) 555-0101'),
    (2, 'DOC-1002', 'Dr. Sofia Rivera', 'Mobility Therapy', '+1 (415) 555-0102');

INSERT INTO patients (user_id, patient_code, name, date_of_birth, gender, phone) VALUES
    (3, 'PT-2001', 'Mia Chen', '1991-04-18', 'Female', '+1 (415) 555-0201'),
    (4, 'PT-2002', 'Omar Hassan', '1978-09-02', 'Male', '+1 (415) 555-0202'),
    (5, 'PT-2003', 'Nina Patel', '1986-12-11', 'Female', '+1 (415) 555-0203'),
    (6, 'PT-2004', 'Leo Martin', '1969-07-25', 'Male', '+1 (415) 555-0204'),
    (7, 'PT-2005', 'Alina Garcia', '1995-03-14', 'Female', '+1 (415) 555-0205');

INSERT INTO doctor_patients (doctor_id, patient_id, status) VALUES
    (1, 1, 'ACTIVE'),
    (1, 2, 'ACTIVE'),
    (1, 3, 'ACTIVE'),
    (2, 3, 'ACTIVE'),
    (2, 4, 'ACTIVE'),
    (2, 5, 'PENDING');

INSERT INTO exercise_sessions (patient_id, exercise_type, started_at, completed_at) VALUES
    (1, 'Shoulder Flexion', '2026-07-10 09:00:00+00', '2026-07-10 09:06:00+00'),
    (1, 'Arm Reach', '2026-07-14 10:15:00+00', '2026-07-14 10:21:00+00'),
    (1, 'Grip Recovery', '2026-07-18 11:30:00+00', '2026-07-18 11:36:00+00'),
    (2, 'Shoulder Flexion', '2026-07-08 08:45:00+00', '2026-07-08 08:52:00+00'),
    (2, 'Arm Reach', '2026-07-12 09:10:00+00', '2026-07-12 09:16:00+00'),
    (3, 'Grip Recovery', '2026-07-11 13:20:00+00', '2026-07-11 13:26:00+00'),
    (3, 'Shoulder Flexion', '2026-07-16 14:00:00+00', '2026-07-16 14:07:00+00'),
    (4, 'Arm Reach', '2026-07-09 15:10:00+00', '2026-07-09 15:16:00+00'),
    (4, 'Grip Recovery', '2026-07-17 16:05:00+00', '2026-07-17 16:11:00+00'),
    (5, 'Shoulder Flexion', '2026-07-13 12:40:00+00', '2026-07-13 12:49:00+00');

INSERT INTO analysis_results (session_id, movement_status, confidence_score, emotion, analyzed_at) VALUES
    (1, 'Improving', 0.82, 'Happy', '2026-07-10 09:07:00+00'),
    (2, 'Improved', 0.87, 'Calm', '2026-07-14 10:22:00+00'),
    (3, 'Improved', 0.91, 'Happy', '2026-07-18 11:37:00+00'),
    (4, 'Not Improved', 0.73, 'Focused', '2026-07-08 08:53:00+00'),
    (5, 'Improving', 0.81, 'Calm', '2026-07-12 09:17:00+00'),
    (6, 'Improved', 0.88, 'Happy', '2026-07-11 13:27:00+00'),
    (7, 'Improved', 0.94, 'Calm', '2026-07-16 14:08:00+00'),
    (8, 'Not Improved', 0.69, 'Tense', '2026-07-09 15:17:00+00'),
    (9, 'Improving', 0.79, 'Focused', '2026-07-17 16:12:00+00'),
    (10, 'Improved', 0.9, 'Happy', '2026-07-13 12:50:00+00');
