import uuid
from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(min_length=2, max_length=120)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    id_token: str = Field(min_length=20)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class OpportunityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    category: str
    title: str
    summary: str
    details: str
    organizer: str
    image_url: str | None
    location_name: str
    latitude: float | None
    longitude: float | None
    starts_at: date | None
    ends_at: date | None
    deadline: date | None
    reward: int | None


class RoleCreate(BaseModel):
    title: str = Field(min_length=2, max_length=120)
    skills: str = ""


class RoleResponse(RoleCreate):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    is_open: bool


class ProjectCreate(BaseModel):
    category: str = Field(min_length=2, max_length=80)
    title: str = Field(min_length=2, max_length=200)
    summary: str = Field(min_length=10)
    owner_role: str = Field(min_length=2, max_length=120)
    roles: list[RoleCreate] = []


class ProjectUpdate(BaseModel):
    category: str | None = Field(default=None, min_length=2, max_length=80)
    title: str | None = Field(default=None, min_length=2, max_length=200)
    summary: str | None = Field(default=None, min_length=10)
    owner_role: str | None = Field(default=None, min_length=2, max_length=120)


class ProjectResponse(ProjectCreate):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    owner_id: uuid.UUID
    roles: list[RoleResponse]


class ApplicationStatusUpdate(BaseModel):
    status: Literal["accepted", "rejected"]


class ApplicationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    user_name: str
    role_id: uuid.UUID
    role_title: str
    project_id: uuid.UUID
    project_title: str
    status: str


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    name: str
    region: str
    bio: str
    skills: list[str]
    interests: list[str]
