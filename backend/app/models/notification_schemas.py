from pydantic import BaseModel
from typing import Optional

class NotificationSettings(BaseModel):
    user_id: str
    all_notifications_enabled: bool = True
    intelligent_nudges: bool = True
    therapy_sessions: bool = True
    journaling_routine_enabled: bool = False
    journaling_time: str = "20:00"
    hydration_reminders_enabled: bool = False
    hydration_interval_minutes: int = 120
    breathing_practices_enabled: bool = False
    breathing_time: str = "08:00"

class UpdateNotificationSettingsRequest(BaseModel):
    all_notifications_enabled: Optional[bool] = None
    intelligent_nudges: Optional[bool] = None
    therapy_sessions: Optional[bool] = None
    journaling_routine_enabled: Optional[bool] = None
    journaling_time: Optional[str] = None
    hydration_reminders_enabled: Optional[bool] = None
    hydration_interval_minutes: Optional[int] = None
    breathing_practices_enabled: Optional[bool] = None
    breathing_time: Optional[str] = None

class Notification(BaseModel):
    notification_id: str
    user_id: str
    type: str  # 'message', 'booking_update', 'rating_reminder'
    title: str
    body: str
    is_read: bool = False
    created_at: str
    data: Optional[dict] = None

class NotificationListResponse(BaseModel):
    notifications: list[Notification]
