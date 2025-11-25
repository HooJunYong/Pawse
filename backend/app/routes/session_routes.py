from fastapi import APIRouter, HTTPException, Depends
from typing import List
from datetime import datetime
import logging

from app.models.chat_session import (
    ChatSessionCreate,
    ChatSessionResponse,
    ChatSession
)
from app.models.chat_message import ChatMessage, Message
from app.models.database import get_database
from app.services.ai_chat_service import AIChatService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/chat/session", tags=["Chat Sessions"])


def get_chat_service():
    """Dependency to get chat service instance"""
    db = get_database()
    return AIChatService(db)


@router.post("/start", response_model=ChatSessionResponse, status_code=201)
async def start_new_chat_session(
    session_create: ChatSessionCreate,
    chat_service: AIChatService = Depends(get_chat_service)
):
    """
    Start a new chat session and generate initial greeting
    
    - **user_id**: User identifier
    - **companion_id**: AI Companion identifier
    
    Returns the created session with auto-generated session_id
    """
    try:
        db = get_database()
        
        # Verify companion exists and is active
        companion = db.ai_companions.find_one(
            {"companion_id": session_create.companion_id, "is_active": True}
        )
        if not companion:
            raise HTTPException(
                status_code=404,
                detail=f"Active companion not found: {session_create.companion_id}"
            )
        
        # Generate session ID
        session_id = await chat_service.generate_session_id()
        
        # Create session document
        session = ChatSession(
            session_id=session_id,
            user_id=session_create.user_id,
            companion_id=session_create.companion_id,
            start_time=datetime.utcnow(),
            end_time=None
        )
        
        # Insert session into database
        db.chat_sessions.insert_one(session.model_dump())
        logger.info(f"Created new session: {session_id}")
        
        # Get companion personality for greeting
        companion_info = await chat_service.get_companion_personality(
            session_create.companion_id
        )
        
        if not companion_info:
            raise HTTPException(
                status_code=500,
                detail="Failed to retrieve companion personality"
            )
        
        # Generate greeting message
        greeting_text = await chat_service.generate_greeting(
            personality_prompt_modifier=companion_info["personality_prompt_modifier"],
            companion_name=companion_info["companion_name"]
        )
        
        # Generate message ID and create greeting message document
        message_id = await chat_service.generate_message_id()
        greeting_message = ChatMessage(
            message_id=message_id,
            session_id=session_id,
            messages=[
                Message(
                    role="AI",
                    message_text=greeting_text,
                    timestamp=datetime.utcnow(),
                    emotion=None
                )
            ]
        )
        
        # Store greeting message
        db.chat_messages.insert_one(greeting_message.model_dump())
        logger.info(f"Created greeting message: {message_id}")
        
        # Return session response
        return ChatSessionResponse.from_session(session)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error starting session: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to start session: {str(e)}")


