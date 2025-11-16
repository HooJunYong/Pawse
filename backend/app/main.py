from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pymongo import MongoClient
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

app = FastAPI(title="AI Mental Health Companion API")

# CORS Configuration from .env
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# MongoDB connection from .env
mongodb_uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
database_name = os.getenv("DATABASE_NAME", "pawse_db")

client = MongoClient(mongodb_uri)
db = client[database_name]

@app.get("/")
def root():
    return {"message": "Backend is running!"}

@app.get("/users")
def get_users():
    users = list(db.users.find({}, {"_id": 0}))
    return {"users": users}

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("BACKEND_HOST", "0.0.0.0")
    port = int(os.getenv("BACKEND_PORT", 8000))
    uvicorn.run(app, host=host, port=port)
