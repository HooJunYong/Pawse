from __future__ import annotations

import secrets
from datetime import datetime
from typing import Iterable, Optional

from ..config.timezone import now_my
from ..models.chat_schemas import (
    ChatConversationResponse,
    ChatMessageResponse,
    MarkConversationReadRequest,
    ParticipantRole,
    SendChatMessageRequest,
)
from ..models.database import db
from ..services.notification_service import create_notification


def _guess_image_mime(image_base64: str) -> str:
    sample = image_base64.strip()[:30]
    if sample.startswith("/9j/"):
        return "image/jpeg"
    if sample.startswith("iVBORw0KGgo"):
        return "image/png"
    if sample.startswith("R0lGOD"):
        return "image/gif"
    if sample.startswith("Qk"):
        return "image/bmp"
    return "image/png"


def _normalize_image_candidate(value: Optional[str]) -> Optional[str]:
    if not isinstance(value, str):
        return None

    candidate = value.strip()
    if not candidate:
        return None

    lower = candidate.lower()
    if lower in {"null", "none"}:
        return None
    if lower.startswith("data:image/"):
        return candidate
    if lower.startswith("http://") or lower.startswith("https://"):
        return candidate

    mime_type = _guess_image_mime(candidate)
    return f"data:{mime_type};base64,{candidate}"


def _resolve_avatar(candidates: Iterable[Optional[str]]) -> Optional[str]:
    for candidate in candidates:
        normalized = _normalize_image_candidate(candidate)
        if normalized:
            return normalized
    return None


def _compose_full_name(parts: Iterable[Optional[str]]) -> str:
    name = " ".join(filter(None, (part.strip() for part in parts if part))).strip()
    return name


def _get_client_display(user_id: str) -> tuple[str, Optional[str]]:
    profile = db.user_profile.find_one({"user_id": user_id})
    if profile:
        # Support both snake_case and camelCase keys that may exist in legacy documents
        first_name = profile.get("first_name") or profile.get("firstName")
        last_name = profile.get("last_name") or profile.get("lastName")
        name = _compose_full_name([first_name, last_name])
        avatar_url = _resolve_avatar(
            [
                profile.get("profile_picture_url") or profile.get("profilePictureUrl"),
                profile.get("profile_picture") or profile.get("profilePicture"),
                profile.get("avatar_url") or profile.get("avatarUrl"),
                profile.get("avatar_base64") or profile.get("avatarBase64"),
                profile.get("profile_picture_base64") or profile.get("profilePictureBase64"),
            ]
        )
        if name:
            return name, avatar_url
    user = db.users.find_one({"user_id": user_id})
    if user:
        full_name = user.get("full_name") or user.get("fullName") or ""
        if full_name:
            return full_name, _resolve_avatar(
                [
                    user.get("profile_picture_url") or user.get("profilePictureUrl"),
                    user.get("avatar_url") or user.get("avatarUrl"),
                    user.get("avatar_base64") or user.get("avatarBase64"),
                ]
            )
        email = user.get("email") or ""
        if email:
            return email.split("@")[0], _resolve_avatar(
                [
                    user.get("profile_picture_url") or user.get("profilePictureUrl"),
                    user.get("avatar_url") or user.get("avatarUrl"),
                    user.get("avatar_base64") or user.get("avatarBase64"),
                ]
            )
    return "Client", None


def _get_therapist_display(user_id: str) -> tuple[str, Optional[str]]:
    therapist = db.therapist_profile.find_one({"user_id": user_id})
    if therapist:
        first = therapist.get("first_name") or therapist.get("firstName")
        last = therapist.get("last_name") or therapist.get("lastName")
        name = _compose_full_name(["Dr.", first, last])
        avatar_url = _resolve_avatar(
            [
                therapist.get("profile_picture_url") or therapist.get("profilePictureUrl"),
                therapist.get("profile_picture") or therapist.get("profilePicture"),
                therapist.get("profile_picture_base64") or therapist.get("profilePictureBase64"),
            ]
        )
        if name.strip():
            return name.strip(), avatar_url
    return "Therapist", None


def _conversation_projection(conversation: dict, requesting_role: ParticipantRole) -> ChatConversationResponse:
    client_name, client_avatar = _get_client_display(conversation["client_user_id"])
    therapist_name, therapist_avatar = _get_therapist_display(conversation["therapist_user_id"])
    unread_count = int(conversation.get("unread_for_client", 0) if requesting_role == "client" else conversation.get("unread_for_therapist", 0))

    return ChatConversationResponse(
        conversation_id=conversation["conversation_id"],
        client_user_id=conversation["client_user_id"],
        therapist_user_id=conversation["therapist_user_id"],
        client_name=client_name,
        therapist_name=therapist_name,
        client_avatar_url=client_avatar,
        therapist_avatar_url=therapist_avatar,
        last_message=conversation.get("last_message"),
        last_message_at=conversation.get("last_message_at"),
        unread_count=unread_count,
    )


