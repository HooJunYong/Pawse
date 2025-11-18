from fastapi import FastAPI  # type: ignore
from .signup import router as signup_router
from .login import router as login_router
from .db import db  # Import shared db (ensures indexes are created)
from starlette.middleware.cors import CORSMiddleware  # type: ignore
import os

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

# Include auth routes
app.include_router(signup_router)
app.include_router(login_router)

@app.get("/")
def root():
    return {"message": "Backend is running!"}

@app.get("/users")
def get_users():
    users = list(db.users.find({}, {"_id": 0}))
    return {"users": users}

@app.get("/health/db")
def db_health():
    """Check MongoDB connection and collection status"""
    try:
        ping_result = db.command("ping")
        collections = db.list_collection_names()
        users_count = db.users.count_documents({})
        profiles_count = db.user_profile.count_documents({})
        return {
            "status": "connected",
            "ping": ping_result.get("ok"),
            "database": db.name,
            "collections": collections,
            "counts": {
                "users": users_count,
                "user_profile": profiles_count
            }
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    import uvicorn  # type: ignore
    host = os.getenv("BACKEND_HOST", "0.0.0.0")
    port = int(os.getenv("BACKEND_PORT", 8000))
    uvicorn.run(app, host=host, port=port)
