import requests
import os
import json

base_url = "http://127.0.0.1:8000"
test_email = "patient@test.com"
test_password = "password123"

def run_test():
    print("1. Login...")
    res = requests.post(f"{base_url}/auth/login", json={"email": test_email, "password": test_password})
    if res.status_code != 200:
        # maybe we need to register first
        res = requests.post(f"{base_url}/auth/register", json={
            "email": test_email, "password": test_password, "name": "Test Patient", "role": "PATIENT"
        })
        if res.status_code != 200:
            print("Failed to register or login:", res.text)
            return
    
    token = res.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    print("2. Create session...")
    res = requests.post(f"{base_url}/patients/me/sessions", json={
        "exercise_type": "Test Exercise",
        "started_at": "2026-08-18T12:00:00Z",
        "completed_at": "2026-08-18T12:05:00Z"
    }, headers=headers)
    
    if res.status_code != 200:
        print("Failed to create session:", res.text)
        return
        
    session_id = res.json()["id"]
    print("Session ID:", session_id)
    
    print("4. Call /analyze...")
    with open("dummy.mp4", "rb") as f:
        files = {"file": ("dummy.mp4", f, "video/mp4")}
        data = {"session_id": str(session_id)}
        res = requests.post(f"{base_url}/analyze", files=files, data=data, headers=headers)
        
    print("Analyze response status:", res.status_code)
    try:
        print("Analyze response data:", json.dumps(res.json(), indent=2))
    except Exception:
        print("Analyze response data:", res.text)
    
    print("5. Verify database persistence...")
    res = requests.get(f"{base_url}/patients/me/progress", headers=headers)
    print("Progress data:", json.dumps(res.json(), indent=2))

if __name__ == "__main__":
    run_test()
