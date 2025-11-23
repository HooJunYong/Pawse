from fastapi import APIRouter, HTTPException, Depends
from typing import List

from ..models.database import db
from ..models.journal_schemas import (
    JournalEntryCreate,
    JournalEntryUpdate,
    JournalEntryResponse,
    PromptResponse
)
from ..services.journal_service import JournalService

router = APIRouter(prefix="/journal", tags=["journal"])


def get_journal_service():
    return JournalService(db)


@router.get("/prompt", response_model=PromptResponse)
async def get_daily_prompt(service: JournalService = Depends(get_journal_service)):
    """Get a random mental health journaling prompt"""
    try:
        prompt_data = service.get_random_prompt()
        return prompt_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting prompt: {str(e)}")


@router.post("/entry/{user_id}", response_model=JournalEntryResponse)
async def create_journal_entry(
    user_id: str,
    entry_data: JournalEntryCreate,
    service: JournalService = Depends(get_journal_service)
):
    """Create a new journal entry"""
    try:
        entry = service.create_entry(user_id, entry_data)
        return entry
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating entry: {str(e)}")


@router.get("/entries/{user_id}", response_model=List[JournalEntryResponse])
async def get_user_entries(
    user_id: str,
    limit: int = 50,
    skip: int = 0,
    service: JournalService = Depends(get_journal_service)
):
    """Get all journal entries for a user"""
    try:
        entries = service.get_user_entries(user_id, limit, skip)
        return entries
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting entries: {str(e)}")


@router.get("/entry/{entry_id}/{user_id}", response_model=JournalEntryResponse)
async def get_journal_entry(
    entry_id: str,
    user_id: str,
    service: JournalService = Depends(get_journal_service)
):
    """Get a specific journal entry"""
    try:
        entry = service.get_entry(entry_id, user_id)
        if not entry:
            raise HTTPException(status_code=404, detail="Journal entry not found")
        return entry
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting entry: {str(e)}")


@router.put("/entry/{entry_id}/{user_id}", response_model=JournalEntryResponse)
async def update_journal_entry(
    entry_id: str,
    user_id: str,
    entry_data: JournalEntryUpdate,
    service: JournalService = Depends(get_journal_service)
):
    """Update a journal entry"""
    try:
        entry = service.update_entry(entry_id, user_id, entry_data)
        if not entry:
            raise HTTPException(status_code=404, detail="Journal entry not found")
        return entry
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating entry: {str(e)}")


@router.delete("/entry/{entry_id}/{user_id}")
async def delete_journal_entry(
    entry_id: str,
    user_id: str,
    service: JournalService = Depends(get_journal_service)
):
    """Delete a journal entry"""
    try:
        success = service.delete_entry(entry_id, user_id)
        if not success:
            raise HTTPException(status_code=404, detail="Journal entry not found")
        return {"message": "Journal entry deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting entry: {str(e)}")
