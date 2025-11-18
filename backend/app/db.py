import os
from dotenv import load_dotenv  # type: ignore
from pymongo import MongoClient  # type: ignore

load_dotenv()

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
DATABASE_NAME = os.getenv("DATABASE_NAME", "pawse_db")

client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

# Ensure indexes (idempotent)
db.users.create_index("email", unique=True)
db.users.create_index("user_id", unique=True)
db.user_profile.create_index("user_id")
