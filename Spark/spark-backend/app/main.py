import uuid

from fastapi import Depends, FastAPI, HTTPException, Query, status
from google.auth.exceptions import GoogleAuthError
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from starlette.concurrency import run_in_threadpool

from .config import get_settings
from .database import get_session
from .models import Application, Bookmark, Opportunity, Project, ProjectRole, User
from .schemas import (
    LoginRequest,
    GoogleAuthRequest,
    OpportunityResponse,
    ProfileResponse,
    ProjectCreate,
    ProjectResponse,
    RegisterRequest,
    TokenResponse,
)
from .security import create_access_token, current_user, hash_password, verify_password


app = FastAPI(title="Spark Backend API", version="0.1.0")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/v1/auth/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, session: AsyncSession = Depends(get_session)) -> TokenResponse:
    existing = await session.scalar(select(User).where(User.email == payload.email.lower()))
    if existing is not None:
        raise HTTPException(status_code=409, detail="Email is already registered")

    user = User(
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        name=payload.name,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return TokenResponse(access_token=create_access_token(user.id))


@app.post("/api/v1/auth/login", response_model=TokenResponse)
async def login(payload: LoginRequest, session: AsyncSession = Depends(get_session)) -> TokenResponse:
    user = await session.scalar(select(User).where(User.email == payload.email.lower()))
    if user is None or user.password_hash is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return TokenResponse(access_token=create_access_token(user.id))


async def verified_google_identity(payload: GoogleAuthRequest) -> tuple[str, str, str]:
    client_id = get_settings().google_web_client_id
    if not client_id:
        raise HTTPException(status_code=503, detail="Google Sign-In is not configured")

    try:
        claims = await run_in_threadpool(
            google_id_token.verify_oauth2_token,
            payload.id_token,
            google_requests.Request(),
            client_id,
        )
    except (ValueError, GoogleAuthError) as error:
        raise HTTPException(status_code=401, detail="Invalid Google token") from error

    email = claims.get("email")
    subject = claims.get("sub")
    if not email or not subject or claims.get("email_verified") is not True:
        raise HTTPException(status_code=401, detail="Google email is not verified")

    normalized_email = email.lower()
    name = claims.get("name") or normalized_email.split("@", maxsplit=1)[0]
    return normalized_email, subject, name


@app.post("/api/v1/auth/google/login", response_model=TokenResponse)
async def google_login(
    payload: GoogleAuthRequest,
    session: AsyncSession = Depends(get_session),
) -> TokenResponse:
    normalized_email, subject, _ = await verified_google_identity(payload)
    user = await session.scalar(
        select(User).where(or_(User.google_sub == subject, User.email == normalized_email))
    )

    if user is None:
        raise HTTPException(status_code=404, detail="Google account is not registered")
    if user.google_sub not in (None, subject):
        raise HTTPException(status_code=409, detail="Email is linked to another Google account")

    if user.google_sub is None:
        user.google_sub = subject
        await session.commit()
        await session.refresh(user)

    return TokenResponse(access_token=create_access_token(user.id))


@app.post(
    "/api/v1/auth/google/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
)
async def google_register(
    payload: GoogleAuthRequest,
    session: AsyncSession = Depends(get_session),
) -> TokenResponse:
    normalized_email, subject, name = await verified_google_identity(payload)
    existing = await session.scalar(
        select(User).where(or_(User.google_sub == subject, User.email == normalized_email))
    )
    if existing is not None:
        raise HTTPException(status_code=409, detail="Google account already exists")

    user = User(
        email=normalized_email,
        password_hash=None,
        google_sub=subject,
        name=name,
    )
    session.add(user)

    await session.commit()
    await session.refresh(user)
    return TokenResponse(access_token=create_access_token(user.id))


@app.get("/api/v1/opportunities", response_model=list[OpportunityResponse])
async def list_opportunities(
    search: str | None = Query(default=None, max_length=100),
    category: str | None = Query(default=None, max_length=50),
    session: AsyncSession = Depends(get_session),
) -> list[Opportunity]:
    query = select(Opportunity).where(Opportunity.published.is_(True))
    if category:
        query = query.where(Opportunity.category == category)
    if search:
        pattern = f"%{search}%"
        query = query.where(or_(Opportunity.title.ilike(pattern), Opportunity.summary.ilike(pattern)))
    return list((await session.scalars(query.order_by(Opportunity.deadline.asc()))).all())


@app.get("/api/v1/opportunities/{opportunity_id}", response_model=OpportunityResponse)
async def opportunity_details(opportunity_id: uuid.UUID, session: AsyncSession = Depends(get_session)) -> Opportunity:
    opportunity = await session.get(Opportunity, opportunity_id)
    if opportunity is None or not opportunity.published:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    return opportunity


@app.post("/api/v1/opportunities/{opportunity_id}/bookmark", status_code=status.HTTP_204_NO_CONTENT)
async def bookmark(
    opportunity_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    if await session.get(Opportunity, opportunity_id) is None:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    existing = await session.scalar(select(Bookmark).where(Bookmark.user_id == user.id, Bookmark.opportunity_id == opportunity_id))
    if existing is None:
        session.add(Bookmark(user_id=user.id, opportunity_id=opportunity_id))
        await session.commit()


@app.get("/api/v1/projects", response_model=list[ProjectResponse])
async def list_projects(session: AsyncSession = Depends(get_session)) -> list[Project]:
    query = select(Project).options(selectinload(Project.roles)).order_by(Project.created_at.desc())
    return list((await session.scalars(query)).unique().all())


@app.post("/api/v1/projects", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    payload: ProjectCreate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> Project:
    project = Project(
        owner_id=user.id,
        category=payload.category,
        title=payload.title,
        summary=payload.summary,
        owner_role=payload.owner_role,
        roles=[ProjectRole(title=role.title, skills=role.skills) for role in payload.roles],
    )
    session.add(project)
    await session.commit()
    query = select(Project).options(selectinload(Project.roles)).where(Project.id == project.id)
    return (await session.scalars(query)).one()


@app.post("/api/v1/project-roles/{role_id}/applications", status_code=status.HTTP_201_CREATED)
async def apply_to_role(
    role_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> dict[str, uuid.UUID]:
    role = await session.get(ProjectRole, role_id)
    if role is None or not role.is_open:
        raise HTTPException(status_code=404, detail="Open role not found")
    existing = await session.scalar(select(Application).where(Application.user_id == user.id, Application.project_role_id == role_id))
    if existing is not None:
        raise HTTPException(status_code=409, detail="Application already exists")
    application = Application(user_id=user.id, project_role_id=role_id)
    session.add(application)
    await session.commit()
    await session.refresh(application)
    return {"id": application.id}


@app.get("/api/v1/profile/me", response_model=ProfileResponse)
async def my_profile(user: User = Depends(current_user)) -> User:
    return user
