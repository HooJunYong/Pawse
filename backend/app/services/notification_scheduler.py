"""
Notification Scheduler Service
Handles scheduled notifications for journaling, hydration, breathing reminders, and therapy sessions
"""
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from app.models.database import db
from app.config.timezone import now_my
from app.services.notification_service import create_notification
import logging

logger = logging.getLogger(__name__)

class NotificationScheduler:
    """Manages scheduled notifications based on user settings"""
    
    @staticmethod
    def get_pending_notifications(user_id: str) -> List[Dict]:
        """Get all pending notifications that should be sent now"""
        settings = db.notification_settings.find_one({"user_id": user_id})
        if not settings or not settings.get('all_notifications_enabled', True):
            return []
        
        current_time = now_my()
        current_hour = current_time.hour
        current_minute = current_time.minute
        
        notifications = []
        
        # Check Journaling Routine
        if settings.get('journaling_routine_enabled', False):
            journaling_time = settings.get('journaling_time', '20:00')
            j_hour, j_minute = map(int, journaling_time.split(':'))
            
            if current_hour == j_hour and current_minute == j_minute:
                # Check if we already sent today
                if not NotificationScheduler._was_sent_today(user_id, 'journaling'):
                    notifications.append({
                        'type': 'journaling_reminder',
                        'title': '📝 Time to Journal',
                        'body': 'Take a moment to reflect on your day. How are you feeling?',
                        'data': {'action': 'open_journal'}
                    })
        
        # Check Breathing Practices
        if settings.get('breathing_practices_enabled', False):
            breathing_time = settings.get('breathing_time', '08:00')
            b_hour, b_minute = map(int, breathing_time.split(':'))
            
            if current_hour == b_hour and current_minute == b_minute:
                if not NotificationScheduler._was_sent_today(user_id, 'breathing'):
                    notifications.append({
                        'type': 'breathing_reminder',
                        'title': '🌬️ Breathing Practice',
                        'body': 'Start your day with a calming breathing exercise.',
                        'data': {'action': 'open_breathing'}
                    })
        
        # Check Hydration Reminders
        if settings.get('hydration_reminders_enabled', False):
            interval_minutes = settings.get('hydration_interval_minutes', 120)
            last_sent = NotificationScheduler._get_last_sent_time(user_id, 'hydration')
            
            if last_sent is None or (current_time - last_sent).total_seconds() / 60 >= interval_minutes:
                notifications.append({
                    'type': 'hydration_reminder',
                    'title': '💧 Hydration Reminder',
                    'body': 'Time to drink some water! Stay hydrated, stay healthy.',
                    'data': {'action': 'log_hydration'}
                })
        
        return notifications
    
    @staticmethod
    def _was_sent_today(user_id: str, notification_type: str) -> bool:
        """Check if a notification of this type was already sent today"""
        today_start = now_my().replace(hour=0, minute=0, second=0, microsecond=0)
        
        existing = db.notification_logs.find_one({
            'user_id': user_id,
            'type': notification_type,
            'sent_at': {'$gte': today_start.isoformat()}
        })
        
        return existing is not None
    
    @staticmethod
    def _get_last_sent_time(user_id: str, notification_type: str) -> Optional[datetime]:
        """Get the last time a notification of this type was sent"""
        log = db.notification_logs.find_one(
            {'user_id': user_id, 'type': notification_type},
            sort=[('sent_at', -1)]
        )
        
        if log and 'sent_at' in log:
            return datetime.fromisoformat(log['sent_at'])
        return None
    
    @staticmethod
    def send_notification(user_id: str, notification_data: Dict):
        """Send a notification and log it"""
        from app.services.notification_service import create_notification
        
        # Create the notification
        notification = create_notification(
            user_id=user_id,
            type=notification_data['type'],
            title=notification_data['title'],
            body=notification_data['body'],
            data=notification_data.get('data')
        )
        
        if notification:
            # Log that we sent it
            db.notification_logs.insert_one({
                'user_id': user_id,
                'type': notification_data['type'],
                'notification_id': notification.notification_id,
                'sent_at': now_my().isoformat()
            })
            
            logger.info(f"Sent {notification_data['type']} notification to user {user_id}")
            return notification
        
        return None
    
    @staticmethod
    def process_therapy_session_reminders():
        """Process scheduled therapy session reminders that are due"""
        current_time = now_my()
        
        # Find all pending therapy session reminders that should be sent now
        # Check for reminders scheduled within the last 5 minutes to handle timing variations
        time_window_start = current_time - timedelta(minutes=5)
        
        pending_reminders = db.scheduled_notifications.find({
            "notification_type": "therapy_session_reminder",
            "is_sent": False,
            "scheduled_time": {"$lte": current_time, "$gte": time_window_start}
        })
        
        sent_count = 0
        for reminder in pending_reminders:
            try:
                notification_data = reminder.get("notification_data", {})
                notification = create_notification(
                    user_id=reminder["user_id"],
                    type="therapy_session_reminder",
                    title=notification_data.get("title", "Therapy Session Reminder"),
                    body=notification_data.get("body", "Your therapy session is starting soon."),
                    data=notification_data.get("data")
                )
                
                if notification:
                    # Mark as sent
                    db.scheduled_notifications.update_one(
                        {"notification_id": reminder["notification_id"]},
                        {"$set": {"is_sent": True, "sent_at": current_time}}
                    )
                    sent_count += 1
                    logger.info(f"Sent therapy session reminder to user {reminder['user_id']}")
            except Exception as e:
                logger.error(f"Failed to send therapy reminder {reminder.get('notification_id')}: {e}")
        
        if sent_count > 0:
            logger.info(f"Sent {sent_count} therapy session reminders")
        
        return sent_count
    
    @staticmethod
    def process_scheduled_notifications():
        """Process all scheduled notifications for all users"""
        # First process therapy session reminders
        NotificationScheduler.process_therapy_session_reminders()
        
        # Get all users with notification settings enabled
        settings_cursor = db.notification_settings.find({
            'all_notifications_enabled': True,
            '$or': [
                {'journaling_routine_enabled': True},
                {'breathing_practices_enabled': True},
                {'hydration_reminders_enabled': True}
            ]
        })
        
        sent_count = 0
        for settings in settings_cursor:
            user_id = settings['user_id']
            pending = NotificationScheduler.get_pending_notifications(user_id)
            
            for notification_data in pending:
                NotificationScheduler.send_notification(user_id, notification_data)
                sent_count += 1
        
        if sent_count > 0:
            logger.info(f"Processed {sent_count} scheduled notifications")
        
        return sent_count

# Convenience function for external use
def process_scheduled_notifications():
    """Process all scheduled notifications"""
    return NotificationScheduler.process_scheduled_notifications()

