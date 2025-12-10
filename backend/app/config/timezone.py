from datetime import datetime, timezone, timedelta
try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover
    ZoneInfo = None  # type: ignore

_MALAYSIA_TZ_NAME = "Asia/Kuala_Lumpur"

def get_malaysia_tz():
    """Get Malaysia timezone object."""
    if ZoneInfo is not None:
        try:
            return ZoneInfo(_MALAYSIA_TZ_NAME)
        except Exception:
            pass
    # Fallback: UTC+8
    return timezone(timedelta(hours=8))

def now_my() -> datetime:
    """Return current Malaysia time as timezone-aware datetime.

    Falls back to naive UTC+8 offset if ZoneInfo not available.
    """
    return datetime.now(get_malaysia_tz())

def make_aware_malaysia(dt: datetime) -> datetime:
    """Convert naive datetime to timezone-aware Malaysia time.
    
    If datetime is already aware, returns as-is.
    If naive, assumes it represents Malaysia local time.
    """
    if dt.tzinfo is not None:
        return dt
    return dt.replace(tzinfo=get_malaysia_tz())
