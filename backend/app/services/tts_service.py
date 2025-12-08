"""
Text-to-Speech Service using Edge TTS
Generates audio files based on companion's voice tone and gender preferences
"""

import edge_tts
import asyncio
import os
import uuid
from datetime import datetime
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

# Configuration for each tone with gender-specific voices
TONE_CONFIG = {
    "gentle": {
        "female": "en-US-AnaNeural",
        "male": "en-US-ChristopherNeural",
        "rate": "-10%",
        "pitch": "+0Hz"
    },
    "energetic": {
        "female": "en-US-AvaNeural",
        "male": "en-US-GuyNeural",
        "rate": "+15%",
        "pitch": "+2Hz"
    },
    "serious": {
        "female": "en-US-MichelleNeural",
        "male": "en-US-RogerNeural",
        "rate": "+0%",
        "pitch": "-5Hz"
    },
    "playful": {
        "female": "en-US-JennyNeural",
        "male": "en-US-EricNeural",
        "rate": "+5%",
        "pitch": "+0Hz"
    },
    "insightful": {
        "female": "en-US-MichelleNeural",
        "male": "en-US-RogerNeural",
        "rate": "-10%",
        "pitch": "-5Hz"
    },
    "tough love": {
        "female": "en-US-MichelleNeural", 
        "male": "en-US-RogerNeural", 
        "rate": "+5%",
        "pitch": "-10Hz"
    },
    "calm": {
        "female": "en-US-AnaNeural",
        "male": "en-US-ChristopherNeural",
        "rate": "-25%",   
        "pitch": "-2Hz"
    }
}


class TTSService:
    """Service for generating text-to-speech audio files"""
    
    def __init__(self):
        # Create audio directory if it doesn't exist
        self.audio_dir = Path("app/static/audio")
        self.audio_dir.mkdir(parents=True, exist_ok=True)
        
    async def generate_audio(
        self,
        text: str,
        tone: str = "gentle",
        gender: str = "female"
    ) -> dict:
        """
        Generate audio file from text using Edge TTS
        
        Args:
            text: The text to convert to speech
            tone: Voice tone (gentle, energetic, serious, playful)
            gender: Voice gender (female, male)
            
        Returns:
            dict with audio file path and metadata
        """
        try:
            # Normalize inputs
            tone = tone.lower()
            gender = gender.lower()
            
            # Validate tone and gender
            if tone not in TONE_CONFIG:
                logger.warning(f"Invalid tone '{tone}', using 'gentle' as default")
                tone = "gentle"
                
            if gender not in ["female", "male"]:
                logger.warning(f"Invalid gender '{gender}', using 'female' as default")
                gender = "female"
            
            # Get voice configuration
            config = TONE_CONFIG[tone]
            voice = config[gender]
            rate = config["rate"]
            pitch = config["pitch"]
            
            # Generate unique filename
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            unique_id = str(uuid.uuid4())[:8]
            filename = f"tts_{tone}_{gender}_{timestamp}_{unique_id}.mp3"
            filepath = self.audio_dir / filename
            
            # Create TTS communicate object
            communicate = edge_tts.Communicate(
                text=text,
                voice=voice,
                rate=rate,
                pitch=pitch
            )
            
            # Save audio file
            await communicate.save(str(filepath))
            
            logger.info(f"Generated TTS audio: {filename}")
            
            # Return file information
            return {
                "success": True,
                "filename": filename,
                "filepath": str(filepath),
                "url": f"/static/audio/{filename}",
                "tone": tone,
                "gender": gender,
                "voice": voice,
                "duration_estimated": len(text) * 0.1
            }
            
        except Exception as e:
            logger.error(f"Error generating TTS audio: {str(e)}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def cleanup_old_files(self, max_age_hours: int = 24):
        """
        Remove audio files older than specified hours
        
        Args:
            max_age_hours: Maximum age of files to keep (default 24 hours)
        """
        try:
            current_time = datetime.now()
            deleted_count = 0
            
            for audio_file in self.audio_dir.glob("tts_*.mp3"):
                # Get file modification time
                file_time = datetime.fromtimestamp(audio_file.stat().st_mtime)
                age_hours = (current_time - file_time).total_seconds() / 3600
                
                if age_hours > max_age_hours:
                    audio_file.unlink()
                    deleted_count += 1
                    
            if deleted_count > 0:
                logger.info(f"Cleaned up {deleted_count} old TTS audio files")
                
        except Exception as e:
            logger.error(f"Error cleaning up audio files: {str(e)}")


# Create singleton instance
tts_service = TTSService()


# Helper function for synchronous contexts
def generate_audio_sync(text: str, tone: str = "gentle", gender: str = "female") -> dict:
    """
    Synchronous wrapper for generate_audio
    
    Args:
        text: The text to convert to speech
        tone: Voice tone (gentle, energetic, serious, playful)
        gender: Voice gender (female, male)
        
    Returns:
        dict with audio file path and metadata
    """
    return asyncio.run(tts_service.generate_audio(text, tone, gender))
