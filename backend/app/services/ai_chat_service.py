import google.generativeai as genai
from typing import List, Dict, Optional
from datetime import datetime
import logging
import uuid
from pymongo.collection import Collection
from pymongo import DESCENDING

from app.config.settings import get_settings
from app.models.chat_message import Message, ChatMessage
from app.models.chat_session import ChatSession

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get settings
settings = get_settings()

# Configure Gemini API
genai.configure(api_key=settings.gemini_api_key)


class AIChatService:
    """Service for AI chat operations with Gemini API integration"""
    
    # Emotion keywords dictionary
    EMOTION_KEYWORDS = {
        "happy": ["happy", "joy", "excited", "great", "wonderful", "awesome", "fantastic", "delighted", "pleased", "cheerful"],
        "sad": ["sad", "unhappy", "depressed", "down", "miserable", "gloomy", "heartbroken", "sorrowful", "melancholy"],
        "angry": ["angry", "mad", "furious", "irritated", "annoyed", "frustrated", "rage", "outraged"],
        "anxious": ["anxious", "worried", "nervous", "stressed", "tense", "uneasy", "concerned", "fearful", "panic"],
        "excited": ["excited", "thrilled", "pumped", "enthusiastic", "eager", "hyped"],
        "tired": ["tired", "exhausted", "fatigued", "weary", "drained", "sleepy"],
        "lonely": ["lonely", "alone", "isolated", "abandoned", "solitary"],
        "confused": ["confused", "lost", "uncertain", "puzzled", "bewildered"],
        "grateful": ["grateful", "thankful", "appreciative", "blessed"],
        "hopeful": ["hopeful", "optimistic", "positive", "encouraged"],
        "neutral": []
    }
    
    def __init__(self, db):
        """Initialize AI Chat Service with database connection"""
        self.db = db
        self.model = genai.GenerativeModel(settings.gemini_model)
        
    async def detect_emotion(self, message_text: str) -> str:
        """
        Detect emotion from message text using keyword matching
        
        Args:
            message_text: The text to analyze
            
        Returns:
            Detected emotion as string
        """
        message_lower = message_text.lower()
        
        # Check each emotion's keywords
        for emotion, keywords in self.EMOTION_KEYWORDS.items():
            for keyword in keywords:
                if keyword in message_lower:
                    logger.info(f"Detected emotion: {emotion} (keyword: {keyword})")
                    return emotion
        
        # Default to neutral if no emotion detected
        logger.info("No specific emotion detected, defaulting to neutral")
        return "neutral"
    
    async def generate_greeting(self, personality_prompt_modifier: str, companion_name: str) -> str:
        """
        Generate a personalized greeting message using Gemini API
        
        Args:
            personality_prompt_modifier: The personality prompt from the Personality collection
            companion_name: Name of the AI companion
            
        Returns:
            Generated greeting message
        """
        try:
            prompt = f"""You are {companion_name}, an AI mental health companion.

{personality_prompt_modifier}

Generate a warm, welcoming greeting message to start a new conversation with a user. 
The greeting should:
- Be friendly and inviting
- Be 1-2 sentences long
- Reflect your personality
- Ask how they're feeling or what's on their mind
- NOT use asterisks or action descriptions

Generate only the greeting message, nothing else."""

            response = self.model.generate_content(prompt)
            greeting = response.text.strip()
            
            logger.info(f"Generated greeting for {companion_name}: {greeting[:50]}...")
            return greeting
            
        except Exception as e:
            logger.error(f"Error generating greeting: {str(e)}")
            # Fallback greeting
            return f"Hello! I'm {companion_name}. How are you feeling today?"
    
    async def generate_response(
        self,
        conversation_history: List[Message],
        personality_prompt_modifier: str,
        companion_name: str,
        detected_emotion: str,
        user_message: str
    ) -> str:
        """
        Generate AI response using Gemini API with context
        
        Args:
            conversation_history: List of previous messages for context
            personality_prompt_modifier: The personality prompt
            companion_name: Name of the AI companion
            detected_emotion: Emotion detected from user's message
            user_message: The current user message
            
        Returns:
            Generated AI response
        """
        try:
            # Build conversation history for context (limit to last 10 messages to avoid token limits)
            history_text = ""
            recent_history = conversation_history[-10:] if len(conversation_history) > 10 else conversation_history
            
            for msg in recent_history:
                role_label = "User" if msg.role == "user" else companion_name
                history_text += f"{role_label}: {msg.message_text}\n"
            
            # Emotion context
            emotion_context = ""
            if detected_emotion != "neutral":
                emotion_context = f"\nThe user seems to be feeling {detected_emotion}. Please respond with appropriate empathy and support."
            
            prompt = f"""You are {companion_name}, an AI mental health companion.

{personality_prompt_modifier}

Conversation history:
{history_text}
User: {user_message}
{emotion_context}

---
SYSTEM INSTRUCTIONS:
- Stay in character at all times.
- Do NOT use asterisks (*) for actions.
- Do NOT output internal thoughts.
- Reply directly to the user.
"""

            response = self.model.generate_content(prompt)
            ai_response = response.text.strip()
            
            logger.info(f"Generated response for emotion '{detected_emotion}': {ai_response[:50]}...")
            return ai_response
            
        except Exception as e:
            logger.error(f"Error generating response: {str(e)}")
            # Fallback response
            return "I understand. I'm here to listen and support you. Could you tell me more about what you're feeling?"
    
    async def generate_session_id(self) -> str:
        """
        Generate session ID using UUID.
        
        Returns:
            New session ID
        """
        new_session_id = str(uuid.uuid4())
        logger.info(f"Generated new session ID: {new_session_id}")
        return new_session_id
    
    async def generate_message_id(self) -> str:
        """
        Generate message ID using UUID.
        
        Returns:
            New message ID
        """
        new_message_id = str(uuid.uuid4())
        logger.info(f"Generated new message ID: {new_message_id}")
        return new_message_id
    
    async def get_companion_personality(self, companion_id: str) -> Optional[Dict]:
        """
        Get companion's personality information
        
        Args:
            companion_id: The companion ID
            
        Returns:
            Dictionary containing companion and personality info, or None if not found
        """
        try:
            # Get companion
            companion = self.db.ai_companions.find_one({"companion_id": companion_id})
            if not companion:
                logger.warning(f"Companion not found: {companion_id}")
                return None
            
            # Get personality
            personality = self.db.personalities.find_one(
                {"personality_id": companion["personality_id"]}
            )
            if not personality:
                logger.warning(f"Personality not found: {companion['personality_id']}")
                return None
            
            return {
                "companion_name": companion["companion_name"],
                "personality_prompt_modifier": personality["prompt_modifier"]
            }
            
        except Exception as e:
            logger.error(f"Error getting companion personality: {str(e)}")
            return None
