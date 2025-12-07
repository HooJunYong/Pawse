from app.models.database import db
from app.models.notification_schemas import NotificationSettings, UpdateNotificationSettingsRequest, Notification
from app.config.timezone import now_my
from typing import Optional
import uuid

def get_notification_settings(user_id: str) -> NotificationSettings:
    settings = db.notification_settings.find_one({"user_id": user_id})
    if settings:
        return NotificationSettings(**settings)
    
    # Create default settings if not found
    new_settings = NotificationSettings(user_id=user_id)
    db.notification_settings.insert_one(new_settings.dict())
    return new_settings

def update_notification_settings(user_id: str, settings: UpdateNotificationSettingsRequest) -> NotificationSettings:
    update_data = {k: v for k, v in settings.dict().items() if v is not None}
    
    if not update_data:
        return get_notification_settings(user_id)
        
    db.notification_settings.update_one(
        {"user_id": user_id},
        {"$set": update_data},
        upsert=True
    )
    
    return get_notification_settings(user_id)

def create_notification(user_id: str, type: str, title: str, body: str, data: Optional[dict] = None):
    """Create a notification if user has enabled notifications"""
    settings = get_notification_settings(user_id)
    
    # Check global switch
    if not settings.all_notifications_enabled:
        return None
        
    # Check specific switches based on type
    if type == 'message' and not settings.intelligent_nudges: # Assuming messages fall under nudges or general
        pass # For now, let's assume messages are important unless global is off
    elif type == 'booking_update' and not settings.therapy_sessions:
        return None
        
    notification = Notification(
        notification_id=str(uuid.uuid4()),
        user_id=user_id,
        type=type,
        title=title,
        body=body,
        created_at=now_my().isoformat(),
        data=data
    )
    
    db.notifications.insert_one(notification.dict())
    return notification

def get_user_notifications(user_id: str):
    notifications = list(db.notifications.find({"user_id": user_id}).sort("created_at", -1))
    return notifications

def mark_notification_read(notification_id: str):
    db.notifications.update_one(
        {"notification_id": notification_id},
        {"$set": {"is_read": True}}
    )
