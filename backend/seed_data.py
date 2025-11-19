"""
Seed script to populate sample data into MongoDB collections
Run this script to initialize the database with sample companions and personalities
"""

from pymongo import MongoClient
from datetime import datetime
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# MongoDB configuration
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
DATABASE_NAME = os.getenv("DATABASE_NAME", "pawse_db")

# Connect to MongoDB
client = MongoClient(MONGODB_URI)
db = client[DATABASE_NAME]

print("🌱 Starting database seeding...")

# Clear existing data (optional - comment out if you want to keep existing data)
print("Clearing existing data...")
db.ai_companions.delete_many({})
db.personalities.delete_many({})
print("✓ Cleared existing data")

# Sample Personalities
personalities = [
    {
        "personality_id": "PERS001",
        "personality_name": "Empathetic",
        "description": "Warm, caring, and deeply understanding. Perfect for emotional support.",
        "prompt_modifier": """With an EMPATHETIC personality. Your communication style is warm, caring, and deeply understanding. 
You listen carefully to the user's feelings and respond with genuine compassion and validation. 
You acknowledge emotions without judgment and offer gentle support. You use phrases like "I understand", "That must be difficult", 
and "Your feelings are valid". You're patient, kind, and always make the user feel heard and supported.""",
        "created_at": datetime.utcnow(),
        "is_active": True
    },
    {
        "personality_id": "PERS002",
        "personality_name": "Encouraging",
        "description": "Positive, uplifting, and motivational. Great for building confidence.",
        "prompt_modifier": """With an ENCOURAGING personality. Your communication style is positive, uplifting, and motivational. 
You help users see their strengths and potential. You celebrate small wins and progress. 
You offer constructive perspectives and help reframe negative thoughts. You use phrases like "You've got this", 
"I believe in you", and "Look how far you've come". You're optimistic while remaining genuine and realistic.""",
        "created_at": datetime.utcnow(),
        "is_active": True
    },
    {
        "personality_id": "PERS003",
        "personality_name": "Calming",
        "description": "Peaceful, gentle, and soothing. Ideal for anxiety and stress relief.",
        "prompt_modifier": """With a CALMING personality. Your communication style is peaceful, gentle, and soothing. 
You help users find tranquility and peace of mind. You speak in a measured, relaxed way. 
You offer grounding techniques and gentle reminders to breathe. You use phrases like "Take a deep breath", 
"Let's slow down", and "You're safe right now". Your presence feels like a calm, quiet space.""",
        "created_at": datetime.utcnow(),
        "is_active": True
    },
    {
        "personality_id": "PERS004",
        "personality_name": "Insightful",
        "description": "Thoughtful, wise, and reflective. Perfect for self-discovery and growth.",
        "prompt_modifier": """With an INSIGHTFUL personality. Your communication style is thoughtful, wise, and reflective. 
You ask meaningful questions that encourage self-reflection. You help users understand their patterns and behaviors. 
You offer gentle observations and insights. You use phrases like "Have you considered...", "What if...", 
and "I notice that...". You guide users toward their own realizations rather than giving direct advice.""",
        "created_at": datetime.utcnow(),
        "is_active": True
    },
    {
        "personality_id": "PERS005",
        "personality_name": "Playful",
        "description": "Lighthearted, humorous, and fun. Great for lifting spirits.",
        "prompt_modifier": """With a PLAYFUL personality. Your communication style is lighthearted, warm, and gently humorous. 
You help users see the lighter side of things without dismissing their feelings. You use appropriate humor to lift spirits. 
You're energetic but sensitive to the user's emotional state. You use phrases like "Let's look at the bright side", 
"Here's a fun way to think about it", while still being supportive and caring. You know when to be serious and when to add levity.""",
        "created_at": datetime.utcnow(),
        "is_active": True
    }
]

print("Inserting personalities...")
db.personalities.insert_many(personalities)
print(f"✓ Inserted {len(personalities)} personalities")

# Sample AI Companions
companions = [
    {
        "companion_id": "COMP001",
        "personality_id": "PERS001",
        "companion_name": "Luna",
        "description": "Luna is a gentle and understanding companion who provides emotional support and validation. She's always ready to listen with compassion.",
        "image": "luna.jpg",
        "created_at": datetime.utcnow(),
        "is_default": True,
        "is_active": True,
        "voice_tone": "warm"
    },
    {
        "companion_id": "COMP002",
        "personality_id": "PERS002",
        "companion_name": "Atlas",
        "description": "Atlas is an encouraging companion who helps you recognize your strengths and build confidence. He's your cheerleader in challenging times.",
        "image": "atlas.jpg",
        "created_at": datetime.utcnow(),
        "is_default": False,
        "is_active": True,
        "voice_tone": "energetic"
    },
    {
        "companion_id": "COMP003",
        "personality_id": "PERS003",
        "companion_name": "River",
        "description": "River is a calming presence who helps you find peace and tranquility. Perfect for when you need to relax and center yourself.",
        "image": "river.jpg",
        "created_at": datetime.utcnow(),
        "is_default": False,
        "is_active": True,
        "voice_tone": "soft"
    },
    {
        "companion_id": "COMP004",
        "personality_id": "PERS004",
        "companion_name": "Sage",
        "description": "Sage is a thoughtful companion who guides you through self-reflection and personal growth. She asks the right questions to help you understand yourself better.",
        "image": "sage.jpg",
        "created_at": datetime.utcnow(),
        "is_default": False,
        "is_active": True,
        "voice_tone": "gentle"
    },
    {
        "companion_id": "COMP005",
        "personality_id": "PERS005",
        "companion_name": "Sunny",
        "description": "Sunny is a cheerful companion who brings lightness and joy to conversations. She helps you find humor and positivity while being supportive.",
        "image": "sunny.jpg",
        "created_at": datetime.utcnow(),
        "is_default": False,
        "is_active": True,
        "voice_tone": "cheerful"
    }
]

print("Inserting companions...")
db.ai_companions.insert_many(companions)
print(f"✓ Inserted {len(companions)} companions")

# Create indexes
print("Creating database indexes...")
try:
    db.chat_sessions.create_index("session_id", unique=True)
    db.chat_sessions.create_index("user_id")
    db.chat_sessions.create_index([("user_id", 1), ("start_time", -1)])
    
    db.chat_messages.create_index("message_id", unique=True)
    db.chat_messages.create_index("session_id", unique=True)
    
    db.ai_companions.create_index("companion_id", unique=True)
    db.ai_companions.create_index("is_active")
    
    db.personalities.create_index("personality_id", unique=True)
    db.personalities.create_index("is_active")
    
    print("✓ Created database indexes")
except Exception as e:
    print(f"⚠ Warning: Some indexes may already exist - {str(e)}")

print("\n" + "="*50)
print("🎉 Database seeding completed successfully!")
print("="*50)
print("\nSeeded data summary:")
print(f"  • {len(personalities)} Personalities")
print(f"  • {len(companions)} AI Companions")
print("\nAvailable Companions:")
for comp in companions:
    default_badge = " (Default)" if comp["is_default"] else ""
    print(f"  • {comp['companion_name']}{default_badge} - {comp['description'][:60]}...")

print("\nYou can now start the FastAPI server and begin testing!")
print("Run: python app/main.py")
print("Or: uvicorn app.main:app --reload")
print("\nAPI Documentation will be available at: http://localhost:8000/docs")

# Close connection
client.close()
