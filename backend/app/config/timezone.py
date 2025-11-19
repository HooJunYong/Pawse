from datetime import datetime
try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover
    ZoneInfo = None  # type: ignore

_MALAYSIA_TZ_NAME = "Asia/Kuala_Lumpur"

def now_my() -> datetime:
    """Return current Malaysia time as timezone-aware datetime.

    Falls back to naive UTC+8 offset if ZoneInfo not available.
    """
    if ZoneInfo is not None:
        try:
            return datetime.now(ZoneInfo(_MALAYSIA_TZ_NAME))
        except Exception:
            # ZoneInfo available but timezone data missing
            pass
    # Fallback: manual offset (UTC+8)
    from datetime import timezone, timedelta
    return datetime.utcnow().replace(tzinfo=timezone.utc) + timedelta(hours=8)