def get_or_create_conversation(client_user_id: str, therapist_user_id: str) -> dict:
    conversation = db.chat_conversations.find_one({
        "client_user_id": client_user_id,
        "therapist_user_id": therapist_user_id,
    })
    if conversation:
        return conversation

    now_ts = now_my()
    conversation_id = secrets.token_hex(16)
    conversation_doc = {
        "conversation_id": conversation_id,
        "client_user_id": client_user_id,
        "therapist_user_id": therapist_user_id,
        "created_at": now_ts,
        "updated_at": now_ts,
        "last_message": None,
        "last_message_at": None,
        "unread_for_client": 0,
        "unread_for_therapist": 0,
    }
    db.chat_conversations.insert_one(conversation_doc)
    return conversation_doc


def list_conversations(user_id: str, role: ParticipantRole) -> list[ChatConversationResponse]:
    if role == "client":
        query = {"client_user_id": user_id}
    else:
        query = {"therapist_user_id": user_id}

    conversations = db.chat_conversations.find(query).sort("updated_at", -1)
    return [_conversation_projection(conv, role) for conv in conversations]


def get_conversation_summary(conversation_id: str, role: ParticipantRole) -> ChatConversationResponse:
    conversation = db.chat_conversations.find_one({"conversation_id": conversation_id})
    if not conversation:
        raise ValueError("Conversation not found")
    return _conversation_projection(conversation, role)


def fetch_messages(conversation_id: str, *, limit: int = 50, before: Optional[datetime] = None) -> list[ChatMessageResponse]:
    query: dict[str, object] = {"conversation_id": conversation_id}
    if before is not None:
        query["created_at"] = {"$lt": before}

    cursor = (
        db.chat_messages
        .find(query)
        .sort("created_at", -1)
        .limit(limit)
    )
    messages = list(cursor)
    messages.reverse()
    return [
        ChatMessageResponse(
            message_id=message["message_id"],
            conversation_id=message["conversation_id"],
            sender_id=message["sender_id"],
            sender_role=message.get("sender_role", "client"),
            content=message.get("content", ""),
            created_at=message.get("created_at", now_my()),
            is_read=bool(message.get("is_read", False)),
        )
        for message in messages
    ]


def send_message(payload: SendChatMessageRequest) -> ChatMessageResponse:
    content = payload.content.strip()
    if not content:
        raise ValueError("Message content cannot be empty")

    conversation: Optional[dict] = None
    if payload.conversation_id:
        conversation = db.chat_conversations.find_one({"conversation_id": payload.conversation_id})

    client_user_id = payload.client_user_id
    therapist_user_id = payload.therapist_user_id

    if conversation is None:
        if not client_user_id or not therapist_user_id:
            raise ValueError("Client and therapist IDs are required to start a conversation")
        conversation = get_or_create_conversation(client_user_id, therapist_user_id)
    else:
        client_user_id = conversation.get("client_user_id")
        therapist_user_id = conversation.get("therapist_user_id")

    conversation_id = conversation["conversation_id"]
    now_ts = now_my()
    message_id = secrets.token_hex(20)
    message_doc = {
        "message_id": message_id,
        "conversation_id": conversation_id,
        "sender_id": payload.sender_id,
        "sender_role": payload.sender_role,
        "content": content,
        "created_at": now_ts,
        "is_read": False,
    }
    db.chat_messages.insert_one(message_doc)

    unread_field = "unread_for_client" if payload.sender_role == "therapist" else "unread_for_therapist"
    db.chat_conversations.update_one(
        {"conversation_id": conversation_id},
        {
            "$set": {
                "last_message": content,
                "updated_at": now_ts,
            },
            "$inc": {unread_field: 1},
        },
    )

    # Send notification to recipient
    recipient_id = client_user_id if payload.sender_role == "therapist" else therapist_user_id
    if recipient_id:
        sender_name = "Therapist" if payload.sender_role == "therapist" else "Client"
        # Try to get better name
        if payload.sender_role == "therapist":
             # Get therapist name
             pass # Simplified for now
        
        create_notification(
            user_id=recipient_id,
            type="message",
            title=f"New message from {sender_name}",
            body=content[:50] + "..." if len(content) > 50 else content,
            data={"conversation_id": conversation_id, "sender_id": payload.sender_id}
        )

    return ChatMessageResponse(
        message_id=message_id,
        conversation_id=conversation_id,
        sender_id=payload.sender_id,
        sender_role=payload.sender_role,
        content=content,
        created_at=now_ts,
        is_read=False,
    )


def mark_conversation_read(conversation_id: str, request: MarkConversationReadRequest) -> None:
    field = "unread_for_client" if request.user_role == "client" else "unread_for_therapist"
    db.chat_conversations.update_one(
        {"conversation_id": conversation_id},
        {
            "$set": {field: 0},
        },
    )

    other_role: ParticipantRole = "therapist" if request.user_role == "client" else "client"
    db.chat_messages.update_many(
        {
            "conversation_id": conversation_id,
            "sender_role": other_role,
        },
        {
            "$set": {"is_read": True},
        },
    )
