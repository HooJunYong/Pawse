"""
Models package for AI Chat Module
"""

from app.models.companion import (
    AICompanion,
    AICompanionCreate,
    AICompanionUpdate,
    AICompanionResponse
)
from app.models.personality import (
    Personality,
    PersonalityCreate,
    PersonalityUpdate,
    PersonalityResponse
)
from app.models.chat_session import (
    ChatSession,
    ChatSessionCreate,
    ChatSessionResponse
)
from app.models.chat_message import (
    ChatMessage,
    Message,
    SendMessageRequest,
    MessageResponse,
    ChatMessageResponse,
    SendMessageResponse
)

__all__ = [
    "AICompanion",
    "AICompanionCreate",
    "AICompanionUpdate",
    "AICompanionResponse",
    "Personality",
    "PersonalityCreate",
    "PersonalityUpdate",
    "PersonalityResponse",
    "ChatSession",
    "ChatSessionCreate",
    "ChatSessionResponse",
    "ChatMessage",
    "Message",
    "SendMessageRequest",
    "MessageResponse",
    "ChatMessageResponse",
    "SendMessageResponse"
]
