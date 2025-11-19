from pydantic import BaseModel, Field
from datetime import datetime
from typing import List, Literal


class Message(BaseModel):
    """Individual message in a conversation"""
    role: Literal["user", "AI"] = Field(..., description="Message sender role")
    message_text: str = Field(..., description="Message content")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    emotion: str | None = Field(default=None, description="Detected emotion (for user messages)")
    
    class Config:
        json_schema_extra = {
            "example": {
                "role": "user",
                "message_text": "I'm feeling anxious today",
                "timestamp": "2024-01-01T10:00:00",
                "emotion": "anxious"
            }
        }


class ChatMessage(BaseModel):
    """Chat Message document for MongoDB collection"""
    message_id: str = Field(..., description="Primary Key (MSG001, MSG002, etc.)")
    session_id: str = Field(..., description="Reference to Chat Session")
    messages: List[Message] = Field(default_factory=list, description="Array of conversation messages")
    
    class Config:
        json_schema_extra = {
            "example": {
                "message_id": "MSG001",
                "session_id": "SESS001",
                "messages": [
                    {
                        "role": "AI",
                        "message_text": "Hello! How are you feeling today?",
                        "timestamp": "2024-01-01T10:00:00"
                    },
                    {
                        "role": "user",
                        "message_text": "I'm feeling anxious",
                        "timestamp": "2024-01-01T10:01:00",
                        "emotion": "anxious"
                    }
                ]
            }
        }


class SendMessageRequest(BaseModel):
    """Request model for sending a message"""
    session_id: str
    message_text: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "session_id": "SESS001",
                "message_text": "I'm feeling anxious today"
            }
        }


class MessageResponse(BaseModel):
    """Response model for a single message"""
    role: str
    message_text: str
    timestamp: datetime
    emotion: str | None = None


class ChatMessageResponse(BaseModel):
    """Response model for chat messages"""
    message_id: str
    session_id: str
    messages: List[MessageResponse]


class SendMessageResponse(BaseModel):
    """Response model after sending a message"""
    success: bool
    user_message: MessageResponse
    ai_response: MessageResponse
    detected_emotion: str
