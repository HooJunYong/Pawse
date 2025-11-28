from fastapi import FastAPI  # type: ignore
from starlette.middleware.cors import CORSMiddleware  # type: ignore
from .models.database import db
from .routes.auth_routes import router as auth_router
from .routes.profile_routes import router as profile_router
from .routes.password_routes import router as password_router
from .routes.therapist_routes import router as therapist_router
from .routes.schedule_routes import router as schedule_router
from .routes.journal_routes import router as journal_router
from .routes.otp_routes import router as otp_router
from .config.settings import ALLOWED_ORIGINS, BACKEND_HOST, BACKEND_PORT

app = FastAPI(title="AI Mental Health Companion API")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, tags=["Authentication"])
app.include_router(profile_router, tags=["Profile"])
app.include_router(password_router, tags=["Password"])
app.include_router(therapist_router, tags=["Therapist"])
app.include_router(schedule_router, tags=["Schedule"])
app.include_router(journal_router, tags=["Journal"])
app.include_router(otp_router, tags=["OTP"])

@app.get("/")
def root():
    return {"message": "Backend is running!"}

@app.get("/users")
def get_users():
    """Get all users (for development/testing)"""
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
    uvicorn.run(app, host=BACKEND_HOST, port=BACKEND_PORT)
