from pymongo import MongoClient, ASCENDING  # type: ignore
from ..config.settings import MONGODB_URI, DATABASE_NAME

client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

# Collection references
therapists_collection = db.therapist_profile
therapy_sessions_collection = db.therapy_sessions
chat_conversations_collection = db.chat_conversations
chat_messages_collection = db.chat_messages
breathing_exercises_collection = db.breathing_exercises
user_breathing_sessions_collection = db.user_breathing_sessions

# Ensure indexes (idempotent)
db.users.create_index("email", unique=True)
db.users.create_index("user_id", unique=True)
db.user_profile.create_index("user_id")
db.user_login_events.create_index("user_id")
db.therapist_profile.create_index("user_id", unique=True)
db.therapist_profile.create_index("license_number", unique=True)
db.therapist_profile.create_index("verification_status")
db.therapy_sessions.create_index("session_id", unique=True)
db.therapy_sessions.create_index("user_id")
db.therapy_sessions.create_index("therapist_user_id")
db.therapy_sessions.create_index("scheduled_at")
db.therapy_sessions.create_index("session_id", unique=True)
db.therapy_sessions.create_index("user_id")
db.therapy_sessions.create_index("therapist_user_id")
db.therapy_sessions.create_index([
	("user_id", ASCENDING),
	("session_status", ASCENDING),
	("scheduled_at", ASCENDING),
])
db.therapy_sessions.create_index([
	("therapist_user_id", ASCENDING),
	("session_status", ASCENDING),
	("scheduled_at", ASCENDING),
])

# Chat collections indexes
db.chat_conversations.create_index("conversation_id", unique=True)
db.chat_conversations.create_index([("client_user_id", ASCENDING), ("therapist_user_id", ASCENDING)], unique=True)
db.chat_conversations.create_index("updated_at")
db.chat_conversations.create_index("client_user_id")
db.chat_conversations.create_index("therapist_user_id")

db.chat_messages.create_index("message_id", unique=True)
db.chat_messages.create_index("conversation_id")
db.chat_messages.create_index("created_at")
db.chat_messages.create_index([("conversation_id", ASCENDING), ("created_at", ASCENDING)])

# OTP codes indexes
db.otp_codes.create_index("email")
db.otp_codes.create_index("expires_at")
db.otp_codes.create_index([("email", ASCENDING), ("used", ASCENDING)])

# Breathing collections indexes
db.breathing_exercises.create_index("exercise_id", unique=True)
db.breathing_exercises.create_index("slug", unique=True, sparse=True)
db.breathing_exercises.create_index("is_active")

db.user_breathing_sessions.create_index("session_id", unique=True)
db.user_breathing_sessions.create_index("user_id")
db.user_breathing_sessions.create_index("exercise_id")
db.user_breathing_sessions.create_index("completed_at")
