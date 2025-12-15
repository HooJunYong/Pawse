from pymongo import MongoClient, ASCENDING  # type: ignore
from ..config.settings import MONGODB_URI, DATABASE_NAME
import logging

logger = logging.getLogger(__name__)

client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

# Collection references
therapists_collection = db.therapist_profile
therapy_sessions_collection = db.therapy_sessions
chat_conversations_collection = db.chat_conversations
therapist_chat_messages_collection = db.therapist_chat_messages
breathing_exercises_collection = db.breathing_exercises
user_breathing_sessions_collection = db.user_breathing_sessions
music_tracks_collection = db.music_tracks
user_playlists_collection = db.user_playlists
music_listening_sessions_collection = db.music_listening_sessions
mood_collection = db.mood_tracking
drift_bottles_collection = db.drift_bottles
bottle_pickups_collection = db.bottle_pickups
rewards_collection = db.rewards
user_rewards_collection = db.user_rewards
activities_collection = db.activities
user_activities_collection = db.user_activities

# Ensure indexes (idempotent)
# Users collection
db.users.create_index("email", unique=True)
db.users.create_index("user_id", unique=True)

# User profile collection
db.user_profile.create_index("user_id")

# User login events
db.user_login_events.create_index("user_id")

# Therapist profile collection
db.therapist_profile.create_index("user_id", unique=True)
db.therapist_profile.create_index("license_number", unique=True)
db.therapist_profile.create_index("verification_status")

# Therapy sessions collection
db.therapy_sessions.create_index("session_id", unique=True)
db.therapy_sessions.create_index("user_id")
db.therapy_sessions.create_index("therapist_user_id")
db.therapy_sessions.create_index("scheduled_at")
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

# Therapist-Client Chat collections
db.chat_conversations.create_index("conversation_id", unique=True)
db.chat_conversations.create_index([("client_user_id", ASCENDING), ("therapist_user_id", ASCENDING)], unique=True)
db.chat_conversations.create_index("updated_at")
db.chat_conversations.create_index("client_user_id")
db.chat_conversations.create_index("therapist_user_id")

db.therapist_chat_messages.create_index("message_id", unique=True)
db.therapist_chat_messages.create_index("conversation_id")
db.therapist_chat_messages.create_index("created_at")
db.therapist_chat_messages.create_index([("conversation_id", ASCENDING), ("created_at", ASCENDING)])

# OTP codes collection
db.otp_codes.create_index("email")
db.otp_codes.create_index("expires_at")
db.otp_codes.create_index([("email", ASCENDING), ("used", ASCENDING)])

# Breathing collections
db.breathing_exercises.create_index("exercise_id", unique=True)
db.breathing_exercises.create_index("slug", unique=True, sparse=True)
db.breathing_exercises.create_index("is_active")

db.user_breathing_sessions.create_index("session_id", unique=True)
db.user_breathing_sessions.create_index("user_id")
db.user_breathing_sessions.create_index("exercise_id")
db.user_breathing_sessions.create_index("completed_at")

# Music collections
db.music_tracks.create_index("music_id", unique=True)
db.music_tracks.create_index("title")
db.music_tracks.create_index("artist")
db.music_tracks.create_index("mood_category")
db.music_tracks.create_index("added_at")

db.user_playlists.create_index("user_playlist_id", unique=True)
db.user_playlists.create_index("user_id")
db.user_playlists.create_index("playlist_name")
db.user_playlists.create_index("is_public")

db.music_listening_sessions.create_index("music_session_id", unique=True)
db.music_listening_sessions.create_index("user_id")
db.music_listening_sessions.create_index("playlist_id")
db.music_listening_sessions.create_index("user_playlist_id")
db.music_listening_sessions.create_index("started_at")
               
# AI Companion Chat collections (User-AI conversations)
db.chat_sessions.create_index("session_id", unique=True)
db.chat_sessions.create_index("user_id")
db.chat_sessions.create_index([("user_id", 1), ("start_time", -1)])
        
db.chat_messages.create_index("message_id", unique=True)
db.chat_messages.create_index([("session_id", ASCENDING), ("timestamp", ASCENDING)])
        
# AI companions collection
db.ai_companions.create_index("companion_id", unique=True)
db.ai_companions.create_index("is_active")

# Personalities collection
db.personalities.create_index("personality_id", unique=True)
db.personalities.create_index("is_active")

# Mood tracking collection
db.mood_tracking.create_index("mood_id", unique=True)
db.mood_tracking.create_index("user_id")
db.mood_tracking.create_index([("user_id", 1), ("date", -1)])

# Drift Bottles collection
db.drift_bottles.create_index("bottle_id", unique=True)
db.drift_bottles.create_index("user_id")
db.drift_bottles.create_index("created_at")
db.drift_bottles.create_index("status") 

db.bottle_pickups.create_index("pickup_id", unique=True)
db.bottle_pickups.create_index("user_id")
db.bottle_pickups.create_index("bottle_id")

# Rewards and Activities collections
db.rewards.create_index("reward_id", unique=True)
db.rewards.create_index("category")

db.user_rewards.create_index("user_id")
db.user_rewards.create_index([("user_id", ASCENDING), ("reward_id", ASCENDING)])

db.activities.create_index("activity_id", unique=True)
db.activities.create_index("category")

db.user_activities.create_index("user_id")
db.user_activities.create_index("completed_at")

# Scheduled notifications collection
db.scheduled_notifications.create_index("notification_id", unique=True)
db.scheduled_notifications.create_index("user_id")
db.scheduled_notifications.create_index("scheduled_time")
db.scheduled_notifications.create_index("is_sent")
db.scheduled_notifications.create_index([("scheduled_time", ASCENDING), ("is_sent", ASCENDING)])


def get_database():
    """Get database instance"""
    return db


def initialize_indexes():
    """Initialize all indexes - already done above during module import"""
    logger.info("Database indexes initialized")