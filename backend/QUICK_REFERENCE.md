# 🚀 Quick Reference Card - AI Chat Backend

## 📦 Installation (First Time)

```powershell
# Navigate to backend
cd c:\VSCodeProject\Pawse\backend

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Update .env with your Gemini API key
# GEMINI_API_KEY=your_actual_api_key_here

# Seed database
python seed_data.py

# Start server
python app/main.py
```

## 🎯 Daily Usage

```powershell
# Activate environment
.\venv\Scripts\Activate.ps1

# Start server
python app/main.py

# OR use quick start
.\start.ps1
```

## 🔗 Important URLs

- **API Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health
- **Root**: http://localhost:8000/

## 📝 Common API Flows

### Start a Conversation
```powershell
# 1. Start session
$session = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/start" `
  -Method Post -ContentType "application/json" `
  -Body (@{user_id="USER001"; companion_id="COMP001"} | ConvertTo-Json)

# 2. Send message
$msg = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/message/send" `
  -Method Post -ContentType "application/json" `
  -Body (@{session_id=$session.session_id; message_text="Hello!"} | ConvertTo-Json)

# 3. Get messages
$msgs = Invoke-RestMethod -Uri "http://localhost:8000/api/chat/message/$($session.session_id)"

# 4. End session
Invoke-RestMethod -Uri "http://localhost:8000/api/chat/session/$($session.session_id)/end" -Method Put
```

## 🎭 Available Companions (After Seeding)

| ID | Name | Personality | Best For |
|----|------|-------------|----------|
| COMP001 | Luna | Empathetic | Emotional support |
| COMP002 | Atlas | Encouraging | Building confidence |
| COMP003 | River | Calming | Anxiety relief |
| COMP004 | Sage | Insightful | Self-reflection |
| COMP005 | Sunny | Playful | Lifting spirits |

## 😊 Emotion Keywords

| Emotion | Keywords |
|---------|----------|
| happy | happy, joy, excited, great, wonderful |
| sad | sad, unhappy, depressed, down |
| anxious | anxious, worried, nervous, stressed |
| angry | angry, mad, furious, irritated |
| excited | excited, thrilled, pumped |
| tired | tired, exhausted, fatigued |
| lonely | lonely, alone, isolated |
| grateful | grateful, thankful, appreciative |

## 📊 Collection Names

- `ai_companions` - AI companion definitions
- `personalities` - Personality types
- `chat_sessions` - User sessions
- `chat_messages` - Conversation messages

## 🔧 Configuration Files

- `.env` - Environment variables (API keys, MongoDB URI)
- `app/config.py` - Application settings
- `requirements.txt` - Python dependencies

## 📚 Documentation Files

- `README.md` - Complete documentation
- `API_TESTING.md` - API examples
- `ARCHITECTURE.md` - System architecture
- `IMPLEMENTATION_SUMMARY.md` - What was built

## 🐛 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Import errors | `pip install -r requirements.txt` |
| MongoDB error | Check MongoDB is running |
| Gemini API error | Verify API key in `.env` |
| No greeting | Run `seed_data.py` |
| Port in use | Change port in `.env` |

## 💡 Tips

- Use Swagger UI (`/docs`) for interactive testing
- Check logs for detailed error messages
- Keep conversation history reasonable (max 10 messages passed to AI)
- End sessions when done to keep database clean
- Use pagination for user sessions list

## 🔐 Security Checklist

- [ ] Gemini API key in `.env` (never commit)
- [ ] CORS configured properly for production
- [ ] Rate limiting enabled
- [ ] MongoDB authentication in production
- [ ] HTTPS in production

## 📞 Quick Commands

```powershell
# Check Python version
python --version

# Check if MongoDB is running
mongod --version

# View database
mongosh
use pawse_db
show collections

# Check installed packages
pip list

# Update requirements
pip freeze > requirements.txt

# Run in production mode
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 🎓 Learning Resources

- FastAPI: https://fastapi.tiangolo.com/
- MongoDB: https://www.mongodb.com/docs/
- Gemini API: https://ai.google.dev/docs
- Pydantic: https://docs.pydantic.dev/

---

**Need Help?**
1. Check README.md
2. Visit /docs endpoint
3. Review logs in console
4. Check API_TESTING.md for examples
