import os
from dotenv import load_dotenv  # type: ignore

load_dotenv()

# MongoDB Configuration
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
DATABASE_NAME = os.getenv("DATABASE_NAME", "pawse_db")

# Server Configuration
BACKEND_HOST = os.getenv("BACKEND_HOST", "0.0.0.0")
BACKEND_PORT = int(os.getenv("BACKEND_PORT", 8000))

# CORS Configuration
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

# Password Security
PASSWORD_MIN_LENGTH = 6
HASH_NAME = "sha256"
PBKDF2_ITERATIONS = 310000
SALT_BYTES = 16

# User Types
VALID_USER_TYPES = {"users", "admin"}

# Email Configuration (Gmail SMTP)
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", 587))
SMTP_USER = os.getenv("SMTP_USER", "teampawse@gmail.com")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "Pawse Team")

# Jamendo API Configuration
JAMENDO_CLIENT_ID = os.getenv("JAMENDO_CLIENT_ID", "bfc770e7")
JAMENDO_DEFAULT_LANGUAGE = os.getenv("JAMENDO_DEFAULT_LANGUAGE", "en")
JAMENDO_DEFAULT_ORDER = os.getenv("JAMENDO_DEFAULT_ORDER", "popularity_total")
