import requests
import json
import uuid

base_url = "http://127.0.0.1:8000"
patient_email = f"pat_{uuid.uuid4().hex[:6]}@test.com"
doctor_email = f"doc_{uuid.uuid4().hex[:6]}@test.com"

print("1. Register Patient")
res = requests.post(f"{base_url}/auth/register", json={
    "email": patient_email, "password": "password123", "name": "Real Patient", "role": "PATIENT"
})
assert res.status_code == 200
patient_token = res.json()["token"]
patient_headers = {"Authorization": f"Bearer {patient_token}"}

print("2. Patient creates session")
res = requests.post(f"{base_url}/patients/me/sessions", json={
    "exercise_type": "Test", "started_at": "2026-08-18T12:00:00Z"
}, headers=patient_headers)
session_id = res.json()["id"]

print("3. Register Doctor")
res = requests.post(f"{base_url}/auth/register", json={
    "email": doctor_email, "password": "password123", "name": "Real Doctor", "role": "DOCTOR"
})
assert res.status_code == 200
doctor_token = res.json()["token"]
doctor_headers = {"Authorization": f"Bearer {doctor_token}"}

print("4. Doctor gets patient list")
res = requests.get(f"{base_url}/doctors/me/patients", headers=doctor_headers)
assert res.status_code == 200
patients = res.json()
print(f"Doctor sees {len(patients)} patients")
found = any(p["name"] == "Real Patient" for p in patients)
assert found, "New patient not found in doctor's list!"

print("5. Doctor updates profile")
res = requests.put(f"{base_url}/doctors/me", json={
    "name": "Updated Doctor",
    "specialization": "Neurology",
    "phone": "555-0000"
}, headers=doctor_headers)
assert res.status_code == 200

print("6. Doctor gets profile")
res = requests.get(f"{base_url}/doctors/me", headers=doctor_headers)
assert res.status_code == 200
doc = res.json()
assert doc["name"] == "Updated Doctor"
assert doc["specialization"] == "Neurology"

print("7. Patient gets 403 on doctor routes")
res = requests.get(f"{base_url}/doctors/me", headers=patient_headers)
assert res.status_code == 403

print("ALL TESTS PASSED SUCCESSFULLY!")
