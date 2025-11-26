from pymongo import MongoClient
from ..config.settings import MONGODB_URI, DATABASE_NAME
import logging

logger = logging.getLogger(__name__)

# MongoDB client and database
client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

def get_database():
    """Get database instance"""
    return db

def initialize_indexes():
    """Initialize all database indexes (idempotent)"""
    try:
        # Users collection
        db.users.create_index("email", unique=True)
        db.users.create_index("user_id", unique=True)
        
        # User profile
        db.user_profile.create_index("user_id")
        db.user_login_events.create_index("user_id")
        
        # Therapist profile
        db.therapist_profile.create_index("user_id", unique=True)
        db.therapist_profile.create_index("license_number", unique=True)
        db.therapist_profile.create_index("verification_status")
        
        # Chat sessions
        db.chat_sessions.create_index("session_id", unique=True)
        db.chat_sessions.create_index("user_id")
        db.chat_sessions.create_index([("user_id", 1), ("start_time", -1)])
        
        # Chat messages
        db.chat_messages.create_index("message_id", unique=True)
        db.chat_messages.create_index("session_id")
        
        # AI companions
        db.ai_companions.create_index("companion_id", unique=True)
        db.ai_companions.create_index("is_active")
        
        # Personalities
        db.personalities.create_index("personality_id", unique=True)
        db.personalities.create_index("is_active")
        
        # Mood tracking
        db.mood_tracking.create_index("mood_id", unique=True)
        db.mood_tracking.create_index("user_id")
        db.mood_tracking.create_index([("user_id", 1), ("date", -1)])
        
        logger.info("All database indexes created successfully")
        
    except Exception as e:
        logger.error(f"Error creating indexes: {str(e)}")
        raise