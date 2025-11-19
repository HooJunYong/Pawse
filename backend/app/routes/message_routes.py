from fastapi import APIRouter, HTTPException, Depends
from datetime import datetime
import logging
from typing import List

from app.models.chat_message import (
    SendMessageRequest,
    SendMessageResponse,
    ChatMessageResponse,
    MessageResponse,
    Message
)
from app.mongodb_connection import get_database
from app.services.ai_chat_service import AIChatService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/chat/message", tags=["Chat Messages"])


def get_chat_service():
    """Dependency to get chat service instance"""
    db = get_database()
    return AIChatService(db)


@router.post("/send", response_model=SendMessageResponse)
async def send_message(
    request: SendMessageRequest,
    chat_service: AIChatService = Depends(get_chat_service)
):
    """
    Send a user message and receive AI response
    
    - **session_id**: The active session
    - **message_text**: User's message text
    
    Returns both the user message and AI response with detected emotion
    """
    try:
        db = get_database()
        
        # Verify session exists and is active
        session = db.chat_sessions.find_one({"session_id": request.session_id})
        if not session:
            raise HTTPException(
                status_code=404,
                detail=f"Session not found: {request.session_id}"
            )
        
        if session.get("end_time"):
            raise HTTPException(
                status_code=400,
                detail="Cannot send message to ended session"
            )
        
        # Get companion personality info
        companion_info = await chat_service.get_companion_personality(
            session["companion_id"]
        )
        
        if not companion_info:
            raise HTTPException(
                status_code=500,
                detail="Failed to retrieve companion information"
            )
        
        # Detect emotion from user message
        detected_emotion = await chat_service.detect_emotion(request.message_text)
        logger.info(f"Detected emotion: {detected_emotion}")
        
        # Get existing message document for this session or create new one
        message_doc = db.chat_messages.find_one({"session_id": request.session_id})
        
        if message_doc:
            # Get conversation history
            conversation_history = [
                Message(**msg) for msg in message_doc["messages"]
            ]
        else:
            # No message document found - this shouldn't happen if greeting was created
            # Create new message document
            message_id = await chat_service.generate_message_id()
            message_doc = {
                "message_id": message_id,
                "session_id": request.session_id,
                "messages": []
            }
            db.chat_messages.insert_one(message_doc)
            conversation_history = []
        
        # Generate AI response
        ai_response_text = await chat_service.generate_response(
            conversation_history=conversation_history,
            personality_prompt_modifier=companion_info["personality_prompt_modifier"],
            companion_name=companion_info["companion_name"],
            detected_emotion=detected_emotion,
            user_message=request.message_text
        )
        
        # Create message objects
        timestamp = datetime.utcnow()
        
        user_message = Message(
            role="user",
            message_text=request.message_text,
            timestamp=timestamp,
            emotion=detected_emotion
        )
        
        ai_message = Message(
            role="AI",
            message_text=ai_response_text,
            timestamp=timestamp,
            emotion=None
        )
        
        # Append both messages to the messages array
        db.chat_messages.update_one(
            {"session_id": request.session_id},
            {
                "$push": {
                    "messages": {
                        "$each": [
                            user_message.model_dump(),
                            ai_message.model_dump()
                        ]
                    }
                }
            }
        )
        
        logger.info(f"Added messages to session: {request.session_id}")
        
        # Return response
        return SendMessageResponse(
            success=True,
            user_message=MessageResponse(
                role=user_message.role,
                message_text=user_message.message_text,
                timestamp=user_message.timestamp,
                emotion=user_message.emotion
            ),
            ai_response=MessageResponse(
                role=ai_message.role,
                message_text=ai_message.message_text,
                timestamp=ai_message.timestamp,
                emotion=ai_message.emotion
            ),
            detected_emotion=detected_emotion
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending message: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to send message: {str(e)}")


@router.get("/{session_id}", response_model=ChatMessageResponse)
async def get_messages(session_id: str):
    """
    Get all messages for a session
    
    - **session_id**: The session to retrieve messages from
    
    Returns all messages in the conversation
    """
    try:
        db = get_database()
        
        # Verify session exists
        session = db.chat_sessions.find_one({"session_id": session_id})
        if not session:
            raise HTTPException(
                status_code=404,
                detail=f"Session not found: {session_id}"
            )
        
        # Get message document
        message_doc = db.chat_messages.find_one({"session_id": session_id})
        
        if not message_doc:
            # No messages yet - return empty
            return ChatMessageResponse(
                message_id="",
                session_id=session_id,
                messages=[]
            )
        
        # Convert messages to response format
        messages = [
            MessageResponse(
                role=msg["role"],
                message_text=msg["message_text"],
                timestamp=msg["timestamp"],
                emotion=msg.get("emotion")
            )
            for msg in message_doc["messages"]
        ]
        
        logger.info(f"Retrieved {len(messages)} messages for session: {session_id}")
        
        return ChatMessageResponse(
            message_id=message_doc["message_id"],
            session_id=message_doc["session_id"],
            messages=messages
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving messages: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve messages: {str(e)}")


@router.get("/history/{session_id}", response_model=List[MessageResponse])
async def get_message_history(session_id: str, limit: int = 50):
    """
    Get message history for a session with optional limit
    
    - **session_id**: The session to retrieve messages from
    - **limit**: Maximum number of messages to return (default: 50)
    
    Returns list of messages (newest first)
    """
    try:
        db = get_database()
        
        # Verify session exists
        session = db.chat_sessions.find_one({"session_id": session_id})
        if not session:
            raise HTTPException(
                status_code=404,
                detail=f"Session not found: {session_id}"
            )
        
        # Get message document
        message_doc = db.chat_messages.find_one({"session_id": session_id})
        
        if not message_doc:
            return []
        
        # Get messages (most recent first)
        messages = message_doc["messages"][-limit:] if len(message_doc["messages"]) > limit else message_doc["messages"]
        
        # Convert to response format
        message_responses = [
            MessageResponse(
                role=msg["role"],
                message_text=msg["message_text"],
                timestamp=msg["timestamp"],
                emotion=msg.get("emotion")
            )
            for msg in messages
        ]
        
        logger.info(f"Retrieved {len(message_responses)} messages for session: {session_id}")
        
        return message_responses
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving message history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve message history: {str(e)}")
