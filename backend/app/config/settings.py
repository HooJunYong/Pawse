import os
from dotenv import load_dotenv  # type: ignore
from pydantic_settings import BaseSettings
from functools import lru_cache

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
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "blbe thrt syui fvxg")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "Pawse Team")

# Jamendo API Configuration
JAMENDO_CLIENT_ID = os.getenv("JAMENDO_CLIENT_ID", "bfc770e7")
JAMENDO_DEFAULT_LANGUAGE = os.getenv("JAMENDO_DEFAULT_LANGUAGE", "en")
JAMENDO_DEFAULT_ORDER = os.getenv("JAMENDO_DEFAULT_ORDER", "popularity_total")

class Settings(BaseSettings):
    """Application settings and configuration"""
    
    # Backend Configuration
    backend_host: str = "0.0.0.0"
    backend_port: int = 8000
    
    # App settings
    app_name: str = "AI Mental Health Companion API"
    app_debug: bool = False
    
    # MongoDB settings
    mongodb_uri: str = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
    database_name: str = os.getenv("DATABASE_NAME", "pawse_db")
    
    # Gemini API settings
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    gemini_model: str = "gemini-2.5-flash"
    
    # CORS settings
    allowed_origins: list = ["*"]
    
    # Rate limiting
    rate_limit_per_minute: int = 60
    
    # Session settings
    session_id_prefix: str = "SESS"
    message_id_prefix: str = "MSG"
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields from .env


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()