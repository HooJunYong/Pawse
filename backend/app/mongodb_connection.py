from pymongo import MongoClient
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# MongoDB configuration from .env
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
DATABASE_NAME = os.getenv("DATABASE_NAME", "pawse_db")

# Create MongoDB client and database connection
client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

def get_database():
    """Returns the MongoDB database instance"""
    return db

def get_client():
    """Returns the MongoDB client instance"""
    return client