from pymongo import MongoClient, ASCENDING  # type: ignore
from ..config.settings import MONGODB_URI, DATABASE_NAME

client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

# Collection references
therapists_collection = db.therapist_profile
therapy_sessions_collection = db.therapy_sessions

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

# OTP codes indexes
db.otp_codes.create_index("email")
db.otp_codes.create_index("expires_at")
db.otp_codes.create_index([("email", ASCENDING), ("used", ASCENDING)])
