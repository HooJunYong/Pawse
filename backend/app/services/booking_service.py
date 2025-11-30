from datetime import datetime, timedelta
from typing import Optional
import secrets
from ..models.database import db
from ..models.booking_schemas import (
    TherapistAvailabilityResponse,
    AvailableTimeSlot,
    BookingRequest,
    BookingResponse,
    UpcomingSessionResponse,
    CancelBookingRequest,
    CancelBookingResponse,
    SessionStatus,
    SessionType,
    UpdateSessionStatusRequest,
    UpdateSessionStatusResponse,
    PendingRatingResponse,
    PendingRatingSession,
    SubmitSessionRatingRequest,
    SubmitSessionRatingResponse,
    ReleaseSessionSlotRequest,
    ReleaseSessionSlotResponse,
)
from ..config.timezone import now_my


def _coerce_session_status(value: Optional[str]) -> SessionStatus:
    """Return a valid session status, defaulting when value is unknown."""

    if not value:
        return SessionStatus.scheduled
    try:
        return SessionStatus(value)
    except ValueError:
        return SessionStatus.scheduled


def _coerce_session_type(value: Optional[str]) -> SessionType:
    """Return a valid session type, defaulting when value is unknown."""

    if not value:
        return SessionType.in_person
    try:
        return SessionType(value)
    except ValueError:
        return SessionType.in_person


def _combine_date_with_time(date_value: datetime, time_str: str) -> datetime:
    """Return a datetime by combining a date with a 'HH:MM AM/PM' label."""

    time_str_clean = time_str.strip().upper()
    dt_time = datetime.strptime(time_str_clean, "%I:%M %p")
    return date_value.replace(hour=dt_time.hour, minute=dt_time.minute, second=0, microsecond=0)


