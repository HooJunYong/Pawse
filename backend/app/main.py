from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv
import os
import logging

from app.models.database import get_database, initialize_indexes
from app.routes import session_router, message_router, companion_router
from .routes.auth_routes import router as auth_router
from .routes.profile_routes import router as profile_router
from .routes.password_routes import router as password_router
from .routes.therapist_routes import router as therapist_router
from .routes.schedule_routes import router as schedule_router
from .routes.mood_routes import router as mood_router
from .routes.personality_routes import router as personality_router
from app.config.settings import get_settings

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Get settings
settings = get_settings()

# Initialize rate limiter
limiter = Limiter(key_func=get_remote_address)

# Create FastAPI app
app = FastAPI(
    title="AI Mental Health Companion API",
    description="Backend API for AI Chat Module with Gemini integration",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add rate limiter to app state
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Configuration
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins if allowed_origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Global exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error occurred"}
    )

# Include routers
app.include_router(session_router)
app.include_router(message_router)
app.include_router(companion_router)
app.include_router(personality_router, tags=["Personalities"])
app.include_router(auth_router, tags=["Authentication"])
app.include_router(profile_router, tags=["Profile"])
app.include_router(password_router, tags=["Password"])
app.include_router(therapist_router, tags=["Therapist"])
app.include_router(schedule_router, tags=["Schedule"])
app.include_router(mood_router, tags=["Mood Tracking"])


# Get MongoDB database connection
db = get_database()

@app.on_event("startup")
async def startup_event():
    """Initialize database indexes and perform startup tasks"""
    logger.info("Starting AI Mental Health Companion API...")
    
    try:
        # Initialize all indexes
        initialize_indexes()
        logger.info("API started successfully!")
        
    except Exception as e:
        logger.error(f"Error during startup: {str(e)}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup tasks on shutdown"""
    logger.info("Shutting down AI Mental Health Companion API...")


@app.get("/", tags=["Health"])
@limiter.limit("60/minute")
async def root(request: Request):
    """Root endpoint - API health check"""
    return {
        "message": "AI Mental Health Companion API is running!",
        "version": "1.0.0",
        "status": "healthy",
        "endpoints": {
            "docs": "/docs",
            "sessions": "/api/chat/session",
            "messages": "/api/chat/message",
            "companions": "/api/companions",
            "personalities": "/api/personalities"
        }
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    try:
        # Check database connection
        db.command("ping")
        return {
            "status": "healthy",
            "database": "connected",
            "gemini_api_configured": bool(settings.gemini_api_key)
        }
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": str(e)
            }
        )


@app.get("/users", tags=["Legacy"])
def get_users():
    """Legacy endpoint - Get all users"""
    users = list(db.users.find({}, {"_id": 0}))
    return {"users": users}

@app.get("/users")
def get_users():
    """Get all users (for development/testing)"""
    users = list(db.users.find({}, {"_id": 0}))
    return {"users": users}

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("BACKEND_HOST", "0.0.0.0")
    port = int(os.getenv("BACKEND_PORT", 8000))
    
    logger.info(f"Starting server on {host}:{port}")
    uvicorn.run(
        "app.main:app",
        host=host,
        port=port,
        reload=True,
        log_level="info"
    )
