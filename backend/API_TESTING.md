# API Testing Examples

This file contains example API calls you can use to test the AI Chat Module backend.

## Setup

Make sure:
1. MongoDB is running
2. Backend server is running (`python app/main.py`)
3. Database is seeded with sample data (`python seed_data.py`)

## Base URL
```
http://localhost:8000
```

---

## 1. Health Check

### Get API Status
```bash
curl http://localhost:8000/
```

### Health Check
```bash
curl http://localhost:8000/health
```

---

## 2. Companions & Personalities

### Get All Companions
```bash
curl http://localhost:8000/api/companions
```

### Get Specific Companion
```bash
curl http://localhost:8000/api/companions/COMP001
```

### Get All Personalities
```bash
curl http://localhost:8000/api/personalities
```

### Get Companion's Personality
```bash
curl http://localhost:8000/api/companions/COMP001/personality
```

---

## 3. Chat Sessions

### Start New Session
```bash
curl -X POST http://localhost:8000/api/chat/session/start \
  -H "Content-Type: application/json" \
  -d "{\"user_id\": \"USER001\", \"companion_id\": \"COMP001\"}"
```

**PowerShell:**
```powershell
$body = @{
    user_id = "USER001"
    companion_id = "COMP001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/start" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

### Get Session by ID
```bash
curl http://localhost:8000/api/chat/session/SESS001
```

### Get User's Sessions
```bash
curl http://localhost:8000/api/chat/session/user/USER001
```

### Resume Session
```bash
curl -X POST http://localhost:8000/api/chat/session/SESS001/resume
```

### End Session
```bash
curl -X PUT http://localhost:8000/api/chat/session/SESS001/end
```

---

## 4. Messaging

### Send a Message
```bash
curl -X POST http://localhost:8000/api/chat/message/send \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"SESS001\", \"message_text\": \"I'm feeling anxious today\"}"
```

**PowerShell:**
```powershell
$body = @{
    session_id = "SESS001"
    message_text = "I'm feeling anxious today"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/chat/message/send" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

### Get All Messages for Session
```bash
curl http://localhost:8000/api/chat/message/SESS001
```

### Get Message History (Limited)
```bash
curl http://localhost:8000/api/chat/message/history/SESS001?limit=10
```

---

## 5. Complete Conversation Flow

### Step 1: Start Session
```powershell
# PowerShell
$session = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/start" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{user_id="USER001"; companion_id="COMP001"} | ConvertTo-Json)

$sessionId = $session.session_id
Write-Host "Session started: $sessionId"
```

### Step 2: Send Multiple Messages
```powershell
# Message 1
$msg1 = @{
    session_id = $sessionId
    message_text = "Hi, I'm feeling really stressed about work"
} | ConvertTo-Json

$response1 = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/message/send" `
  -Method Post `
  -ContentType "application/json" `
  -Body $msg1

Write-Host "AI: $($response1.ai_response.message_text)"

# Message 2
$msg2 = @{
    session_id = $sessionId
    message_text = "I have a big presentation tomorrow and I'm anxious"
} | ConvertTo-Json

$response2 = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/message/send" `
  -Method Post `
  -ContentType "application/json" `
  -Body $msg2

Write-Host "AI: $($response2.ai_response.message_text)"
```

### Step 3: Get Full Conversation
```powershell
$messages = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/message/$sessionId"
$messages.messages | ForEach-Object {
    Write-Host "$($_.role): $($_.message_text)"
}
```

### Step 4: End Session
```powershell
Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/$sessionId/end" `
  -Method Put
Write-Host "Session ended"
```

---

## 6. Testing Different Emotions

### Happy
```bash
curl -X POST http://localhost:8000/api/chat/message/send \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"SESS001\", \"message_text\": \"I'm so happy and excited today!\"}"
```

### Sad
```bash
curl -X POST http://localhost:8000/api/chat/message/send \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"SESS001\", \"message_text\": \"I feel really sad and down\"}"
```

### Anxious
```bash
curl -X POST http://localhost:8000/api/chat/message/send \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"SESS001\", \"message_text\": \"I'm worried and anxious about everything\"}"
```

### Angry
```bash
curl -X POST http://localhost:8000/api/chat/message/send \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"SESS001\", \"message_text\": \"I'm so angry and frustrated right now\"}"
```

---

## 7. Testing Different Companions

### Luna (Empathetic)
```powershell
$session = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/start" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{user_id="USER001"; companion_id="COMP001"} | ConvertTo-Json)
```

### Atlas (Encouraging)
```powershell
$session = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/start" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{user_id="USER001"; companion_id="COMP002"} | ConvertTo-Json)
```

### River (Calming)
```powershell
$session = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/start" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{user_id="USER001"; companion_id="COMP003"} | ConvertTo-Json)
```

---

## 8. Pagination Testing

### Get User Sessions with Pagination
```bash
# First page (first 10 sessions)
curl "http://localhost:8000/api/chat/session/user/USER001?limit=10&skip=0"

# Second page (next 10 sessions)
curl "http://localhost:8000/api/chat/session/user/USER001?limit=10&skip=10"
```

---

## 9. Error Testing

### Invalid Session ID
```bash
curl http://localhost:8000/api/chat/session/INVALID_SESSION
# Should return 404
```

### Invalid Companion ID
```bash
curl -X POST http://localhost:8000/api/chat/session/start \
  -H "Content-Type: application/json" \
  -d "{\"user_id\": \"USER001\", \"companion_id\": \"INVALID\"}"
# Should return 404
```

### Send Message to Ended Session
```bash
# First end a session
curl -X PUT http://localhost:8000/api/chat/session/SESS001/end

# Then try to send a message
curl -X POST http://localhost:8000/api/chat/message/send \
  -H "Content-Type: application/json" \
  -d "{\"session_id\": \"SESS001\", \"message_text\": \"Hello\"}"
# Should return 400
```

---

## Using Python Requests

```python
import requests

BASE_URL = "http://localhost:8000"

# Start session
response = requests.post(
    f"{BASE_URL}/api/chat/session/start",
    json={"user_id": "USER001", "companion_id": "COMP001"}
)
session_id = response.json()["session_id"]
print(f"Session started: {session_id}")

# Send message
response = requests.post(
    f"{BASE_URL}/api/chat/message/send",
    json={
        "session_id": session_id,
        "message_text": "I'm feeling anxious today"
    }
)
result = response.json()
print(f"Detected emotion: {result['detected_emotion']}")
print(f"AI response: {result['ai_response']['message_text']}")

# Get messages
response = requests.get(f"{BASE_URL}/api/chat/message/{session_id}")
messages = response.json()
for msg in messages["messages"]:
    print(f"{msg['role']}: {msg['message_text']}")
```

---

## Tips

1. **Use Swagger UI**: Visit `http://localhost:8000/docs` for interactive API testing
2. **Check Logs**: Monitor the server console for detailed logs
3. **MongoDB**: Use MongoDB Compass to view database contents
4. **Rate Limiting**: API is rate-limited to 60 requests/minute by default
5. **Session Management**: Remember to end sessions when done to keep data clean

---

## Troubleshooting

- **Connection Refused**: Ensure the server is running
- **404 Errors**: Check that you're using correct IDs (run seed_data.py if needed)
- **500 Errors**: Check server logs for detailed error messages
- **Empty Responses**: Ensure MongoDB is running and contains data