def get_therapist_availability_for_booking(therapist_user_id: str, date_str: str) -> TherapistAvailabilityResponse:
    """
    Get therapist's available time slots for a specific date
    Returns slots based on therapist's set availability minus already booked slots
    """
    print(f"\n=== AVAILABILITY SERVICE DEBUG ===")
    print(f"Therapist ID: {therapist_user_id}")
    print(f"Date requested: {date_str}")
    
    # Get therapist profile
    therapist = db.therapist_profile.find_one({"user_id": therapist_user_id})
    print(f"Therapist found: {therapist is not None}")
    if therapist:
        print(f"Therapist name: {therapist.get('first_name', '')} {therapist.get('last_name', '')}")
    if not therapist:
        print("ERROR: Therapist not found")
        raise ValueError("Therapist not found")
    
    # Parse date
    try:
        target_date = datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        raise ValueError("Invalid date format. Use YYYY-MM-DD")
    
    # Get day of week (lowercase)
    day_of_week = target_date.strftime("%A").lower()
    print(f"Day of week: {day_of_week}")
    
    # Attempt to find date-specific availability first, then fall back to recurring weekly slots
    print(f"Querying for date-specific slots: user_id={therapist_user_id}, availability_date={date_str}")
    specific_slots = list(db.therapist_availability.find({
        "user_id": therapist_user_id,
        "availability_date": date_str
    }))
    print(f"Found {len(specific_slots)} date-specific slots")
    for slot in specific_slots:
        print(f"  - {slot.get('start_time')} to {slot.get('end_time')}, available: {slot.get('is_available')}")
    
    if specific_slots:
        availability_slots = specific_slots
    else:
        print(f"No date-specific slots, checking recurring for day: {day_of_week}")
        availability_slots = list(db.therapist_availability.find({
            "user_id": therapist_user_id,
            "day_of_week": day_of_week,
            "availability_date": None
        }))
        print(f"Found {len(availability_slots)} recurring slots")
        for slot in availability_slots:
            print(f"  - {slot.get('start_time')} to {slot.get('end_time')}, available: {slot.get('is_available')}")
    
    if not availability_slots:
        print(f"No availability found, returning empty response")
        return TherapistAvailabilityResponse(
            therapist_id=therapist_user_id,
            therapist_name=f"{therapist.get('first_name', '')} {therapist.get('last_name', '')}".strip(),
            date=date_str,
            available_slots=[],
            price=float(therapist.get('hourly_rate', 150.0)),
            center_name=therapist.get('office_name', 'Holistic Mind Center')
        )
    
    # Get existing bookings for this date
    start_of_day = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_day = target_date.replace(hour=23, minute=59, second=59, microsecond=999999)
    
    existing_sessions = list(db.therapy_sessions.find({
        "therapist_user_id": therapist_user_id,
        "scheduled_at": {
            "$gte": start_of_day,
            "$lte": end_of_day
        },
        "$or": [
            {"session_status": {"$in": [SessionStatus.scheduled.value]}},
            {"status": {"$in": [SessionStatus.scheduled.value]}},
            {"session_status": {"$regex": "cancel", "$options": "i"}},
            {"status": {"$regex": "cancel", "$options": "i"}}
        ]
    }))
    
    session_windows: list[tuple[datetime, datetime]] = []
    for session in existing_sessions:
        scheduled_value = session.get("scheduled_at")
        scheduled_dt: Optional[datetime] = None
        if isinstance(scheduled_value, datetime):
            scheduled_dt = scheduled_value
        elif isinstance(scheduled_value, str):
            try:
                scheduled_dt = datetime.fromisoformat(scheduled_value.replace("Z", "+00:00"))
            except ValueError:
                scheduled_dt = None

        if scheduled_dt is None:
            start_label = session.get("start_time")
            if start_label:
                try:
                    scheduled_dt = _combine_date_with_time(target_date, start_label)
                except ValueError:
                    continue
        if scheduled_dt is None:
            continue

        status_value = session.get("session_status") or session.get("status")
        status_text = (status_value or "").strip().lower()
        is_cancelled = status_text == SessionStatus.cancelled.value or "cancel" in status_text
        if is_cancelled and session.get("slot_released") is True:
            continue

        duration = int(session.get("duration_minutes", 50))
        end_dt = scheduled_dt + timedelta(minutes=duration)
        session_windows.append((scheduled_dt, end_dt))

    slot_entries: list[tuple[datetime, AvailableTimeSlot]] = []

    for slot in availability_slots:
        start_time_label = slot.get("start_time")
        end_time_label = slot.get("end_time")
        if not start_time_label or not end_time_label:
            continue

        try:
            slot_start_dt = _combine_date_with_time(target_date, start_time_label)
            slot_end_dt = _combine_date_with_time(target_date, end_time_label)
        except ValueError:
            continue

        if slot_end_dt <= slot_start_dt:
            continue

        slot_id = slot.get("availability_id") or str(slot.get("_id"))

        is_booked = any(
            not (slot_end_dt <= window_start or slot_start_dt >= window_end)
            for window_start, window_end in session_windows
        )

        is_available_flag = slot.get("is_available", True) and not is_booked

        slot_entries.append((
            slot_start_dt,
            AvailableTimeSlot(
                slot_id=slot_id,
                start_time=slot_start_dt.strftime("%I:%M %p"),
                end_time=slot_end_dt.strftime("%I:%M %p"),
                is_available=is_available_flag,
                date=date_str
            )
        ))

    available_slots = [entry[1] for entry in sorted(slot_entries, key=lambda entry: entry[0])]
    print(f"\n=== FINAL RESULT ===")
    print(f"Returning {len(available_slots)} total slots")
    for slot in available_slots:
        print(f"  - {slot.start_time} to {slot.end_time}, available: {slot.is_available}")
    print(f"=================================\n")
    
    return TherapistAvailabilityResponse(
        therapist_id=therapist_user_id,
        therapist_name=f"{therapist.get('first_name', '')} {therapist.get('last_name', '')}".strip(),
        date=date_str,
        available_slots=available_slots,
        price=float(therapist.get('hourly_rate', 150.0)),
        center_name=therapist.get('office_name', 'Holistic Mind Center')
    )


