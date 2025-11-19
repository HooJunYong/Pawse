"""
Routes package for AI Chat Module
"""

from app.routes.session_routes import router as session_router
from app.routes.message_routes import router as message_router
from app.routes.companion_routes import router as companion_router

__all__ = [
    "session_router",
    "message_router",
    "companion_router"
]
