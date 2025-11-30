from __future__ import annotations

from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, Field  # type: ignore

ParticipantRole = Literal["client", "therapist"]


class CreateConversationRequest(BaseModel):
    client_user_id: str = Field(..., min_length=1)
    therapist_user_id: str = Field(..., min_length=1)
    requester_role: ParticipantRole = "client"


class ChatConversationResponse(BaseModel):
    conversation_id: str
    client_user_id: str
    therapist_user_id: str
    client_name: str
    therapist_name: str
    client_avatar_url: Optional[str] = None
    therapist_avatar_url: Optional[str] = None
    last_message: Optional[str] = None
    last_message_at: Optional[datetime] = None
    unread_count: int = 0


class ChatMessageResponse(BaseModel):
    message_id: str
    conversation_id: str
    sender_id: str
    sender_role: ParticipantRole
    content: str
    created_at: datetime
    is_read: bool = False


class SendChatMessageRequest(BaseModel):
    sender_id: str = Field(..., min_length=1)
    sender_role: ParticipantRole
    content: str = Field(..., min_length=1)
    conversation_id: Optional[str] = None
    client_user_id: Optional[str] = None
    therapist_user_id: Optional[str] = None


class MarkConversationReadRequest(BaseModel):
    user_id: str = Field(..., min_length=1)
    user_role: ParticipantRole


class ConversationListResponse(BaseModel):
    conversations: list[ChatConversationResponse]
