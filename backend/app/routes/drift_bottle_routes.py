from fastapi import APIRouter, HTTPException
from typing import List, Dict, Any
from pydantic import BaseModel
import logging

from app.models.drift_bottle import DriftBottleResponse
from app.models.bottle_pickup import BottlePickupResponse
from app.models.bottle_reply import BottleReplyResponse
from app.services.drift_bottle_service import DriftBottleService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/drift-bottles", tags=["Drift Bottles"])


# ==================== Request Models ====================

class ThrowBottleRequest(BaseModel):
    """Request model for throwing a bottle"""
    user_id: str
    message: str


class PassBottleRequest(BaseModel):
    """Request model for passing a bottle"""
    user_id: str
    bottle_id: str


class ReplyBottleRequest(BaseModel):
    """Request model for replying to a bottle"""
    user_id: str
    bottle_id: str
    reply_content: str


class EndBottleRequest(BaseModel):
    """Request model for ending a bottle"""
    user_id: str
    bottle_id: str


# ==================== Routes ====================

@router.post("/throw", response_model=DriftBottleResponse)
async def throw_bottle(request: ThrowBottleRequest):
    """
    Throw a new drift bottle into the ocean
    
    - **user_id**: The user who is throwing the bottle
    - **message**: The message content in the bottle
    
    Returns the created bottle
    """
    try:
        bottle = DriftBottleService.throw_bottle(
            user_id=request.user_id,
            message=request.message
        )
        return bottle
    except Exception as e:
        logger.error(f"Error throwing bottle: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to throw bottle: {str(e)}")


@router.post("/pickup", response_model=DriftBottleResponse)
async def pickup_bottle(user_id: str):
    """
    Pick up a random available bottle from the ocean
    
    - **user_id**: The user who is picking up the bottle
    
    Returns the picked up bottle or 404 if no bottle available
    """
    try:
        bottle = DriftBottleService.pickup_bottle(user_id=user_id)
        
        if not bottle:
            raise HTTPException(
                status_code=404,
                detail="No bottles available in the ocean right now. Try again later!"
            )
        
        return bottle
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error picking up bottle: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to pick up bottle: {str(e)}")


@router.post("/pass")
async def pass_bottle(request: PassBottleRequest):
    """
    Pass a bottle back into the ocean without replying
    
    - **user_id**: The user who is passing the bottle
    - **bottle_id**: The bottle to pass
    
    Returns success message
    """
    try:
        DriftBottleService.pass_bottle(
            user_id=request.user_id,
            bottle_id=request.bottle_id
        )
        return {"message": "Bottle passed back into the ocean"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error passing bottle: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to pass bottle: {str(e)}")


@router.post("/reply", response_model=BottleReplyResponse)
async def reply_to_bottle(request: ReplyBottleRequest):
    """
    Reply to a bottle
    
    - **user_id**: The user who is replying
    - **bottle_id**: The bottle to reply to
    - **reply_content**: The reply message content
    
    Returns the created reply
    """
    try:
        reply = DriftBottleService.reply_to_bottle(
            user_id=request.user_id,
            bottle_id=request.bottle_id,
            reply_content=request.reply_content
        )
        return reply
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error replying to bottle: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to reply to bottle: {str(e)}")


@router.get("/thrown/{user_id}", response_model=List[DriftBottleResponse])
async def get_thrown_history(user_id: str):
    """
    Get all bottles that the user has thrown
    
    - **user_id**: The user ID
    
    Returns list of bottles thrown by the user
    """
    try:
        bottles = DriftBottleService.get_thrown_history(user_id=user_id)
        return bottles
    except Exception as e:
        logger.error(f"Error getting thrown history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get thrown history: {str(e)}")


@router.get("/pickup-history/{user_id}")
async def get_pickup_history(user_id: str):
    """
    Get all bottles that the user has picked up
    
    - **user_id**: The user ID
    
    Returns list of pickup records with bottle details
    """
    try:
        history = DriftBottleService.get_pickup_history(user_id=user_id)
        return history
    except Exception as e:
        logger.error(f"Error getting pickup history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get pickup history: {str(e)}")


@router.get("/detail/{bottle_id}")
async def get_bottle_detail(bottle_id: str):
    """
    Get bottle message and all replies
    
    - **bottle_id**: The bottle ID
    
    Returns bottle details with message and replies
    """
    try:
        detail = DriftBottleService.get_bottle_detail(bottle_id=bottle_id)
        
        if not detail:
            raise HTTPException(status_code=404, detail=f"Bottle not found: {bottle_id}")
        
        return detail
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting bottle detail: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to get bottle detail: {str(e)}")


@router.post("/end")
async def end_bottle(request: EndBottleRequest):
    """
    Manually end a bottle (only the owner can do this)
    
    - **user_id**: The user who is ending the bottle
    - **bottle_id**: The bottle to end
    
    Returns success message
    """
    try:
        DriftBottleService.end_bottle(
            user_id=request.user_id,
            bottle_id=request.bottle_id
        )
        return {"message": "Bottle ended successfully"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error ending bottle: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to end bottle: {str(e)}")


# ==================== Admin/Maintenance Routes ====================

@router.post("/admin/check-stuck")
async def check_stuck_bottles():
    """
    Check for bottles that have been pending for more than 24 hours
    and release them back to the ocean
    
    Returns number of bottles released
    """
    try:
        count = DriftBottleService.check_stuck_bottles()
        return {"message": f"Released {count} stuck bottles back to the ocean"}
    except Exception as e:
        logger.error(f"Error checking stuck bottles: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to check stuck bottles: {str(e)}")


@router.post("/admin/expire-old")
async def expire_old_bottles():
    """
    Expire bottles that have been in the ocean for more than 14 days
    
    Returns number of bottles expired
    """
    try:
        count = DriftBottleService.expire_old_bottles()
        return {"message": f"Expired {count} old bottles"}
    except Exception as e:
        logger.error(f"Error expiring old bottles: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to expire old bottles: {str(e)}")
