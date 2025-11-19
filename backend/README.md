# AI Chat Module Backend - FastAPI

A production-ready FastAPI backend for an AI Mental Health Companion chat system using MongoDB and Google Gemini API.

## 🚀 Features

- **Session Management**: Create, resume, and end chat sessions
- **AI-Powered Responses**: Gemini API integration for contextual responses
- **Emotion Detection**: Keyword-based emotion detection from user messages
- **Personality System**: Multiple AI personalities with unique communication styles
- **Auto-Generated IDs**: Sequential session (SESS001) and message (MSG001) IDs
- **Conversation History**: Complete message threading per session
- **Rate Limiting**: Built-in API rate limiting protection
- **MongoDB Integration**: Full async database operations
- **CORS Support**: Configurable cross-origin resource sharing
- **Comprehensive Logging**: Detailed logging for debugging

## 📋 Requirements

- Python 3.10+
- MongoDB (local or cloud)
- Google Gemini API key

## 🛠️ Installation

1. **Navigate to backend directory**:
```bash
cd c:\VSCodeProject\Pawse\backend
```

2. **Create and activate virtual environment** (if not exists):
```bash
python -m venv venv
.\venv\Scripts\Activate.ps1
```

3. **Install dependencies**:
```bash
pip install -r requirements.txt
```

4. **Configure environment variables**:
Edit `.env` file with your configurations:
```env
# Backend Configuration
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017/
DATABASE_NAME=pawse_db

# CORS Configuration
ALLOWED_ORIGINS=*

# Gemini API Configuration
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

## 📊 Database Setup

### Collections Structure

1. **ai_companions** - AI companion definitions
2. **personalities** - Personality types and prompts
3. **chat_sessions** - User chat sessions
4. **chat_messages** - Conversation messages

### Seed Sample Data

Run the seed script to populate sample data:
```bash
python seed_data.py
```

Or manually insert sample data into MongoDB collections.

## 🚀 Running the Server

### Development Mode (with auto-reload):
```bash
python app/main.py
```

Or using uvicorn directly:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Production Mode:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 📚 API Documentation

Once the server is running, access:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🔗 API Endpoints

### Session Management
- `POST /api/chat/session/start` - Start new chat session with greeting
- `PUT /api/chat/session/{session_id}/end` - End chat session
- `GET /api/chat/session/{session_id}` - Get session details
- `GET /api/chat/session/user/{user_id}` - Get user's sessions (paginated)
- `POST /api/chat/session/{session_id}/resume` - Resume existing session

### Messaging
- `POST /api/chat/message/send` - Send message and get AI response
- `GET /api/chat/message/{session_id}` - Get all messages for session
- `GET /api/chat/message/history/{session_id}` - Get message history (limited)

### Companions & Personalities
- `GET /api/companions` - Get all active companions
- `GET /api/companions/{companion_id}` - Get companion details
- `GET /api/companions/{companion_id}/personality` - Get companion's personality
- `GET /api/personalities` - Get all active personalities
- `GET /api/personalities/{personality_id}` - Get personality details

### Health & Status
- `GET /` - Root endpoint with API info
- `GET /health` - Health check with database status

## 📝 Usage Examples

### 1. Start a New Chat Session

```bash
POST /api/chat/session/start
Content-Type: application/json

{
    "user_id": "USER001",
    "companion_id": "COMP001"
}
```

Response:
```json
{
    "session_id": "SESS001",
    "user_id": "USER001",
    "companion_id": "COMP001",
    "start_time": "2024-01-01T10:00:00",
    "end_time": null,
    "is_active": true
}
```

### 2. Send a Message

```bash
POST /api/chat/message/send
Content-Type: application/json

{
    "session_id": "SESS001",
    "message_text": "I'm feeling anxious today"
}
```

Response:
```json
{
    "success": true,
    "user_message": {
        "role": "user",
        "message_text": "I'm feeling anxious today",
        "timestamp": "2024-01-01T10:05:00",
        "emotion": "anxious"
    },
    "ai_response": {
        "role": "AI",
        "message_text": "I understand you're feeling anxious. That's a completely valid feeling...",
        "timestamp": "2024-01-01T10:05:01",
        "emotion": null
    },
    "detected_emotion": "anxious"
}
```

### 3. Get Message History

```bash
GET /api/chat/message/{session_id}
```

## 🔧 Configuration

### Rate Limiting
Default: 60 requests per minute (configurable in `config.py`)

### Session & Message IDs
- Sessions: SESS001, SESS002, SESS003...
- Messages: MSG001, MSG002, MSG003...

### Emotion Detection Keywords
Configured in `ai_chat_service.py`:
- happy, sad, angry, anxious, excited, tired, lonely, confused, grateful, hopeful, neutral

## 🏗️ Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app entry point
│   ├── config.py               # Configuration settings
│   ├── mongodb_connection.py   # Database connection
│   ├── models/                 # Pydantic models
│   │   ├── __init__.py
│   │   ├── companion.py
│   │   ├── personality.py
│   │   ├── chat_session.py
│   │   └── chat_message.py
│   ├── routes/                 # API routes
│   │   ├── __init__.py
│   │   ├── session_routes.py
│   │   ├── message_routes.py
│   │   └── companion_routes.py
│   └── services/               # Business logic
│       ├── __init__.py
│       └── ai_chat_service.py
├── .env                        # Environment variables
├── requirements.txt            # Python dependencies
├── seed_data.py               # Sample data seeder
└── README.md                  # This file
```

## 🧪 Testing

Test the API using:
- Swagger UI at `/docs`
- Postman collection (import from docs)
- Python requests library
- Frontend integration

## 🔐 Security Considerations

1. **API Keys**: Keep `GEMINI_API_KEY` secret, never commit to version control
2. **CORS**: Configure `ALLOWED_ORIGINS` properly for production
3. **Rate Limiting**: Adjust limits based on your needs
4. **MongoDB**: Use authentication in production environments
5. **HTTPS**: Use HTTPS in production with proper SSL certificates

## 🐛 Troubleshooting

### MongoDB Connection Issues
- Verify MongoDB is running: `mongod --version`
- Check connection string in `.env`
- Ensure database permissions

### Gemini API Errors
- Verify API key is correct
- Check API quota/limits
- Review logs for detailed error messages

### Import Errors
- Ensure virtual environment is activated
- Run `pip install -r requirements.txt` again

## 📦 Dependencies

Key packages:
- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `pymongo` - MongoDB driver
- `google-generativeai` - Gemini API client
- `pydantic-settings` - Settings management
- `slowapi` - Rate limiting

## 🤝 Contributing

1. Follow PEP 8 style guidelines
2. Add type hints to all functions
3. Write comprehensive docstrings
4. Log important operations
5. Handle exceptions properly

## 📄 License

MIT License - See LICENSE file for details

## 👥 Support

For issues or questions:
1. Check API documentation at `/docs`
2. Review logs for error details
3. Verify environment configuration
4. Test with sample data

---

**Happy Coding! 🎉**
