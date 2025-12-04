"""
Activity Service
Handles daily activity assignment, tracking, and points/rank management
"""
import logging
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any

from app.models.database import get_database
from app.models.activity import ActivityResponse
from app.models.user_activity import UserActivityResponse, ActivityStatus

logger = logging.getLogger(__name__)


class ActivityService:
    """Service for managing daily activities, points, and ranks"""

    # ==================== Activity Assignment ====================

    @staticmethod
    def has_activities_assigned_today(user_id: str) -> bool:
        """
        Check if user already has activities assigned for today.
        Called every time when user logs in.
        If not assigned, calls assign_daily_activities.
        
        Args:
            user_id: The user ID
            
        Returns:
            True if activities already assigned, False if newly assigned
        """
        db = get_database()
        
        # Get today's date range (start of day to end of day)
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timedelta(days=1)
        
        # Check if any activity exists for today
        count = db.user_activities.count_documents({
            "user_id": user_id,
            "assigned_date": {
                "$gte": today_start,
                "$lt": today_end
            }
        })
        
        if count > 0:
            logger.info(f"User {user_id} already has activities assigned for today")
            return True
        
        # User doesn't have activities for today, assign them
        ActivityService.assign_daily_activities(user_id)
        return False

    @staticmethod
    def assign_daily_activities(user_id: str) -> List[Dict[str, Any]]:
        """
        Assign all activities to user for today.
        Creates new records in user_activities collection.
        
        Args:
            user_id: The user ID
            
        Returns:
            List of assigned user activities
        """
        db = get_database()
        
        # Get all activities from activities collection
        activities = list(db.activities.find({}, {"_id": 0}))
        
        if not activities:
            logger.warning("No activities found in activities collection")
            return []
        
        # Create user_activity records for each activity
        today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        user_activities = []
        
        for activity in activities:
            user_activity = {
                "user_id": user_id,
                "activity_id": activity["activity_id"],
                "assigned_date": today,
                "status": ActivityStatus.PENDING.value,
                "action_key": activity["action_key"],
                "progress": 0,
                "target": activity["target_count"],
                "completion_date": None
            }
            user_activities.append(user_activity)
        
        # Insert all user activities
        if user_activities:
            db.user_activities.insert_many(user_activities)
            logger.info(f"Assigned {len(user_activities)} activities to user {user_id}")
        
        return ActivityService.get_user_daily_activities(user_id)

    @staticmethod
    def get_user_daily_activities(user_id: str) -> List[Dict[str, Any]]:
        """
        Get all user's activities for today with activity details and progress.
        
        Args:
            user_id: The user ID
            
        Returns:
            List of user activities with activity details
        """
        db = get_database()
        
        # Get today's date range
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timedelta(days=1)
        
        # Get user's activities for today
        user_activities = list(db.user_activities.find({
            "user_id": user_id,
            "assigned_date": {
                "$gte": today_start,
                "$lt": today_end
            }
        }, {"_id": 0}))
        
        # Enrich with activity details from activities collection
        result = []
        for ua in user_activities:
            activity = db.activities.find_one(
                {"activity_id": ua["activity_id"]},
                {"_id": 0}
            )
            if activity:
                result.append({
                    "user_id": ua["user_id"],
                    "activity_id": ua["activity_id"],
                    "assigned_date": ua["assigned_date"],
                    "status": ua["status"],
                    "progress": ua["progress"],
                    "target": ua["target"],
                    "completion_date": ua["completion_date"],
                    "activity_name": activity["name"],
                    "activity_description": activity["description"],
                    "point_award": activity["point_award"],
                    "action_key": activity["action_key"]
                })
        
        return result

    # ==================== Activity Tracking ====================

    @staticmethod
    def track_activity(user_id: str, action_key: str) -> Optional[Dict[str, Any]]:
        """
        Track when user performs an action.
        Updates progress for the corresponding activity if assigned and pending.
        
        Args:
            user_id: The user ID
            action_key: The action key (e.g., 'chat_message', 'throw_bottle', 'log_mood_note')
            
        Returns:
            Dict with tracking result info, or None if skipped
        """
        db = get_database()
        
        # Get today's date range
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timedelta(days=1)
        
        # Find the user's pending activity for today with matching action_key
        user_activity = db.user_activities.find_one({
            "user_id": user_id,
            "action_key": action_key,
            "assigned_date": {
                "$gte": today_start,
                "$lt": today_end
            },
            "status": ActivityStatus.PENDING.value
        })
        
        if not user_activity:
            logger.debug(f"No pending activity found for user {user_id} with action_key: {action_key}")
            return None
        
        # Increment progress
        new_progress = user_activity["progress"] + 1
        target = user_activity["target"]
        
        # Update the progress
        db.user_activities.update_one(
            {"_id": user_activity["_id"]},
            {"$set": {"progress": new_progress}}
        )
        
        result = {
            "action_key": action_key,
            "activity_id": user_activity["activity_id"],
            "previous_progress": user_activity["progress"],
            "new_progress": new_progress,
            "target": target,
            "is_completed": False
        }
        
        # Check if completed (progress >= target)
        if new_progress >= target:
            ActivityService.complete_activity(user_id, user_activity["activity_id"])
            result["is_completed"] = True
            logger.info(f"User {user_id} completed activity {user_activity['activity_id']}")
        else:
            logger.info(f"User {user_id} progress: {new_progress}/{target} for {action_key}")
        
        return result

    @staticmethod
    def complete_activity(user_id: str, activity_id: str) -> bool:
        """
        Mark activity as completed and award points.
        Called when activity's progress reaches the target.
        
        Args:
            user_id: The user ID
            activity_id: The activity ID
            
        Returns:
            True if successful
        """
        db = get_database()
        
        # Get today's date range
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timedelta(days=1)
        
        # Update status to completed
        db.user_activities.update_one(
            {
                "user_id": user_id,
                "activity_id": activity_id,
                "assigned_date": {
                    "$gte": today_start,
                    "$lt": today_end
                }
            },
            {
                "$set": {
                    "status": ActivityStatus.COMPLETED.value,
                    "completion_date": datetime.utcnow()
                }
            }
        )
        
        # Get point_award from activities collection
        activity = db.activities.find_one({"activity_id": activity_id}, {"_id": 0})
        if activity:
            points = activity["point_award"]
            ActivityService.award_points(user_id, points)
            logger.info(f"Awarded {points} points to user {user_id} for completing {activity_id}")
        
        return True

    # ==================== Points Management ====================

    @staticmethod
    def award_points(user_id: str, points: int) -> Dict[str, Any]:
        """
        Award points to user. Adds to both lifetime_points and current_points.
        After awarding, checks for rank up.
        
        Args:
            user_id: The user ID
            points: Number of points to award
            
        Returns:
            Dict with updated point info
        """
        db = get_database()
        
        # Get current user profile
        user = db.user_profiles.find_one({"user_id": user_id})
        
        if not user:
            logger.error(f"User {user_id} not found")
            return {"success": False, "error": "User not found"}
        
        # Calculate new points
        current_lifetime = user.get("lifetime_points", 0)
        current_available = user.get("current_points", 0)
        
        new_lifetime = current_lifetime + points
        new_available = current_available + points
        
        # Update user profile
        db.user_profiles.update_one(
            {"user_id": user_id},
            {
                "$set": {
                    "lifetime_points": new_lifetime,
                    "current_points": new_available
                }
            }
        )
        
        logger.info(f"Awarded {points} points to user {user_id}. Lifetime: {new_lifetime}, Available: {new_available}")
        
        # Check for rank up
        rank_result = ActivityService.check_and_update_rank(user_id)
        
        return {
            "success": True,
            "points_awarded": points,
            "lifetime_points": new_lifetime,
            "current_points": new_available,
            "rank_up": rank_result.get("rank_changed", False),
            "current_rank": rank_result.get("current_rank")
        }

    # ==================== Rank Management ====================

    @staticmethod
    def check_and_update_rank(user_id: str) -> Dict[str, Any]:
        """
        Check if user qualifies for a rank up based on lifetime_points.
        Updates current_rank_id if user reaches next rank's min_points.
        
        Args:
            user_id: The user ID
            
        Returns:
            Dict with rank info and whether rank changed
        """
        db = get_database()
        
        # Get user profile
        user = db.user_profiles.find_one({"user_id": user_id})
        
        if not user:
            return {"error": "User not found"}
        
        lifetime_points = user.get("lifetime_points", 0)
        current_rank_id = user.get("current_rank_id", "rank_bronze")
        
        # Get current rank
        current_rank = db.ranks.find_one({"rank_id": current_rank_id}, {"_id": 0})
        
        if not current_rank:
            # Default to bronze if no rank found
            current_rank = db.ranks.find_one({"rank_id": "rank_bronze"}, {"_id": 0})
        
        # Find next rank (rank with min_points > current rank's max_points)
        next_rank = db.ranks.find_one(
            {"min_points": {"$gt": current_rank["max_points"] if current_rank else 0}},
            {"_id": 0},
            sort=[("min_points", 1)]
        )
        
        rank_changed = False
        
        # Check if user qualifies for next rank
        if next_rank and lifetime_points >= next_rank["min_points"]:
            # Update user's rank
            db.user_profiles.update_one(
                {"user_id": user_id},
                {"$set": {"current_rank_id": next_rank["rank_id"]}}
            )
            rank_changed = True
            current_rank_id = next_rank["rank_id"]
            logger.info(f"User {user_id} ranked up to {next_rank['rank_name']}!")
        
        return {
            "current_rank": current_rank_id,
            "rank_name": next_rank["rank_name"] if rank_changed else (current_rank["rank_name"] if current_rank else "Bronze"),
            "rank_changed": rank_changed,
            "lifetime_points": lifetime_points
        }

    @staticmethod
    def get_user_rank(user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get user's current rank details.
        
        Args:
            user_id: The user ID
            
        Returns:
            Rank details or None
        """
        db = get_database()
        
        user = db.user_profiles.find_one({"user_id": user_id})
        if not user:
            return None
        
        rank_id = user.get("current_rank_id", "rank_bronze")
        rank = db.ranks.find_one({"rank_id": rank_id}, {"_id": 0})
        
        return {
            "rank_id": rank_id,
            "rank_name": rank["rank_name"] if rank else "Bronze",
            "min_points": rank["min_points"] if rank else 0,
            "max_points": rank["max_points"] if rank else 2999,
            "lifetime_points": user.get("lifetime_points", 0),
            "current_points": user.get("current_points", 0)
        }

    @staticmethod
    def get_next_rank_progress(user_id: str) -> Dict[str, Any]:
        """
        Get user's progress towards the next rank.
        
        Args:
            user_id: The user ID
            
        Returns:
            Progress info including lifetime_points and next rank min_points
        """
        db = get_database()
        
        user = db.user_profiles.find_one({"user_id": user_id})
        if not user:
            return {"error": "User not found"}
        
        lifetime_points = user.get("lifetime_points", 0)
        current_rank_id = user.get("current_rank_id", "rank_bronze")
        
        # Get current rank
        current_rank = db.ranks.find_one({"rank_id": current_rank_id}, {"_id": 0})
        
        # Get next rank
        next_rank = db.ranks.find_one(
            {"min_points": {"$gt": current_rank["max_points"] if current_rank else 0}},
            {"_id": 0},
            sort=[("min_points", 1)]
        )
        
        if not next_rank:
            # User is at max rank
            return {
                "current_rank_id": current_rank_id,
                "current_rank_name": current_rank["rank_name"] if current_rank else "Gold",
                "lifetime_points": lifetime_points,
                "is_max_rank": True,
                "progress_percentage": 100
            }
        
        # Calculate progress percentage
        points_in_current_rank = lifetime_points - (current_rank["min_points"] if current_rank else 0)
        points_needed_for_next = next_rank["min_points"] - (current_rank["min_points"] if current_rank else 0)
        progress_percentage = min(100, (points_in_current_rank / points_needed_for_next) * 100) if points_needed_for_next > 0 else 0
        
        return {
            "current_rank_id": current_rank_id,
            "current_rank_name": current_rank["rank_name"] if current_rank else "Bronze",
            "next_rank_id": next_rank["rank_id"],
            "next_rank_name": next_rank["rank_name"],
            "lifetime_points": lifetime_points,
            "next_rank_min_points": next_rank["min_points"],
            "points_needed": next_rank["min_points"] - lifetime_points,
            "progress_percentage": round(progress_percentage, 1),
            "is_max_rank": False
        }
