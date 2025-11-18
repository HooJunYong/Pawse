from fastapi import APIRouter, HTTPException # type: ignore
from pydantic import BaseModel, EmailStr # type: ignore
from datetime import datetime
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

	now = datetime.utcnow()
	db.users.update_one({"user_id": user["user_id"]}, {"$set": {"last_login": now}})
	return LoginResponse(user_id=user["user_id"], email=user["email"], last_login=now)

