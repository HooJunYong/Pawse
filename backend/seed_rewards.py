"""
Seed script for rewards collection
Run this script to populate the rewards collection with initial data
"""
from app.models.database import get_database

def seed_rewards():
    """Insert initial rewards into the rewards collection"""
    db = get_database()
    
    # Check if rewards already exist
    existing_count = db.rewards.count_documents({})
    if existing_count > 0:
        print(f"⚠️  Rewards collection already has {existing_count} documents")
        response = input("Do you want to clear and re-seed? (yes/no): ")
        if response.lower() != 'yes':
            print("❌ Seed operation cancelled")
            return
        
        # Clear existing rewards
        db.rewards.delete_many({})
        print("🗑️  Cleared existing rewards")
    
    # Define rewards data
    rewards = [
        {
            "reward_id": "REW001",
            "reward_name": "Siamese Cat",
            "description": "A Siamese appearance for your AI companion.",
            "cost": 2000,
            "reward_type": "companion_skin",
            "image_path": "siamese1.png",
            "is_active": True
        },
        {
            "reward_id": "REW002",
            "reward_name": "White Cat",
            "description": "A White cat appearance for your AI companion.",
            "cost": 2000,
            "reward_type": "companion_skin",
            "image_path": "whitecat1.png",
            "is_active": True
        },
        {
            "reward_id": "REW003",
            "reward_name": "50% Off Therapy Session",
            "description": "A discount voucher for therapy session.",
            "cost": 8000,
            "reward_type": "voucher",
            "image_path": None,
            "is_active": True
        }
    ]
    
    # Insert rewards
    result = db.rewards.insert_many(rewards)
    
    print(f"✅ Successfully seeded {len(result.inserted_ids)} rewards:")
    for reward in rewards:
        print(f"   - {reward['reward_id']}: {reward['reward_name']} ({reward['cost']} points)")
    
    # Create indexes for better query performance
    db.rewards.create_index("reward_id", unique=True)
    db.rewards.create_index("reward_type")
    db.rewards.create_index("is_active")
    print("📊 Created indexes on reward_id, reward_type, and is_active")

if __name__ == "__main__":
    print("🌱 Starting rewards seed script...")
    seed_rewards()
    print("🎉 Rewards seed completed!")
