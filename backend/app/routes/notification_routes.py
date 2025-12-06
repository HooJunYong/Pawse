from fastapi import APIRouter, HTTPException
from app.models.notification_schemas import NotificationSettings, UpdateNotificationSettingsRequest
from app.services import notification_service

router = APIRouter()

@router.get("/notifications/settings/{user_id}", response_model=NotificationSettings)
def get_settings(user_id: str):
    return notification_service.get_notification_settings(user_id)

@router.put("/notifications/settings/{user_id}", response_model=NotificationSettings)
def update_settings(user_id: str, settings: UpdateNotificationSettingsRequest):
    return notification_service.update_notification_settings(user_id, settings)
