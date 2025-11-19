from fastapi import APIRouter, HTTPException  # type: ignore
from pydantic import BaseModel, EmailStr  # type: ignore
from datetime import datetime
from .timezone import now_my
import base64
import hashlib
import hmac

from .db import db

router = APIRouter()

class LoginRequest(BaseModel):
	email: EmailStr
	password: str

class LoginResponse(BaseModel):
	user_id: str
	email: EmailStr
	last_login: datetime

class LoginHistoryItem(BaseModel):
    login_at: datetime

class LoginHistoryResponse(BaseModel):
    user_id: str
    history: list[LoginHistoryItem]

def verify_password(raw: str, hashed: str) -> bool:
	try:
		# Expected format: pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>
		algo, iterations_str, salt_b64, hash_b64 = hashed.split("$")
		if not algo.startswith("pbkdf2_"):
			return False
		iterations = int(iterations_str)
		salt = base64.b64decode(salt_b64)
		expected = base64.b64decode(hash_b64)
		name = algo.replace("pbkdf2_", "")
		dk = hashlib.pbkdf2_hmac(name, raw.encode("utf-8"), salt, iterations)
		return hmac.compare_digest(dk, expected)
	except Exception:
		return False

@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest):
	user = db.users.find_one({"email": payload.email.lower()})
	if not user:
		raise HTTPException(status_code=401, detail="Invalid credentials")
	if not verify_password(payload.password, user.get("password", "")):
		raise HTTPException(status_code=401, detail="Invalid credentials")
	if not user.get("is_active", True):
		raise HTTPException(status_code=403, detail="User inactive")

	now = now_my()
	db.users.update_one({"user_id": user["user_id"]}, {"$set": {"last_login": now}})
	# Record this login event in history collection
	db.user_login_events.insert_one({
		"user_id": user["user_id"],
		"login_at": now,
	})
	return LoginResponse(user_id=user["user_id"], email=user["email"], last_login=now)

@router.get("/login/history/{user_id}", response_model=LoginHistoryResponse)
def login_history(user_id: str, limit: int = 20):
	"""Return recent login timestamps for a user (default 20, max 100)."""
	if limit <= 0 or limit > 100:
		limit = 20
	cursor = (
		db.user_login_events.find({"user_id": user_id}, {"_id": 0})
		.sort("login_at", -1)
		.limit(limit)
	)
	events = [LoginHistoryItem(**doc) for doc in cursor]
	if not events and not db.users.find_one({"user_id": user_id}):
		raise HTTPException(status_code=404, detail="User not found")
	return LoginHistoryResponse(user_id=user_id, history=events)

