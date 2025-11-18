import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()

class GeminiService:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key or api_key == "your_gemini_api_key_here":
            raise ValueError("Please set GEMINI_API_KEY in .env file")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')
        self.chat_sessions = {}
    
    def start_chat(self, user_id: str):
        """Start a new chat session for a user"""
        self.chat_sessions[user_id] = self.model.start_chat(history=[])
        return self.chat_sessions[user_id]
    
    def get_chat(self, user_id: str):
        """Get existing chat session or create new one"""
        if user_id not in self.chat_sessions:
            return self.start_chat(user_id)
        return self.chat_sessions[user_id]
    
    async def send_message(self, user_id: str, message: str):
        """Send message and get response"""
        try:
            chat = self.get_chat(user_id)
            response = chat.send_message(message)
            return {
                "success": True,
                "response": response.text,
                "error": None
            }
        except Exception as e:
            return {
                "success": False,
                "response": None,
                "error": str(e)
            }
    
    def clear_chat(self, user_id: str):
        """Clear chat session for a user"""
        if user_id in self.chat_sessions:
            del self.chat_sessions[user_id]

# Create singleton instance
gemini_service = GeminiService()