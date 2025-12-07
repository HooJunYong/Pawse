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
            {"prompt": "What is something that brought you comfort today?"},
            {"prompt": "What helped you feel grounded when things felt overwhelming?"},
            {"prompt": "What is one moment you felt genuinely yourself today?"},
            {"prompt": "What peaceful thought can you hold onto right now?"},
            {"prompt": "What is something in your life that feels stable or reliable?"},
            {"prompt": "What is a small joy you experienced recently?"},
            {"prompt": "What is one thing your heart needs to hear today?"},
            {"prompt": "What helped you stay present in a stressful moment?"},
            {"prompt": "What is something you can forgive yourself for today?"},
            {"prompt": "What is one thing you’re glad you didn’t give up on?"},
            {"prompt": "What is something that made you feel connected to the world around you?"},
            {"prompt": "What is a small step you took toward healing this week?"},
            {"prompt": "What is one thing that reminded you of your strength recently?"},
            {"prompt": "What is a moment of calm you can recreate when needed?"},
            {"prompt": "What is something you’re learning to accept about yourself?"},
            {"prompt": "What part of your day made you feel at ease?"},
            {"prompt": "What is one thing you can be gentle with yourself about?"},
            {"prompt": "What is something that restored your hope today?"},
            {"prompt": "What is one thing that made you feel appreciated?"},
            {"prompt": "What healthy boundary supported your well-being recently?"},
            {"prompt": "What is something that made you feel supported or understood?"},
            {"prompt": "What is a small improvement you noticed in yourself?"},
            {"prompt": "What moment reminded you to slow down today?"},
            {"prompt": "What is something that made you feel valued this week?"},
            {"prompt": "What is one thing that helped lighten your mood today?"},
            {"prompt": "What is something you’re grateful to have learned over time?"},
            {"prompt": "What moment brought you clarity today?"},
            {"prompt": "What is something you handled better than you expected?"},
            {"prompt": "What is one thing you want to celebrate about yourself?"},
            {"prompt": "What is something that made you feel anchored during uncertainty?"},
            {"prompt": "What is one thing that reminded you you’re not alone?"},
            {"prompt": "What is a moment when you felt proud of your resilience?"},
            {"prompt": "What is one thing you chose today that supported your well-being?"},
            {"prompt": "What is something that softened your stress today?"},
            {"prompt": "What is one moment that brought you peace this week?"},
            {"prompt": "What is something that made you feel hopeful about the future?"},
            {"prompt": "What calming activity would benefit you right now?"},
            {"prompt": "What is one thing you’re grateful your past self pushed through?"},
            {"prompt": "What is something you can let go of to create space for growth?"},
            {"prompt": "What is a gentle truth about yourself that you can acknowledge today?"},
            {"prompt": "What is something that reminded you of your worth?"},
            {"prompt": "What is one moment of kindness you offered someone recently?"},
            {"prompt": "What is something you enjoyed without judgment today?"},
            {"prompt": "What helped you feel more balanced this week?"},
            {"prompt": "What is one thing you’re learning to trust in yourself?"},
            {"prompt": "What is a moment when you felt calm in your body?"},
            {"prompt": "What is something you can appreciate about your journey so far?"},
            {"prompt": "What is a meaningful moment that lifted your spirits today?"},
            {"prompt": "What is one thing that helped you breathe a little deeper today?"},
            {"prompt": "What is something you can thank yourself for right now?"},
        ]
        # Insert prompts if collection is empty
        if self.prompts_collection.count_documents({}) == 0:
            self.prompts_collection.insert_many(prompts)
            print(f"Inserted {len(prompts)} prompts into journal_prompts collection.")
        else:
            print(f"journal_prompts collection already has {self.prompts_collection.count_documents({})} prompts. No insertion performed.")

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
