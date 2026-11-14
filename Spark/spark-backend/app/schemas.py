import uuid
import base64
import binascii
from datetime import date
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(min_length=2, max_length=120)


class EmailRequest(BaseModel):
    email: EmailStr


class VerifyCodeRequest(EmailRequest):
    code: str = Field(pattern=r"^\d{6}$")


class ResetPasswordRequest(VerifyCodeRequest):
    new_password: str = Field(min_length=8, max_length=128)


class MessageResponse(BaseModel):
    message: str
    development_code: str | None = None


class AvatarRequest(BaseModel):
    data: str = Field(min_length=4)
    content_type: Literal["image/jpeg", "image/png"]

    def decoded_data(self) -> bytes:
        try:
            return base64.b64decode(self.data, validate=True)
        except (ValueError, binascii.Error) as error:
            raise ValueError("Invalid avatar data") from error


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


class AchievementCreate(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    issuer: str = Field(min_length=2, max_length=160)
    issued_at: date


class AchievementResponse(AchievementCreate):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
