"""
Initialize gamification fields for existing users
Run this once to add points and rank fields to all existing users
"""

from app.models.database import get_database

def init_user_gamification():
    """Add gamification fields to all existing users"""
    db = get_database()
    
    # Update all users who don't have gamification fields
    result = db.user_profile.update_many(
        {
            "$or": [
                {"lifetime_points": {"$exists": False}},
                {"current_points": {"$exists": False}},
                {"current_rank_id": {"$exists": False}}
            ]
        },
        {
            "$set": {
                "lifetime_points": 0,
                "current_points": 0,
                "current_rank_id": "rank_bronze"
            }
        }
    )
    
    print(f"✅ Initialized gamification for {result.modified_count} users")
    print(f"   - lifetime_points: 0")
    print(f"   - current_points: 0")
    print(f"   - current_rank_id: rank_bronze")

if __name__ == "__main__":
    init_user_gamification()