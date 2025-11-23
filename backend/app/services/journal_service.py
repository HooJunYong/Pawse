import random
from datetime import datetime
from typing import List, Optional
from pymongo.database import Database
from bson import ObjectId

from ..models.journal_schemas import JournalEntryCreate, JournalEntryUpdate, PromptType


class JournalService:
    def __init__(self, db: Database):
        self.db = db
        self.collection = db["journal_entry"]
        self.prompts_collection = db["journal_prompts"]
        self.daily_prompt_collection = db["daily_prompt"]
        self._initialize_prompts()

    def _initialize_prompts(self):
        # List of all prompts to be saved in the database
        prompts = [
            {"prompt": "What is something that brought you a moment of peace today, and how did it feel?"},
            {"prompt": "What is one thing you did today that you’re proud of, no matter how small?"},
            {"prompt": "What helped you feel calm or grounded today?"},
            {"prompt": "What is one act of kindness you noticed or received recently?"},
            {"prompt": "What emotion stood out to you today, and what might have caused it?"},
            {"prompt": "What is one thing your mind or body needs right now?"},
            {"prompt": "What is something you learned about yourself this week?"},
            {"prompt": "What is a moment today when you felt safe or supported?"},
            {"prompt": "What helped you get through a difficult moment today?"},
            {"prompt": "What is one thing you’re looking forward to, even if it’s small?"},
            {"prompt": "What is a gentle reminder you need to hear today?"},
            {"prompt": "What is something you did to care for yourself recently?"},
            {"prompt": "What is one thought you can replace with a kinder one?"},
            {"prompt": "What is something in your environment that brings you comfort?"},
            {"prompt": "What part of your routine helps your mental well-being?"},
            {"prompt": "What is one thing you can let go of right now?"},
            {"prompt": "What is a memory that makes you feel warm or safe?"},
            {"prompt": "What is something you appreciate about yourself today?"},
            {"prompt": "What helped you feel connected to others this week?"},
            {"prompt": "What is one boundary you set that protected your peace?"},
            {"prompt": "What is something that made you smile today?"},
            {"prompt": "What is one challenge you handled better than you expected?"},
            {"prompt": "What is something you can celebrate about your progress?"},
            {"prompt": "What is one comforting thought you can hold onto right now?"},
            {"prompt": "What is something that inspired you recently?"},
            {"prompt": "What is a small step you took today toward healing or growth?"},
            {"prompt": "What made you feel hopeful today?"},
            {"prompt": "What is one need you want to honor tomorrow?"},
            {"prompt": "What is something that helped you feel balanced today?"},
            {"prompt": "What is one thing that reminds you you’re doing your best?"},
            {"prompt": "What is something you can simplify in your life right now?"},
            {"prompt": "What is a moment today when you felt present?"},
            {"prompt": "What is one thing that helped you breathe a little easier today?"},
            {"prompt": "What is a strength you used today, even if you didn’t notice at first?"},
            {"prompt": "What is something you appreciate about the person you’re becoming?"},
        ]
        # Insert prompts if collection is empty
        if self.prompts_collection.count_documents({}) == 0:
            self.prompts_collection.insert_many(prompts)

    def get_daily_prompt(self, last_prompt: Optional[str] = None) -> dict:
        """Get a new random prompt every time (no daily persistence), avoid repeating last prompt if possible"""
        prompts = list(self.prompts_collection.find({}))
        if not prompts:
            return {"prompt": "No prompts available.", "prompt_type": "daily"}
        if last_prompt and len(prompts) > 1:
            filtered = [p for p in prompts if p["prompt"] != last_prompt]
            if filtered:
                prompt_doc = random.choice(filtered)
            else:
                prompt_doc = random.choice(prompts)
        else:
            prompt_doc = random.choice(prompts)
        return {"prompt": prompt_doc["prompt"], "prompt_type": "daily"}
    
    # Deprecated: use get_daily_prompt instead
    def get_random_prompt(self) -> dict:
        return self.get_daily_prompt()
    
    def create_entry(self, user_id: str, entry_data: JournalEntryCreate) -> dict:
        """Create a new journal entry, recording the day's prompt and created time"""
        # Get today's prompt
        today = datetime.now().strftime("%Y-%m-%d")
        daily = self.daily_prompt_collection.find_one({"date": today})
        prompt_text = daily["prompt"] if daily else None
        entry = {
            "user_id": user_id,
            "title": entry_data.title,
            "content": entry_data.content,
            "prompt_type": entry_data.prompt_type,
            "prompt": prompt_text,
            "emotional_tags": entry_data.emotional_tags or [],
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }
        result = self.collection.insert_one(entry)
        entry["entry_id"] = str(result.inserted_id)
        entry["_id"] = result.inserted_id
        
        # After saving, delete today's prompt so a new one will be generated on next request
        self.daily_prompt_collection.delete_one({"date": today})
        
        return entry
    
    def get_entry(self, entry_id: str, user_id: str) -> Optional[dict]:
        """Get a specific journal entry"""
        try:
            entry = self.collection.find_one({
                "_id": ObjectId(entry_id),
                "user_id": user_id
            })
            
            if entry:
                entry["entry_id"] = str(entry["_id"])
                return entry
            return None
        except Exception:
            return None
    
    def get_user_entries(self, user_id: str, limit: int = 50, skip: int = 0) -> List[dict]:
        """Get all journal entries for a user"""
        entries = list(
            self.collection.find({"user_id": user_id})
            .sort("created_at", -1)
            .skip(skip)
            .limit(limit)
        )
        
        for entry in entries:
            entry["entry_id"] = str(entry["_id"])
        
        return entries
    
    def update_entry(self, entry_id: str, user_id: str, entry_data: JournalEntryUpdate) -> Optional[dict]:
        """Update a journal entry"""
        try:
            update_data = {k: v for k, v in entry_data.dict(exclude_unset=True).items() if v is not None}
            
            if not update_data:
                return None
            
            update_data["updated_at"] = datetime.now()
            
            result = self.collection.find_one_and_update(
                {"_id": ObjectId(entry_id), "user_id": user_id},
                {"$set": update_data},
                return_document=True
            )
            
            if result:
                result["entry_id"] = str(result["_id"])
                return result
            return None
        except Exception:
            return None
    
    def delete_entry(self, entry_id: str, user_id: str) -> bool:
        """Delete a journal entry"""
        try:
            result = self.collection.delete_one({
                "_id": ObjectId(entry_id),
                "user_id": user_id
            })
            return result.deleted_count > 0
        except Exception:
            return False
