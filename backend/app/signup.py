from fastapi import APIRouter, HTTPException, status # type: ignore
from pydantic import BaseModel, EmailStr # type: ignore
from datetime import datetime
from .timezone import now_my
import uuid
import os
import base64
import hashlib
import hmac
import logging

from .db import db

logger = logging.getLogger(__name__)
router = APIRouter()

class SignupRequest(BaseModel):
	email: EmailStr
	password: str
	phone_number: str | None = None
	user_type: str | None = "standard"  # could be: standard, admin
	first_name: str
	last_name: str
	gender: str | None = None
	date_of_birth: str | None = None  # ISO date (YYYY-MM-DD)
	home_address: str | None = None
	city: str | None = None
	state: str | None = None
	zip: int | None = None
	profile_picture_url: str | None = None

class SignupResponse(BaseModel):
	user_id: str
	email: EmailStr
	created_at: datetime
	first_name: str
	last_name: str

PASSWORD_MIN_LENGTH = 6
VALID_USER_TYPES = {"standard", "admin"}

# Password hashing parameters (standard library, no external deps)
HASH_NAME = "sha256"
PBKDF2_ITERATIONS = 310000
SALT_BYTES = 16

def hash_password(raw: str) -> str:
	salt = os.urandom(SALT_BYTES)
	dk = hashlib.pbkdf2_hmac(HASH_NAME, raw.encode("utf-8"), salt, PBKDF2_ITERATIONS)
	return f"pbkdf2_{HASH_NAME}${PBKDF2_ITERATIONS}${base64.b64encode(salt).decode()}${base64.b64encode(dk).decode()}"

@router.post("/signup", response_model=SignupResponse, status_code=status.HTTP_201_CREATED)
def signup(payload: SignupRequest):
	# Validate password strength minimally
	if len(payload.password) < PASSWORD_MIN_LENGTH:
		raise HTTPException(status_code=400, detail="Password too short")
	if payload.user_type not in VALID_USER_TYPES:
		raise HTTPException(status_code=400, detail="Invalid user_type")

	existing = db.users.find_one({"email": payload.email.lower()})
	if existing:
		logger.warning(f"Signup failed: email {payload.email} already exists")
		raise HTTPException(status_code=409, detail="Email already registered")

	user_id = str(uuid.uuid4())
	logger.info(f"Creating new user: {user_id} / {payload.email}")
	now = now_my()
	password_hash = hash_password(payload.password)

	user_doc = {
		"user_id": user_id,
		"email": payload.email.lower(),
		"phone_number": payload.phone_number,
		"password": password_hash,
		"user_type": payload.user_type,
		"created_at": now,
		"last_login": None,
		"is_active": True,
	}

	profile_doc = {
		"user_id": user_id,
		"first_name": payload.first_name,
		"last_name": payload.last_name,
		"gender": payload.gender,
		"date_of_birth": payload.date_of_birth,  # store as string; can parse later
		"home_address": payload.home_address,
		"city": payload.city,
		"state": payload.state,
		"zip": payload.zip,
		"profile_picture_url": payload.profile_picture_url,
		"updated_at": now,
		"total_points": 0,
	}

	try:
		db.users.insert_one(user_doc)
		logger.info(f"Inserted user document: {user_id}")
		db.user_profile.insert_one(profile_doc)
		logger.info(f"Inserted profile document: {user_id}")
	except Exception as e:
		logger.error(f"Insert failed for {user_id}: {e}")
		# Rollback user if profile insert fails
		db.users.delete_one({"user_id": user_id})
		raise HTTPException(status_code=500, detail="Failed to create user profile")

	logger.info(f"Signup successful: {user_id} / {payload.email}")
	return SignupResponse(
		user_id=user_id,
		email=payload.email,
		created_at=now,
		first_name=payload.first_name,
		last_name=payload.last_name,
	)

