"""
Mood Nudge Service
Manages mood-based intelligent nudge prompts stored in database
"""
from app.models.database import db
from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

class MoodNudgeService:
    """Service for managing mood nudge prompts"""
    
    # Mood nudge prompts organized by mood type
    MOOD_NUDGES = {
        "very_happy": [
            {"title": "Anchor the Moment", "message": "You're glowing! 📸 Take a quick photo or write down one sentence about what made today great so you can revisit this feeling later.", "action": "open_journal"},
            {"title": "Share the Joy", "message": "Happiness multiplies when shared. Send a text to a friend or family member just to say hello or tell them good news.", "action": "share"},
            {"title": "Tackle the 'Big' Task", "message": "Your energy is high right now. Is there a daunting task you've been putting off? You have the power to crush it today.", "action": "task"},
            {"title": "Future You Will Thank You", "message": "Ride this wave! 🌊 Do one small favor for your future self, like prepping tomorrow's breakfast or organizing your workspace.", "action": "task"},
            {"title": "Gratitude Deep Dive", "message": "It's a great day. Who helped you get here? Consider sending a quick 'thank you' note to someone who supports you.", "action": "gratitude"},
            {"title": "Physical Celebration", "message": "Your body feels the joy, too. Put on your favorite upbeat track and move for 5 minutes—dance, run, or stretch!", "action": "exercise"},
            {"title": "Creative Spark", "message": "High mood often brings high creativity. Spend 10 minutes brainstorming ideas or working on a passion project.", "action": "creative"},
            {"title": "The 'Save' Button", "message": "Curate a 'Happy Playlist' right now while you feel this way. It will be a great tool to boost your mood on slower days.", "action": "open_music"},
            {"title": "Spread the Wealth", "message": "Feeling generous? Leave a nice review for a local business or give a genuine compliment to a stranger.", "action": "kindness"},
            {"title": "Reflect on the 'Why'", "message": "Pause for a second. What specific trigger caused this mood? Identify it so you can recreate it later.", "action": "open_journal"}
        ],
        "happy": [
            {"title": "Savor the Calm", "message": "Things are going well. Take a deep breath and just enjoy the absence of stress for a moment.", "action": "open_breathing"},
            {"title": "Walk and Talk", "message": "Great day for a stroll. If you can, take a 10-minute walk outside to get some fresh air and Vitamin D.", "action": "walk"},
            {"title": "Hydration Check", "message": "Keep the good vibes flowing. Have you had a glass of water recently? 💧", "action": "hydration"},
            {"title": "Learning Mode", "message": "A clear mind is ready to learn. Read one article or listen to a podcast episode on a topic you're curious about.", "action": "learn"},
            {"title": "Gentle Tidy", "message": "Clear space, clear mind. Spend 5 minutes tidying up your immediate surroundings to keep the momentum going.", "action": "tidy"},
            {"title": "Cook Something Fresh", "message": "Why not treat yourself to a healthy, colorful meal today? Cooking can be a great meditation when you're in a good mood.", "action": "cook"},
            {"title": "Goal Review", "message": "You're in a good headspace. Take a look at your weekly goals—are you on track? Adjust as needed without pressure.", "action": "goals"},
            {"title": "Connect", "message": "Call someone you haven't spoken to in a while, just to catch up. No agenda, just connection.", "action": "connect"},
            {"title": "Mindful Pause", "message": "Look away from the screen. Find 3 things in the room you find beautiful or interesting.", "action": "mindful"},
            {"title": "Digital Detox", "message": "You're feeling good—you don't need the scroll. Try putting your phone down for an hour this evening.", "action": "detox"}
        ],
        "neutral": [
            {"title": "The Body Scan", "message": "Feeling 'meh'? Do a quick body scan. Are your shoulders tense? Is your jaw clenched? Relax them.", "action": "open_breathing"},
            {"title": "Change of Scenery", "message": "Stagnation check. Stand up and move to a different room, or look out a window for 60 seconds.", "action": "move"},
            {"title": "Micro-Adventure", "message": "Routine can feel flat. Try a different coffee order, a new route home, or listen to a genre of music you rarely play.", "action": "open_music"},
            {"title": "Intention Setting", "message": "Let's give the next hour a purpose. Pick one single thing you want to accomplish, no matter how small.", "action": "intention"},
            {"title": "Sensory Wake-Up", "message": "Wake up your senses. Splash cold water on your face or smell something strong (like coffee or citrus).", "action": "sensory"},
            {"title": "Stretch it Out", "message": "Motion creates emotion. Do a 2-minute stretch routine to get the blood flowing.", "action": "open_breathing"},
            {"title": "The 5-Minute Rule", "message": "Bored? Commit to doing a task for just 5 minutes. If you still hate it, you can stop. Usually, you won't want to.", "action": "task"},
            {"title": "Doodle or Write", "message": "Brain dump. Write down whatever is in your head, even if it's 'I don't know what to write.' It clears the static.", "action": "open_journal"},
            {"title": "Declutter Your Phone", "message": "Neutral time is great for admin. Delete 5 old screenshots or unsubscribe from 3 junk emails.", "action": "declutter"},
            {"title": "Just Breathe", "message": "Try the 4-7-8 breathing technique. Inhale for 4, hold for 7, exhale for 8. It resets the nervous system.", "action": "open_breathing"}
        ],
        "sad": [
            {"title": "Permission to Feel", "message": "It's okay to feel this way. You don't need to 'fix' it right this second. Just be.", "action": "open_journal"},
            {"title": "Comfort Mode", "message": "Wrap yourself in a blanket, put on comfy socks, or make a warm drink. Soothe your physical self first.", "action": "comfort"},
            {"title": "Low-Fi Distraction", "message": "Sometimes we need a break from our thoughts. Watch a comfort movie or read a book you already know and love.", "action": "distract"},
            {"title": "Nature's Hug", "message": "If you can manage it, step outside. Even sitting on a balcony or doorstep for fresh air can help shift perspective.", "action": "nature"},
            {"title": "Journal the Heavy", "message": "Get it out of your head. Write down what's hurting. You can tear the paper up afterwards if you want.", "action": "open_journal"},
            {"title": "Cancel the Noise", "message": "Overwhelmed? It's okay to say no to plans today. Protect your energy.", "action": "boundary"},
            {"title": "Water Therapy", "message": "A warm shower or bath can wash away some of the physical weight of sadness.", "action": "bath"},
            {"title": "Gentle Movement", "message": "No workouts today. Just a slow, gentle walk or some yoga stretches to release tension.", "action": "open_breathing"},
            {"title": "Reach Out (Low Stakes)", "message": "Send a text to a safe friend saying, 'I'm having a rough day.' You don't have to talk, just let them know.", "action": "connect"},
            {"title": "Sleep Reset", "message": "Everything feels harder when you're tired. If you can, take a 20-minute nap to reset your brain.", "action": "rest"}
        ],
        "awful": [
            {"title": "5-4-3-2-1 Grounding", "message": "Let's come back to the present. Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, and 1 you taste.", "action": "grounding"},
            {"title": "Box Breathing", "message": "Focus only on your breath. Inhale 4 seconds, hold 4, exhale 4, hold 4. Repeat until your heart rate slows.", "action": "open_breathing"},
            {"title": "Disconnect", "message": "The world is too loud right now. Put your phone on 'Do Not Disturb' for 30 minutes. The notifications can wait.", "action": "disconnect"},
            {"title": "Temperature Shock", "message": "Need to snap out of a spiral? Hold an ice cube in your hand or splash freezing water on your face. It resets the vagus nerve.", "action": "temperature"},
            {"title": "One Small Step", "message": "Don't look at the whole mountain. Just look at your feet. What is the one tiny thing you can do next? (e.g., sit up).", "action": "tiny_step"},
            {"title": "Visual Release", "message": "Close your eyes. Visualize your stress as a heavy cloud, and watch it slowly drift away with the wind.", "action": "visualize"},
            {"title": "Support Signal", "message": "You don't have to do this alone. Call a helpline or your emergency contact. Just hearing a voice can help.", "action": "call_support"},
            {"title": "Environment Check", "message": "Is it too bright? Too messy? Too loud? Move to a quieter, darker corner or put on noise-canceling headphones.", "action": "environment"},
            {"title": "Hydrate to Regulate", "message": "Stress dehydrates us. Drink a full glass of water slowly. Count the swallows.", "action": "hydration"},
            {"title": "This is Temporary", "message": "Remember: Feelings are weather, not the sky. The storm is heavy right now, but it will eventually pass. Just hold on.", "action": "hope"}
        ]
    }
    
    @staticmethod
    def initialize_nudges():
        """Initialize mood nudges in database if not already present"""
        try:
            for mood, nudges in MoodNudgeService.MOOD_NUDGES.items():
                existing = db.mood_nudges.find_one({"mood": mood})
                if not existing:
                    db.mood_nudges.insert_one({
                        "mood": mood,
                        "nudges": nudges
                    })
                    logger.info(f"Initialized {len(nudges)} nudges for mood: {mood}")
                else:
                    # Update existing with new nudges
                    db.mood_nudges.update_one(
                        {"mood": mood},
                        {"$set": {"nudges": nudges}}
                    )
                    logger.info(f"Updated {len(nudges)} nudges for mood: {mood}")
            return True
        except Exception as e:
            logger.error(f"Error initializing mood nudges: {e}")
            return False
    
    @staticmethod
    def get_nudges_for_mood(mood: str) -> List[Dict]:
        """Get all nudges for a specific mood"""
        try:
            result = db.mood_nudges.find_one({"mood": mood})
            if result and "nudges" in result:
                return result["nudges"]
            return []
        except Exception as e:
            logger.error(f"Error fetching nudges for mood {mood}: {e}")
            return []
    
    @staticmethod
    def get_random_nudge_for_mood(mood: str) -> Dict:
        """Get a random nudge for a specific mood"""
        import random
        nudges = MoodNudgeService.get_nudges_for_mood(mood)
        if nudges:
            return random.choice(nudges)
        return {
            "title": "Check In",
            "message": "Take a moment to notice how you're feeling. You matter.",
            "action": "open_journal"
        }

# Initialize nudges on module load
def init_mood_nudges():
    """Initialize mood nudges in database"""
    return MoodNudgeService.initialize_nudges()
