from fastapi import APIRouter, HTTPException
from app.models.notification_schemas import NotificationSettings, UpdateNotificationSettingsRequest, NotificationListResponse
from app.services import notification_service

router = APIRouter()

@router.get("/notifications/settings/{user_id}", response_model=NotificationSettings)
def get_settings(user_id: str):
    return notification_service.get_notification_settings(user_id)

@router.put("/notifications/settings/{user_id}", response_model=NotificationSettings)
def update_settings(user_id: str, settings: UpdateNotificationSettingsRequest):
    return notification_service.update_notification_settings(user_id, settings)

@router.get("/notifications/{user_id}", response_model=NotificationListResponse)
def get_notifications(user_id: str, limit: int = 50):
    """Get user notifications"""
    notifications = notification_service.get_user_notifications(user_id)
    return NotificationListResponse(notifications=notifications[:limit])

@router.post("/notifications/{notification_id}/read")
def mark_read(notification_id: str):
    """Mark notification as read"""
    notification_service.mark_notification_read(notification_id)
    return {"status": "success"}

@router.post("/notifications/test/{user_id}")
def send_test_notification(user_id: str):
    """Send a test notification (for development)"""
    notification = notification_service.create_notification(
        user_id=user_id,
        type="test",
        title="🔔 Test Notification",
        body="This is a test notification from Pawse!",
        data={"test": True}
    )
    return notification
