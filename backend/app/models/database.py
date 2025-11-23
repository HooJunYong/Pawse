from pymongo import MongoClient  # type: ignore
from ..config.settings import MONGODB_URI, DATABASE_NAME

client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

# Ensure indexes (idempotent)
db.users.create_index("email", unique=True)
db.users.create_index("user_id", unique=True)
db.user_profile.create_index("user_id")
db.user_login_events.create_index("user_id")
db.therapist_profile.create_index("user_id", unique=True)
db.therapist_profile.create_index("license_number", unique=True)
db.therapist_profile.create_index("verification_status")
