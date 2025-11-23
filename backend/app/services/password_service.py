import base64
import hashlib
import hmac
import os
from ..config.settings import HASH_NAME, PBKDF2_ITERATIONS, SALT_BYTES

def hash_password(raw: str) -> str:
    """Hash password using pbkdf2_sha256"""
    salt = os.urandom(SALT_BYTES)
    dk = hashlib.pbkdf2_hmac(HASH_NAME, raw.encode("utf-8"), salt, PBKDF2_ITERATIONS)
    return f"pbkdf2_{HASH_NAME}${PBKDF2_ITERATIONS}${base64.b64encode(salt).decode()}${base64.b64encode(dk).decode()}"

def verify_password(raw: str, hashed: str) -> bool:
    """Verify password using pbkdf2_sha256 format"""
    try:
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