@router.put("/{session_id}/end", response_model=ChatSessionResponse)
async def end_chat_session(session_id: str):
    """
    End a chat session by setting end_time
    
    - **session_id**: The session to end
    """
    try:
        db = get_database()
        
        # Find session
        session = db.chat_sessions.find_one({"session_id": session_id})
        if not session:
            raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")
        
        # Check if already ended
        if session.get("end_time"):
            raise HTTPException(status_code=400, detail="Session already ended")
        
        # Update end_time
        result = db.chat_sessions.update_one(
            {"session_id": session_id},
            {"$set": {"end_time": datetime.utcnow()}}
        )
        
        if result.modified_count == 0:
            raise HTTPException(status_code=500, detail="Failed to end session")
        
        # Fetch updated session
        updated_session = db.chat_sessions.find_one({"session_id": session_id})
        logger.info(f"Ended session: {session_id}")
        
        return ChatSessionResponse(
            session_id=updated_session["session_id"],
            user_id=updated_session["user_id"],
            companion_id=updated_session["companion_id"],
            start_time=updated_session["start_time"],
            end_time=updated_session["end_time"],
            is_active=False
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error ending session: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to end session: {str(e)}")


@router.get("/{session_id}", response_model=ChatSessionResponse)
async def get_session_by_id(session_id: str):
    """
    Get session details by session_id
    
    - **session_id**: The session to retrieve
    """
    try:
        db = get_database()
        
        session = db.chat_sessions.find_one({"session_id": session_id})
        if not session:
            raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")
        
        return ChatSessionResponse(
            session_id=session["session_id"],
            user_id=session["user_id"],
            companion_id=session["companion_id"],
            start_time=session["start_time"],
            end_time=session.get("end_time"),
            is_active=session.get("end_time") is None
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving session: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve session: {str(e)}")


@router.get("/user/{user_id}", response_model=List[ChatSessionResponse])
async def get_user_sessions(user_id: str, limit: int = 50, skip: int = 0):
    """
    Get all sessions for a specific user with pagination
    
    - **user_id**: User identifier
    - **limit**: Maximum number of sessions to return (default: 50)
    - **skip**: Number of sessions to skip for pagination (default: 0)
    """
    try:
        db = get_database()
        
        # Query sessions with pagination, sorted by start_time (newest first)
        sessions = list(
            db.chat_sessions
            .find({"user_id": user_id})
            .sort("start_time", -1)
            .skip(skip)
            .limit(limit)
        )
        
        # Convert to response models
        session_responses = [
            ChatSessionResponse(
                session_id=session["session_id"],
                user_id=session["user_id"],
                companion_id=session["companion_id"],
                start_time=session["start_time"],
                end_time=session.get("end_time"),
                is_active=session.get("end_time") is None
            )
            for session in sessions
        ]
        
        logger.info(f"Retrieved {len(session_responses)} sessions for user: {user_id}")
        return session_responses
        
    except Exception as e:
        logger.error(f"Error retrieving user sessions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve sessions: {str(e)}")


@router.post("/{session_id}/resume", response_model=ChatSessionResponse)
async def resume_session(session_id: str):
    """
    Resume an existing session (validate and return session info)
    
    - **session_id**: The session to resume
    """
    try:
        db = get_database()
        
        session = db.chat_sessions.find_one({"session_id": session_id})
        if not session:
            raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")
        
        # Verify companion is still active
        companion = db.ai_companions.find_one(
            {"companion_id": session["companion_id"], "is_active": True}
        )
        if not companion:
            raise HTTPException(
                status_code=400,
                detail="Session's companion is no longer active"
            )
        
        logger.info(f"Resumed session: {session_id}")
        
        return ChatSessionResponse(
            session_id=session["session_id"],
            user_id=session["user_id"],
            companion_id=session["companion_id"],
            start_time=session["start_time"],
            end_time=session.get("end_time"),
            is_active=True
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error resuming session: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to resume session: {str(e)}")


@router.get("/user/{user_id}/history")
async def get_user_chat_history(user_id: str):
    """
    Get chat history for a user with last message from each session
    
    - **user_id**: User identifier
    
    Returns list of chat sessions with their last message, companion_id, and end_time (or start_time if session is active)
    """
    try:
        db = get_database()
        
        # Get all sessions for the user, sorted by most recent first
        sessions = list(
            db.chat_sessions
            .find({"user_id": user_id})
            .sort("start_time", -1)
        )
        
        if not sessions:
            return []
        
        chat_history = []
        
        for session in sessions:
            session_id = session["session_id"]
            companion_id = session.get("companion_id", "")
            
            # Get the last message from chat_messages collection
            message_doc = db.chat_messages.find_one({"session_id": session_id})
            
            last_message_text = ""
            if message_doc and message_doc.get("messages"):
                # Get the last message from the messages array
                last_message = message_doc["messages"][-1]
                last_message_text = last_message.get("message_text", "")
            
            # Use end_time if session is ended, otherwise use start_time
            display_date = session.get("end_time") or session.get("start_time")
            
            chat_history.append({
                "session_id": session_id,
                "companion_id": companion_id,
                "date": display_date,
                "last_message": last_message_text,
                "is_active": session.get("end_time") is None
            })
        
        logger.info(f"Retrieved {len(chat_history)} chat history entries for user: {user_id}")
        return chat_history
        
    except Exception as e:
        logger.error(f"Error retrieving chat history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve chat history: {str(e)}")