def create_booking(request: BookingRequest) -> BookingResponse:
    """
    Create a new booking for a therapy session
    """
    # Validate therapist exists
    therapist = db.therapist_profile.find_one({"user_id": request.therapist_user_id})
    if not therapist:
        raise ValueError("Therapist not found")
    
    # Validate client exists
    client = db.users.find_one({"user_id": request.client_user_id})
    if not client:
        raise ValueError("Client not found")
    
    # Parse date and time
    try:
        date_obj = datetime.strptime(request.date, "%Y-%m-%d")
    except ValueError:
        raise ValueError("Invalid date format. Use YYYY-MM-DD")
    
    # Parse start time to datetime
    start_time_str = request.start_time.upper().strip()
    try:
        time_parts = start_time_str.split()
        time_str = time_parts[0]
        period = time_parts[1] if len(time_parts) > 1 else "AM"
        
        hour, minute = map(int, time_str.split(':'))
        if period == "PM" and hour != 12:
            hour += 12
        elif period == "AM" and hour == 12:
            hour = 0
        
        scheduled_datetime = date_obj.replace(hour=hour, minute=minute, second=0, microsecond=0)
    except (ValueError, IndexError):
        raise ValueError("Invalid time format. Use format like '9:00 AM'")
    
    normalized_start_time = scheduled_datetime.strftime("%I:%M %p")
    
    # Check if slot is available
    day_of_week = date_obj.strftime("%A").lower()
    availability = db.therapist_availability.find_one({
        "user_id": request.therapist_user_id,
        "availability_date": request.date,
        "start_time": normalized_start_time
    })

    if not availability:
        availability = db.therapist_availability.find_one({
            "user_id": request.therapist_user_id,
            "day_of_week": day_of_week,
            "availability_date": None,
            "start_time": normalized_start_time
        })
    
    if not availability and request.start_time != normalized_start_time:
        availability = db.therapist_availability.find_one({
            "user_id": request.therapist_user_id,
            "availability_date": request.date,
            "start_time": request.start_time
        })

    if not availability and request.start_time != normalized_start_time:
        availability = db.therapist_availability.find_one({
            "user_id": request.therapist_user_id,
            "day_of_week": day_of_week,
            "availability_date": None,
            "start_time": request.start_time
        })
    
    if not availability or not availability.get("is_available", True):
        raise ValueError("This time slot is not available")
    
    # Check if already booked
    existing_session = db.therapy_sessions.find_one({
        "therapist_user_id": request.therapist_user_id,
        "scheduled_at": scheduled_datetime,
        "$or": [
            {"session_status": {"$in": [SessionStatus.scheduled.value]}},
            {"status": {"$in": [SessionStatus.scheduled.value]}}
        ]
    })
    
    if existing_session:
        raise ValueError("This time slot is already booked")
    
    # Calculate end time
    end_datetime = scheduled_datetime + timedelta(minutes=request.duration_minutes)
    end_time_str = end_datetime.strftime("%I:%M %p")
    
    # Create therapy session record
    session_id = secrets.token_hex(32)
    therapist_name = f"{therapist.get('first_name', '')} {therapist.get('last_name', '')}".strip()
    center_name = therapist.get('office_name') or "Holistic Mind Center"
    address_parts = [
        therapist.get('office_address'),
        therapist.get('city'),
        therapist.get('state'),
    ]
    center_address = ", ".join([part for part in address_parts if part]) or therapist.get('office_address') or ""
    client_name = client.get('full_name') or client.get('email', '').split('@')[0]
    
    # Calculate session fee based on hourly rate and duration
    hourly_rate = float(therapist.get('hourly_rate', 150.0))
    duration_hours = request.duration_minutes / 60.0
    session_fee = hourly_rate * duration_hours
    
    session_status = SessionStatus.scheduled.value
    now_ts = now_my()

    session_doc = {
        "session_id": session_id,
        "user_id": request.client_user_id,
        "client_name": client_name,
        "therapist_user_id": request.therapist_user_id,
        "therapist_name": therapist_name,
        "scheduled_at": scheduled_datetime,
        "start_time": normalized_start_time,
        "end_time": end_time_str,
        "duration_minutes": request.duration_minutes,
        "session_fee": session_fee,
        "session_type": request.session_type.value,
        "session_status": session_status,
        "status": session_status,
        "session_notes": request.notes or "",
        "user_rating": None,
        "user_feedback": "",
        "created_at": now_ts,
        "updated_at": now_ts,
        "center_name": center_name,
        "center_address": center_address,
    }

    db.therapy_sessions.insert_one(session_doc)

    return BookingResponse(
        booking_id=session_id,
        session_id=session_id,
        client_user_id=request.client_user_id,
        therapist_user_id=request.therapist_user_id,
        therapist_name=therapist_name or "Unknown Therapist",
        scheduled_at=scheduled_datetime.isoformat(),
        start_time=normalized_start_time,
        end_time=end_time_str,
        duration_minutes=request.duration_minutes,
        price=session_fee,
        session_fee=session_fee,
        status=session_status,
        session_status=SessionStatus.scheduled,
        session_type=request.session_type,
        created_at=now_ts.isoformat(),
        message="Booking confirmed successfully!",
        center_name=center_name,
        center_address=center_address,
    )


