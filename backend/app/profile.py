from fastapi import APIRouter, HTTPException, Query  # type: ignore
from pydantic import BaseModel, EmailStr  # type: ignore
from typing import Optional

from .db import db

router = APIRouter()


class ProfileResponse(BaseModel):
    user_id: str
    full_name: str
    avatar_url: Optional[str] = None
    avatar_base64: Optional[str] = None
    initials: str


def _make_initials(
    first_name: Optional[str],
    last_name: Optional[str],
    full_name: Optional[str],
    email: Optional[str],
) -> str:
    fn = (first_name or "").strip()
    ln = (last_name or "").strip()
    if fn or ln:
        first = fn[0].upper() if fn else ""
        last = ln[0].upper() if ln else ""
        return (first + last) or (first or last) or "U"
    if full_name:
        parts = [p for p in full_name.strip().split() if p]
        if len(parts) >= 2:
            return (parts[0][0] + parts[1][0]).upper()
        if parts:
            return parts[0][0].upper()
    if email:
        return email[0].upper()
    return "U"


def _compose_profile_doc(user_doc: Optional[dict], profile_doc: Optional[dict]) -> ProfileResponse:
    if not user_doc and not profile_doc:
        raise HTTPException(status_code=404, detail="User not found")

    user_id = (profile_doc or {}).get("user_id") or (user_doc or {}).get("user_id")
    email = (user_doc or {}).get("email")

    # Prefer explicit first_name + last_name when available
    first_name = (profile_doc or {}).get("first_name") or (user_doc or {}).get("first_name")
    last_name = (profile_doc or {}).get("last_name") or (user_doc or {}).get("last_name")

    if (first_name and first_name.strip()) or (last_name and last_name.strip()):
        full_name = f"{(first_name or '').strip()} {(last_name or '').strip()}".strip()
    else:
        # Fall back to stored full_name, then name, then derived from email
        full_name = (
            (profile_doc or {}).get("full_name")
            or (user_doc or {}).get("full_name")
            or (user_doc or {}).get("name")
            or (email.split("@")[0].replace(".", " ").title() if email else "User")
        )

    avatar_url = (profile_doc or {}).get("avatar_url")
    avatar_base64 = (profile_doc or {}).get("avatar_base64")

    return ProfileResponse(
        user_id=str(user_id),
        full_name=str(full_name),
        avatar_url=avatar_url,
        avatar_base64=avatar_base64,
        initials=_make_initials(first_name, last_name, full_name, email),
    )


@router.get("/profile/{user_id}", response_model=ProfileResponse)
def get_profile_by_user_id(user_id: str):
    profile_doc = db.user_profile.find_one({"user_id": user_id}, {"_id": 0})
    user_doc = db.users.find_one({"user_id": user_id}, {"_id": 0})
    return _compose_profile_doc(user_doc, profile_doc)


@router.get("/profile/by-email", response_model=ProfileResponse)
def get_profile_by_email(email: EmailStr = Query(..., description="User email")):
    user_doc = db.users.find_one({"email": email.lower()}, {"_id": 0})
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")
    user_id = user_doc.get("user_id")
    profile_doc = db.user_profile.find_one({"user_id": user_id}, {"_id": 0})
    return _compose_profile_doc(user_doc, profile_doc)
