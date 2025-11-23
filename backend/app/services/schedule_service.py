import uuid
import logging
from datetime import datetime, time
from typing import Optional
from fastapi import HTTPException
from ..models.database import db
from ..models.schemas import (
    SetAvailabilityRequest, AvailabilityResponse, TherapistScheduleResponse, 
    DashboardAppointment, TherapistDashboardResponse, UpcomingAvailability,
    EditAvailabilityRequest
)
from ..config.timezone import now_my

logger = logging.getLogger(__name__)

VALID_DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

def _parse_time_string(time_str: str) -> time:
    """Parse time string in format 'HH:MM AM/PM' to time object"""
    try:
        # Parse formats like "09:00 AM" or "02:00 PM"
        dt = datetime.strptime(time_str, "%I:%M %p")
        return dt.time()
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid time format: {time_str}. Use 'HH:MM AM/PM'")

def _time_to_string(time_obj: time) -> str:
    """Convert time object to string format 'HH:MM AM/PM'"""
    return time_obj.strftime("%I:%M %p")

def set_therapist_availability(payload: SetAvailabilityRequest) -> dict:
    """Set or update therapist availability for a specific day or date"""
    
    # Validate day of week
    if payload.day_of_week.lower() not in VALID_DAYS:
        raise HTTPException(status_code=400, detail="Invalid day of week")
    
    # Verify therapist exists
    therapist = db.therapist_profile.find_one({
        "user_id": payload.user_id,
        "verification_status": "approved"
    })
    if not therapist:
        raise HTTPException(status_code=404, detail="Approved therapist profile not found")
    
    now = now_my()
    day_lower = payload.day_of_week.lower()
    
    # Validate availability_date if provided
    availability_date = None
    if payload.availability_date:
        try:
            availability_date = datetime.strptime(payload.availability_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    
    # Delete existing availability for this day/date
    delete_query: dict = {
        "user_id": payload.user_id,
        "day_of_week": day_lower
    }
    if availability_date:
        delete_query["availability_date"] = payload.availability_date
    else:
        delete_query["availability_date"] = None  # Only delete recurring slots
    
    deleted_result = db.therapist_availability.delete_many(delete_query)
    logger.info(f"Deleted {deleted_result.deleted_count} existing slots for {day_lower}")
    
    # Check for time overlaps with existing slots (excluding the ones we're about to delete)
    existing_slots = list(db.therapist_availability.find({
        "user_id": payload.user_id,
        "$or": [
            {"availability_date": payload.availability_date} if payload.availability_date else {"availability_date": None, "day_of_week": day_lower}
        ]
    }))
    
    # Validate each new slot doesn't overlap with other new slots
    for i, slot in enumerate(payload.slots):
        start_time = _parse_time_string(slot.start_time)
        end_time = _parse_time_string(slot.end_time)
        
        # Validate start time is before end time
        if start_time >= end_time:
            raise HTTPException(status_code=400, detail="Start time must be before end time")
        
        # Check against other new slots
        for j, other_slot in enumerate(payload.slots):
            if i != j:
                other_start = _parse_time_string(other_slot.start_time)
                other_end = _parse_time_string(other_slot.end_time)
                
                # Check if times overlap
                if not (end_time <= other_start or start_time >= other_end):
                    raise HTTPException(
                        status_code=400,
                        detail=f"Time slot {slot.start_time}-{slot.end_time} overlaps with {other_slot.start_time}-{other_slot.end_time}"
                    )
    
    # Insert new availability slots
    inserted_ids = []
    for slot in payload.slots:
        start_time = _parse_time_string(slot.start_time)
        end_time = _parse_time_string(slot.end_time)
        
        availability_doc = {
            "availability_id": str(uuid.uuid4()),
            "user_id": payload.user_id,
            "day_of_week": day_lower,
            "start_time": _time_to_string(start_time),
            "end_time": _time_to_string(end_time),
            "is_available": payload.is_available,
            "availability_date": payload.availability_date,  # Store specific date if provided
            "created_at": now,
            "updated_at": now,
        }
        
        result = db.therapist_availability.insert_one(availability_doc)
        inserted_ids.append(availability_doc["availability_id"])
    
    logger.info(f"Set availability for therapist {payload.user_id} on {day_lower}: {len(inserted_ids)} slots")
    
    return {
        "success": True,
        "message": f"Availability set for {payload.day_of_week}" + (f" on {payload.availability_date}" if payload.availability_date else ""),
        "slots_created": len(inserted_ids),
        "availability_ids": inserted_ids
    }

def get_therapist_availability(user_id: str, day_of_week: Optional[str] = None) -> list[AvailabilityResponse]:
    """Get therapist availability for a specific day or all days"""
    
    query = {"user_id": user_id}
    if day_of_week:
        if day_of_week.lower() not in VALID_DAYS:
            raise HTTPException(status_code=400, detail="Invalid day of week")
        query["day_of_week"] = day_of_week.lower()
    
    availability = list(db.therapist_availability.find(query, {"_id": 0}).sort("start_time", 1))
    
    return [AvailabilityResponse(**avail) for avail in availability]

def delete_availability_slot(availability_id: str, user_id: str) -> dict:
    """Delete a specific availability slot"""
    
    result = db.therapist_availability.delete_one({
        "availability_id": availability_id,
        "user_id": user_id
    })
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Availability slot not found")
    
    logger.info(f"Deleted availability slot {availability_id} for therapist {user_id}")
    
    return {
        "success": True,
        "message": "Availability slot deleted"
    }

def get_therapist_schedule(user_id: str, date: str) -> TherapistScheduleResponse:
    """Get therapist's schedule for a specific date"""
    
    try:
        # Parse date string (format: YYYY-MM-DD)
        target_date = datetime.strptime(date, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    
    # Get day of week
    day_name = target_date.strftime("%A").lower()
    
    # Get sessions for this date
    start_of_day = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = target_date.replace(hour=23, minute=59, second=59, microsecond=999999)
    
    sessions = list(db.therapy_session.find({
        "therapist_user_id": user_id,
        "scheduled_at": {
            "$gte": start_of_day,
            "$lte": end_of_day
        }
    }, {"_id": 0}).sort("scheduled_at", 1))
    
    # Enrich sessions with client info
    for session in sessions:
        client = db.user_profile.find_one({"user_id": session["user_id"]}, {"_id": 0})
        if client:
            session["client_name"] = f"{client.get('first_name', '')} {client.get('last_name', '')}".strip()
            user_data = db.users.find_one({"user_id": session["user_id"]}, {"_id": 0})
            if user_data:
                session["client_email"] = user_data.get("email")
    
    # Get availability for this date
    date_str = target_date.strftime("%Y-%m-%d")
    availability_slots = list(db.therapist_availability.find({
        "$or": [
            {"user_id": user_id, "availability_date": date_str},  # Specific date
            {"user_id": user_id, "day_of_week": day_name, "availability_date": None}  # Recurring
        ]
    }, {"_id": 0}).sort("start_time", 1))
    
    return TherapistScheduleResponse(
        date=date,
        sessions=sessions,
        availability_slots=availability_slots
    )

def get_today_sessions(user_id: str) -> list[dict]:
    """Get therapist's sessions for today"""
    
    now = now_my()
    today_date = now.strftime("%Y-%m-%d")
    
    schedule = get_therapist_schedule(user_id, today_date)
    return schedule.sessions

def get_therapist_dashboard(user_id: str) -> TherapistDashboardResponse:
    """Get therapist dashboard data including today's appointments"""
    
    # Get therapist profile
    therapist = db.therapist_profile.find_one({
        "user_id": user_id,
        "verification_status": "approved"
    })
    if not therapist:
        raise HTTPException(status_code=404, detail="Approved therapist profile not found")
    
    therapist_name = f"Dr. {therapist.get('first_name', 'Therapist')}"
    
    # Get today's sessions
    now = now_my()
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = now.replace(hour=23, minute=59, second=59, microsecond=999999)
    
    sessions = list(db.therapy_session.find({
        "therapist_user_id": user_id,
        "scheduled_at": {
            "$gte": start_of_day,
            "$lte": end_of_day
        },
        "session_status": {"$in": ["scheduled", "confirmed"]}
    }, {"_id": 0}).sort("scheduled_at", 1))
    
    # Format appointments for dashboard
    appointments = []
    for session in sessions:
        # Get client info
        client = db.user_profile.find_one({"user_id": session["user_id"]}, {"_id": 0})
        client_name = "Unknown Client"
        if client:
            first_name = client.get('first_name', '')
            last_name = client.get('last_name', '')
            if first_name and last_name:
                client_name = f"{first_name} {last_name[0]}."
            elif first_name:
                client_name = first_name
        
        # Format time
        scheduled_time = session["scheduled_at"]
        time_str = scheduled_time.strftime("%I:%M").lstrip("0")  # Remove leading zero
        period = scheduled_time.strftime("%p")
        
        # Format session description
        session_type = session.get("session_type", "Session")
        session_desc = f"{session_type.replace('_', ' ').title()} (Online)"
        
        appointments.append(DashboardAppointment(
            time=time_str,
            period=period,
            name=client_name,
            session=session_desc
        ))
    
    # Get upcoming availability (next 5 days with scheduled availability)
    upcoming = get_upcoming_availability(user_id, 5)
    
    return TherapistDashboardResponse(
        therapist_name=therapist_name,
        today_appointments=appointments,
        total_today=len(appointments),
        upcoming_availability=upcoming
    )

def get_upcoming_availability(user_id: str, days: int = 5) -> list[UpcomingAvailability]:
    """Get upcoming availability for the next N days"""
    
    now = now_my()
    upcoming_list = []
    
    for i in range(1, days + 1):  # Start from tomorrow
        target_date = now + __import__('datetime').timedelta(days=i)
        date_str = target_date.strftime("%Y-%m-%d")
        day_name = target_date.strftime("%A")
        day_lower = day_name.lower()
        
        # Get availability for this date (specific date or recurring)
        availability_slots = list(db.therapist_availability.find({
            "$or": [
                {"user_id": user_id, "availability_date": date_str},  # Specific date
                {"user_id": user_id, "day_of_week": day_lower, "availability_date": None}  # Recurring
            ]
        }, {"_id": 0}).sort("start_time", 1))
        
        if availability_slots:  # Only include days with availability
            slots_list = []
            for slot in availability_slots:
                slots_list.append({
                    "availability_id": slot.get("availability_id"),
                    "start_time": slot.get("start_time"),
                    "end_time": slot.get("end_time")
                })
            
            upcoming_list.append(UpcomingAvailability(
                date=date_str,
                day_name=day_name,
                slots=slots_list
            ))
    
    return upcoming_list

def edit_availability_slot(availability_id: str, user_id: str, payload: EditAvailabilityRequest) -> dict:
    """Edit an existing availability slot"""
    
    # Parse and validate times
    start_time = _parse_time_string(payload.start_time)
    end_time = _parse_time_string(payload.end_time)
    
    if start_time >= end_time:
        raise HTTPException(status_code=400, detail="Start time must be before end time")
    
    now = now_my()
    
    result = db.therapist_availability.update_one(
        {"availability_id": availability_id, "user_id": user_id},
        {
            "$set": {
                "start_time": _time_to_string(start_time),
                "end_time": _time_to_string(end_time),
                "updated_at": now
            }
        }
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Availability slot not found")
    
    logger.info(f"Updated availability slot {availability_id} for therapist {user_id}")
    
    return {
        "success": True,
        "message": "Availability slot updated successfully"
    }

def get_therapist_schedule_for_month(user_id: str, year: int, month: int) -> dict:
    """Get all dates in a month that have either an appointment or availability"""
    
    # Validate month and year
    if not (1 <= month <= 12):
        raise HTTPException(status_code=400, detail="Month must be between 1 and 12")
    if not (2000 <= year <= 2100):
        raise HTTPException(status_code=400, detail="Year must be between 2000 and 2100")

    # Get start and end of the month
    start_of_month = datetime(year, month, 1)
    if month == 12:
        end_of_month = datetime(year + 1, 1, 1)
    else:
        end_of_month = datetime(year, month + 1, 1)

    # --- Get dates with sessions ---
    sessions = db.therapy_session.find({
        "therapist_user_id": user_id,
        "scheduled_at": {
            "$gte": start_of_month,
            "$lt": end_of_month
        }
    })
    
    scheduled_dates = {session["scheduled_at"].strftime("%Y-%m-%d") for session in sessions}

    # --- Get dates with specific availability ---
    specific_availability = db.therapist_availability.find({
        "user_id": user_id,
        "availability_date": {
            "$gte": start_of_month.strftime("%Y-%m-%d"),
            "$lt": end_of_month.strftime("%Y-%m-%d")
        }
    })
    
    for avail in specific_availability:
        scheduled_dates.add(avail["availability_date"])
        
    # --- Get dates from recurring availability ---
    recurring_availability = db.therapist_availability.find({
        "user_id": user_id,
        "availability_date": None
    })
    
    recurring_days = {avail["day_of_week"].lower() for avail in recurring_availability}
    
    if recurring_days:
        # Iterate through the month to find matching days of the week
        current_day = start_of_month
        while current_day < end_of_month:
            if current_day.strftime("%A").lower() in recurring_days:
                scheduled_dates.add(current_day.strftime("%Y-%m-%d"))
            current_day += __import__('datetime').timedelta(days=1)

    return {"scheduled_dates": sorted(list(scheduled_dates))}