def get_client_bookings(client_user_id: str) -> list[BookingResponse]:
    """Get all therapy sessions booked by a client."""

    sessions = list(
        db.therapy_sessions
        .find({"user_id": client_user_id})
        .sort("scheduled_at", -1)
    )

    result: list[BookingResponse] = []
    for session in sessions:
        scheduled_at = session.get("scheduled_at")
        created_at = session.get("created_at")
        session_fee = float(session.get("session_fee", session.get("price", 0.0)))
        status_enum = _coerce_session_status(session.get("session_status") or session.get("status"))
        type_enum = _coerce_session_type(session.get("session_type"))

        result.append(BookingResponse(
            booking_id=str(session.get("_id")),
            session_id=session.get("session_id", ""),
            client_user_id=session.get("user_id", ""),
            therapist_user_id=session.get("therapist_user_id", ""),
            therapist_name=session.get("therapist_name", "Unknown Therapist"),
            scheduled_at=scheduled_at.isoformat() if scheduled_at else "",
            start_time=session.get("start_time", ""),
            end_time=session.get("end_time", ""),
            duration_minutes=int(session.get("duration_minutes", 50)),
            price=session_fee,
            session_fee=session_fee,
            status=status_enum.value,
            session_status=status_enum,
            session_type=type_enum,
            created_at=created_at.isoformat() if created_at else "",
            message="",
            center_name=session.get("center_name"),
            center_address=session.get("center_address"),
        ))

    return result


def get_therapist_bookings(therapist_user_id: str) -> list[BookingResponse]:
    """Get all bookings for a therapist"""
    sessions = list(
        db.therapy_sessions
        .find({"therapist_user_id": therapist_user_id})
        .sort("scheduled_at", -1)
    )

    result: list[BookingResponse] = []
    for session in sessions:
        scheduled_at = session.get("scheduled_at")
        created_at = session.get("created_at")
        session_fee = float(session.get("session_fee", session.get("price", 0.0)))
        status_enum = _coerce_session_status(session.get("session_status") or session.get("status"))
        type_enum = _coerce_session_type(session.get("session_type"))

        result.append(BookingResponse(
            booking_id=str(session.get("_id")),
            session_id=session.get("session_id", ""),
            client_user_id=session.get("user_id", ""),
            therapist_user_id=session.get("therapist_user_id", ""),
            therapist_name=session.get("client_name", "Unknown Client"),
            scheduled_at=scheduled_at.isoformat() if scheduled_at else "",
            start_time=session.get("start_time", ""),
            end_time=session.get("end_time", ""),
            duration_minutes=int(session.get("duration_minutes", 50)),
            price=session_fee,
            session_fee=session_fee,
            status=status_enum.value,
            session_status=status_enum,
            session_type=type_enum,
            created_at=created_at.isoformat() if created_at else "",
            message="",
            center_name=session.get("center_name"),
            center_address=session.get("center_address"),
        ))

    return result


