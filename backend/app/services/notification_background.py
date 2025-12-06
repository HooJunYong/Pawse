"""
Background Tasks for Notification Scheduler
Runs periodic checks for scheduled notifications
"""
import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)

class NotificationBackgroundTask:
    def __init__(self):
        self.task = None
        self.running = False
    
    async def check_notifications(self):
        """Periodic task that checks and sends scheduled notifications"""
        from app.services.notification_scheduler import process_scheduled_notifications
        
        while self.running:
            try:
                # Process all scheduled notifications
                process_scheduled_notifications()
            except Exception as e:
                logger.error(f"Error in notification scheduler: {e}")
            
            # Wait 60 seconds before checking again
            await asyncio.sleep(60)
    
    async def start(self):
        """Start the background task"""
        if not self.running:
            self.running = True
            self.task = asyncio.create_task(self.check_notifications())
            logger.info("Notification scheduler started")
    
    async def stop(self):
        """Stop the background task"""
        self.running = False
        if self.task:
            self.task.cancel()
            try:
                await self.task
            except asyncio.CancelledError:
                pass
            logger.info("Notification scheduler stopped")

# Global instance
notification_task = NotificationBackgroundTask()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """FastAPI lifespan context manager"""
    # Startup
    await notification_task.start()
    yield
    # Shutdown
    await notification_task.stop()
