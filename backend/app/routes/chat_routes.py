from __future__ import annotations

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, HTTPException, Query  # type: ignore

from ..models.chat_schemas import (
    ChatConversationResponse,
    ChatMessageResponse,
    ConversationListResponse,
    CreateConversationRequest,
    MarkConversationReadRequest,
    SendChatMessageRequest,
)
from ..services.chat_service import (
    fetch_messages,
    get_conversation_summary,
    get_or_create_conversation,
    list_conversations,
    mark_conversation_read,
    send_message,
)

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("/conversations", response_model=ChatConversationResponse)
def create_conversation(request: CreateConversationRequest) -> ChatConversationResponse:
    conversation = get_or_create_conversation(request.client_user_id, request.therapist_user_id)
    try:
        return get_conversation_summary(conversation["conversation_id"], request.requester_role)
    except ValueError as exc:  # pragma: no cover - defensive guard
        raise HTTPException(status_code=404, detail=str(exc))


@router.get("/conversations", response_model=ConversationListResponse)
def get_conversations(user_id: str = Query(..., min_length=1), role: str = Query("client")) -> ConversationListResponse:
    if role not in {"client", "therapist"}:
        raise HTTPException(status_code=400, detail="Role must be 'client' or 'therapist'")
    role_value = "client" if role == "client" else "therapist"
    conversations = list_conversations(user_id, role_value)
    return ConversationListResponse(conversations=conversations)


@router.get("/conversations/{conversation_id}/messages", response_model=list[ChatMessageResponse])
def get_conversation_messages(
    conversation_id: str,
    limit: int = Query(50, gt=0, le=200),
    before: Optional[str] = Query(None),
) -> list[ChatMessageResponse]:
    target_before: Optional[datetime] = None
    if before:
        try:
            target_before = datetime.fromisoformat(before)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid 'before' timestamp")

    return fetch_messages(conversation_id, limit=limit, before=target_before)


@router.post("/messages", response_model=ChatMessageResponse)
def post_message(payload: SendChatMessageRequest) -> ChatMessageResponse:
    try:
        return send_message(payload)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.post("/conversations/{conversation_id}/read")
def mark_read(conversation_id: str, payload: MarkConversationReadRequest) -> dict[str, bool]:
    mark_conversation_read(conversation_id, payload)
    return {"success": True}
