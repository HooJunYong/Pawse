from pydantic import BaseModel
from typing import Optional


class TherapistResponse(BaseModel):
    id: str
    name: str
    title: str
    specialties: str
    location: str
    languages: str
    rating: float
    imageUrl: str
    quote: str
    price: float


class TherapistListResponse(BaseModel):
    therapists: list[TherapistResponse]
    total: int