def get_upcoming_client_session(client_user_id: str) -> Optional[UpcomingSessionResponse]:
    """Return the next upcoming scheduled session for the given client."""

    now_utc = datetime.utcnow()
    session = db.therapy_sessions.find_one(
        {
            "user_id": client_user_id,
            "session_status": {"$in": [SessionStatus.scheduled.value]},
            "scheduled_at": {"$gte": now_utc},
        },
        sort=[("scheduled_at", 1)],
    )

    if not session:
        return None

    scheduled_at_value = session.get("scheduled_at")
    if isinstance(scheduled_at_value, datetime):
        scheduled_dt = scheduled_at_value
    elif isinstance(scheduled_at_value, str):
        try:
            scheduled_dt = datetime.fromisoformat(
                scheduled_at_value.replace("Z", "+00:00")
            )
        except ValueError:
            scheduled_dt = now_utc
    else:
        scheduled_dt = now_utc

    status_enum = _coerce_session_status(session.get("session_status") or session.get("status"))
    type_enum = _coerce_session_type(session.get("session_type"))
    session_fee = float(session.get("session_fee", session.get("price", 0.0)))

    center_name_value = session.get("center_name")
    center_address_value = session.get("center_address")

    if not center_name_value or not center_address_value:
        therapist_profile = db.therapist_profile.find_one({"user_id": session.get("therapist_user_id")})
        if therapist_profile:
            center_name_value = center_name_value or therapist_profile.get("office_name")
            address_parts = [
                therapist_profile.get('office_address'),
                therapist_profile.get('city'),
                therapist_profile.get('state'),
            ]
            combined_address = ", ".join([part for part in address_parts if part]) or therapist_profile.get('office_address')
            center_address_value = center_address_value or combined_address

    return UpcomingSessionResponse(
        session_id=session.get("session_id", ""),
        therapist_user_id=session.get("therapist_user_id", ""),
        therapist_name=session.get("therapist_name", "Unknown Therapist"),
        scheduled_at=scheduled_dt,
        start_time=session.get("start_time", ""),
        end_time=session.get("end_time", ""),
        duration_minutes=int(session.get("duration_minutes", 50)),
        session_fee=session_fee,
        session_status=status_enum,
        session_type=type_enum,
        center_name=center_name_value,
        center_address=center_address_value,
    )


def update_session_status(request: UpdateSessionStatusRequest) -> UpdateSessionStatusResponse:
    """Mark a therapy session as completed or no-show."""

    allowed_statuses = {SessionStatus.completed, SessionStatus.no_show}
    if request.status not in allowed_statuses:
        raise ValueError("Only completed or no_show statuses can be applied via this endpoint.")

    session = db.therapy_sessions.find_one({
        "session_id": request.session_id,
        "therapist_user_id": request.therapist_user_id,
    })

    if not session:
        raise ValueError("Session not found or does not belong to this therapist.")

    current_status = _coerce_session_status(session.get("session_status") or session.get("status"))

    if current_status == SessionStatus.cancelled:
        raise ValueError("Cancelled sessions cannot be updated.")

    if current_status == request.status:
        return UpdateSessionStatusResponse(
            success=True,
            message=f"Session already marked as {request.status.value.replace('_', ' ')}.",
            session_status=current_status,
        )

    now_ts = now_my()

    update_fields = {
        "session_status": request.status.value,
        "status": request.status.value,
        "updated_at": now_ts,
    }
    unset_fields: dict[str, str] = {}

    if request.status == SessionStatus.completed:
        awaiting_rating = session.get("user_rating") in (None, "", 0, 0.0)
        update_fields["completed_at"] = now_ts
        update_fields["awaiting_rating"] = awaiting_rating
        if awaiting_rating:
            update_fields["rating_prompted_at"] = now_ts
        else:
            unset_fields["rating_prompted_at"] = ""
    else:  # no_show
        update_fields["awaiting_rating"] = False
        update_fields["completed_at"] = now_ts
        unset_fields["rating_prompted_at"] = ""

    update_spec: dict[str, dict] = {"$set": update_fields}
    if unset_fields:
        update_spec["$unset"] = unset_fields

    db.therapy_sessions.update_one(
        {"session_id": request.session_id, "therapist_user_id": request.therapist_user_id},
        update_spec,
    )

    return UpdateSessionStatusResponse(
        success=True,
        message=f"Session marked as {request.status.value.replace('_', ' ')}.",
        session_status=request.status,
    )


def get_pending_rating(client_user_id: str) -> PendingRatingResponse:
    """Return the next completed session that still requires a client rating."""

    query = {
        "user_id": client_user_id,
        "session_status": SessionStatus.completed.value,
        "$and": [
            {
                "$or": [
                    {"user_rating": {"$exists": False}},
                    {"user_rating": None},
                    {"user_rating": ""},
                ]
            },
            {
                "$or": [
                    {"awaiting_rating": True},
                    {"awaiting_rating": {"$exists": False}},
                ]
            },
        ],
    }

    session = db.therapy_sessions.find_one(query, sort=[("scheduled_at", 1)])

    if not session:
        return PendingRatingResponse(has_pending=False, session=None)

    scheduled_value = session.get("scheduled_at")
    if isinstance(scheduled_value, datetime):
        scheduled_dt = scheduled_value
    else:
        try:
            scheduled_dt = datetime.fromisoformat(str(scheduled_value))
        except Exception:
            scheduled_dt = now_my()

    therapist_profile = db.therapist_profile.find_one(
        {"user_id": session.get("therapist_user_id")},
        {"profile_picture_url": 1},
    )

    pending = PendingRatingSession(
        session_id=session.get("session_id", ""),
        therapist_user_id=session.get("therapist_user_id", ""),
        therapist_name=session.get("therapist_name", "Therapist"),
        scheduled_at=scheduled_dt,
        end_time=session.get("end_time", ""),
        duration_minutes=int(session.get("duration_minutes", 50)),
        session_type=_coerce_session_type(session.get("session_type")),
        therapist_profile_picture_url=(therapist_profile or {}).get("profile_picture_url"),
    )

    return PendingRatingResponse(has_pending=True, session=pending)


