# RehabTrack Unity VR Game Bridge

This folder contains the integration script for your Unity VR project running on your laptop.

## How It Works

1. **Doctor App**: The doctor prescribes a level (e.g. Level 1 to 5).
2. **Patient App**: The patient taps **"Start VR Session & Record"**.
   - The mobile app signals the FastAPI backend.
   - The phone camera simultaneously turns on to record the patient's upper-body movements.
3. **Unity Game**:
   - `RehabVRGameBridge.cs` receives the signal over HTTP/Wi-Fi.
   - It automatically starts the VR headset experience at the prescribed level (e.g., loads `Level_2`).
4. **Completion & AI Analysis**:
   - Patient taps **"Finish & Send to Doctor"** in the mobile app.
   - The video is processed by the backend AI models (shoulder/arm angles + facial emotion).
   - The doctor's dashboard updates immediately with the progress chart and metrics.

---

## Setup in Unity (2 Minutes)

1. Copy [`RehabVRGameBridge.cs`](file:///c:/Users/sdshy/OneDrive/Dokumen/projects/stroke-recovery-app/Stroke-Recovery-App/unity_bridge/RehabVRGameBridge.cs) into your Unity project's `Assets/Scripts/` folder.
2. In your opening scene (or main menu scene), create an empty GameObject and name it `RehabNetworkManager`.
3. Drag and drop `RehabVRGameBridge.cs` onto `RehabNetworkManager`.
4. In the Inspector:
   - **Backend Base URL**: Set this to your backend server's IP address.
     - If Unity is running on the **same laptop** as the backend: `http://127.0.0.1:8000`
     - If Unity is on a **separate laptop on the same Wi-Fi**: `http://<YOUR_LAPTOP_IP>:8000` (e.g. `http://192.168.1.5:8000`)
   - **Patient Code**: Set this to the patient code you are testing (e.g., `PT-2001`).
   - **Auto Load Level Scene**: Checked by default. It will load `Level_1`, `Level_2`, etc.
5. Hit **Play** in Unity. When the patient taps "Start VR Session" in the app, Unity will immediately launch the prescribed level in the VR headset!

