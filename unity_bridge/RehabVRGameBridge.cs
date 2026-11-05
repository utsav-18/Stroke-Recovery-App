using System;
using System.Collections;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Networking;
using UnityEngine.SceneManagement;

/// <summary>
/// Attach this script to an empty GameObject (e.g. "RehabNetworkManager") in your Unity VR project.
/// It continuously listens for the doctor's prescribed level and the patient's "Start Game" trigger from the mobile app.
/// </summary>
public class RehabVRGameBridge : MonoBehaviour
{
    [Header("Backend Connection")]
    [Tooltip("IP address or URL of your RehabTrack FastAPI backend (e.g. http://192.168.1.50:8000 or http://127.0.0.1:8000)")]
    public string backendBaseUrl = "http://127.0.0.1:8000";

    [Tooltip("The unique patient code assigned to this patient (e.g. PT-2001)")]
    public string patientCode = "PT-2001";

    [Tooltip("How frequently (in seconds) Unity polls the server for the start trigger")]
    [Range(0.5f, 5.0f)]
    public float pollInterval = 1.0f;

    [Header("Scene Management")]
    [Tooltip("Whether Unity should automatically load scenes named 'Level_1', 'Level_2', etc.")]
    public bool autoLoadLevelScene = true;

    [Tooltip("Scene name prefix before level number (default: 'Level_')")]
    public string scenePrefix = "Level_";

    [Header("Events")]
    public UnityEvent<int> onLevelStartTriggered;

    private bool isListening = true;
    private Coroutine pollCoroutine;

    void Start()
    {
        // Keep this network bridge persistent across scene transitions if needed
        DontDestroyOnLoad(gameObject);
        StartListening();
    }

    public void StartListening()
    {
        isListening = true;
        if (pollCoroutine != null) StopCoroutine(pollCoroutine);
        pollCoroutine = StartCoroutine(PollTriggerRoutine());
        Debug.Log($"[RehabVRGameBridge] Listening for game triggers for patient {patientCode} at {backendBaseUrl}");
    }

    public void StopListening()
    {
        isListening = false;
        if (pollCoroutine != null)
        {
            StopCoroutine(pollCoroutine);
            pollCoroutine = null;
        }
    }

    private IEnumerator PollTriggerRoutine()
    {
        while (isListening)
        {
            string url = $"{backendBaseUrl.TrimEnd('/')}/patients/game-trigger/{patientCode.Trim()}";

            using (UnityWebRequest req = UnityWebRequest.Get(url))
            {
                req.timeout = 4;
                yield return req.SendWebRequest();

                if (req.result == UnityWebRequest.Result.Success)
                {
                    string json = req.downloadHandler.text;
                    TriggerResponse data = JsonUtility.FromJson<TriggerResponse>(json);

                    if (data != null && data.game_status == "START_TRIGGERED")
                    {
                        Debug.Log($"[RehabVRGameBridge] START TRIGGER RECEIVED! Level: {data.assigned_level} for {data.patient_name}");

                        // 1. Acknowledge server so status changes to 'PLAYING'
                        yield return StartCoroutine(AcknowledgeStart(patientCode));

                        // 2. Fire custom Unity event
                        onLevelStartTriggered?.Invoke(data.assigned_level);

                        // 3. Load level scene if configured
                        if (autoLoadLevelScene)
                        {
                            string sceneToLoad = $"{scenePrefix}{data.assigned_level}";
                            Debug.Log($"[RehabVRGameBridge] Loading scene: {sceneToLoad}");
                            SceneManager.LoadScene(sceneToLoad);
                        }
                    }
                }
                else
                {
                    // Network warning (silently retry on next tick)
                    // Debug.LogWarning($"[RehabVRGameBridge] Polling failed: {req.error}");
                }
            }

            yield return new WaitForSeconds(pollInterval);
        }
    }

    private IEnumerator AcknowledgeStart(string code)
    {
        string ackUrl = $"{backendBaseUrl.TrimEnd('/')}/patients/game-trigger/{code.Trim()}/ack";
        using (UnityWebRequest req = UnityWebRequest.PostWwwForm(ackUrl, ""))
        {
            req.timeout = 4;
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                Debug.Log("[RehabVRGameBridge] Acknowledged start to backend.");
            }
        }
    }

    [Serializable]
    private class TriggerResponse
    {
        public int patient_id;
        public string patient_code;
        public string patient_name;
        public int assigned_level;
        public string game_status;
    }
}