def submit_session_rating(request: SubmitSessionRatingRequest) -> SubmitSessionRatingResponse:
    """Store the client rating for a completed therapy session."""

    rating_value = float(request.rating)
    if rating_value < 1 or rating_value > 5:
        raise ValueError("Rating must be between 1 and 5 stars.")

    session = db.therapy_sessions.find_one({
        "session_id": request.session_id,
        "user_id": request.client_user_id,
    })

    if not session:
        raise ValueError("Session not found for this user.")

    if _coerce_session_status(session.get("session_status") or session.get("status")) != SessionStatus.completed:
        raise ValueError("Only completed sessions can be rated.")

    now_ts = now_my()

    update_spec = {
        "$set": {
            "user_rating": round(rating_value, 1),
            "user_feedback": request.feedback or "",
            "awaiting_rating": False,
            "rated_at": now_ts,
            "updated_at": now_ts,
        },
        "$unset": {"rating_prompted_at": ""},
    }

    db.therapy_sessions.update_one(
        {"session_id": request.session_id, "user_id": request.client_user_id},
        update_spec,
    )

    return SubmitSessionRatingResponse(
        success=True,
        message="Thank you for rating your session.",
        rating=round(rating_value, 1),
    )


def cancel_client_booking(request: CancelBookingRequest) -> CancelBookingResponse:
    """Cancel a client's upcoming session if it is still scheduled."""

    session = db.therapy_sessions.find_one({
        "session_id": request.session_id,
        "user_id": request.client_user_id,
        "$or": [
            {"slot_released": {"$exists": False}},
            {"slot_released": False},
        ],
    })

    if not session:
        raise ValueError("Booking not found")

    status = _coerce_session_status(session.get("session_status") or session.get("status")).value
    if status == SessionStatus.cancelled.value:
        return CancelBookingResponse(success=True, message="Booking already cancelled")
    if status not in {SessionStatus.scheduled.value}:
        raise ValueError("Only scheduled bookings can be cancelled")

    now_ts = now_my()

    db.therapy_sessions.update_one(
        {"session_id": request.session_id, "user_id": request.client_user_id},
        {
            "$set": {
                "session_status": SessionStatus.cancelled.value,
                "status": SessionStatus.cancelled.value,
                "updated_at": now_ts,
                "cancellation_reason": request.reason or "",
                "slot_released": False,
            }
        }
    )

    return CancelBookingResponse(
        success=True,
        message="Booking cancelled successfully",
    )


def release_cancelled_session_slot(request: ReleaseSessionSlotRequest) -> ReleaseSessionSlotResponse:
    """Allow a therapist to mark a cancelled session slot as available again."""

    session = db.therapy_sessions.find_one({
        "session_id": request.session_id,
        "therapist_user_id": request.therapist_user_id,
    })

    if not session:
        raise ValueError("Session not found")

    status = _coerce_session_status(session.get("session_status") or session.get("status"))
    if status != SessionStatus.cancelled:
        raise ValueError("Only cancelled sessions can be released")

    if session.get("slot_released") is True:
        return ReleaseSessionSlotResponse(
            success=True,
            message="Slot already released",
        )

    now_ts = now_my()

    db.therapy_sessions.update_one(
        {"session_id": request.session_id, "therapist_user_id": request.therapist_user_id},
        {
            "$set": {
                "slot_released": True,
                "updated_at": now_ts,
            }
        }
    )

    return ReleaseSessionSlotResponse(
        success=True,
        message="Cancelled slot released for new bookings",
    )
