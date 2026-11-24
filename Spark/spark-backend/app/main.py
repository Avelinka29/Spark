import hashlib
import asyncio
import base64
import secrets
import uuid
import httpx
from datetime import date, datetime, timedelta, timezone

from fastapi import Depends, FastAPI, HTTPException, Query, status
from google.auth.exceptions import GoogleAuthError
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy import and_, delete, func, or_, select, text, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlalchemy.dialects.postgresql import insert as pg_insert
from starlette.concurrency import run_in_threadpool

from .config import get_settings
from .ai_recommendations import ModelMatch, rank_projects
from .database import get_session
from .email_service import send_auth_code
from .models import Achievement, Application, ApplicationStatus, AuthCode, AuthCodePurpose, Bookmark, ChatMember, ChatMessage, EventProposal, Friendship, FriendshipStatus, Notification, Opportunity, OpportunityAttendance, Project, ProjectChat, ProjectRole, TeamTask, TeamWorkspace, User
from .schemas import (
    LoginRequest,
    ApplicationResponse,
    ApplicationStatusUpdate,
    AchievementCreate,
    AchievementResponse,
    AvatarRequest,
    ChatMessageCreate,
    ChatMessageResponse,
    ChatResponse,
    EmailRequest,
    EventProposalCreate,
    EventProposalDecision,
    EventProposalResponse,
    FriendResponse,
    GoogleAuthRequest,
    MessageResponse,
    NotificationResponse,
    OpportunityCreate,
    OpportunityResponse,
    OrganizationProfileUpdate,
    OrganizationApplicationResponse,
    OrganizationDecision,
    AttendanceResponse,
    AttendingFriend,
    TeamTaskCreate,
    TeamTaskUpdate,
    TeamTaskResponse,
    TeamWorkspaceData,
    ProfileResponse,
    ProfileUpdate,
    PublicProfileResponse,
    PortfolioProject,
    PortfolioEvent,
    ProjectCreate,
    ProjectResponse,
    ProjectUpdate,
    RegisterRequest,
    ResetPasswordRequest,
    RoleCreate,
    RoleResponse,
    RoleUpdate,
    TokenResponse,
    VerifyCodeRequest,
)
from .security import create_access_token, current_user, hash_password, verify_password


app = FastAPI(title="Spark Backend API", version="0.1.0")
ai_request_slot = asyncio.Semaphore(1)


@app.get("/health")
async def health(session: AsyncSession = Depends(get_session)) -> dict[str, str]:
    try:
        await session.execute(text("SELECT 1"))
    except Exception as error:
        raise HTTPException(status_code=503, detail="Database is unavailable") from error
    return {"status": "ok", "database": "ok"}


@app.get("/health/live")
async def liveness() -> dict[str, str]:
    return {"status": "ok"}


def hash_auth_code(code: str) -> str:
    value = f"{code}:{get_settings().jwt_secret}".encode()
    return hashlib.sha256(value).hexdigest()


async def issue_auth_code(
    session: AsyncSession,
    user: User,
    purpose: AuthCodePurpose,
) -> str:
    code = f"{secrets.randbelow(1_000_000):06d}"
    await session.execute(
        delete(AuthCode).where(AuthCode.user_id == user.id, AuthCode.purpose == purpose)
    )
    session.add(
        AuthCode(
            user_id=user.id,
            purpose=purpose,
            code_hash=hash_auth_code(code),
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=15),
        )
    )
    await session.commit()
    return code


async def deliver_auth_code(email: str, code: str, purpose: AuthCodePurpose) -> str | None:
    delivered = await send_auth_code(email, code, purpose.value)
    settings = get_settings()
    if not delivered and not settings.allow_development_codes:
        raise HTTPException(status_code=503, detail="Email delivery is not configured")
    return code if settings.allow_development_codes else None


async def valid_auth_code(
    session: AsyncSession,
    user: User,
    purpose: AuthCodePurpose,
    code: str,
) -> AuthCode:
    auth_code = await session.scalar(
        select(AuthCode).where(AuthCode.user_id == user.id, AuthCode.purpose == purpose)
    )
    if (
        auth_code is None
        or auth_code.expires_at < datetime.now(timezone.utc)
        or not secrets.compare_digest(auth_code.code_hash, hash_auth_code(code))
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")
    return auth_code


@app.post("/api/v1/auth/register", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, session: AsyncSession = Depends(get_session)) -> MessageResponse:
    existing = await session.scalar(select(User).where(User.email == payload.email.lower()))
    if existing is not None:
        raise HTTPException(status_code=409, detail="Email is already registered")

    user = User(
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        name=payload.name,
        email_verified=False,
        account_type="admin" if get_settings().is_admin_email(payload.email) else "user",
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    code = await issue_auth_code(session, user, AuthCodePurpose.verify_email)
    development_code = await deliver_auth_code(user.email, code, AuthCodePurpose.verify_email)
    return MessageResponse(message="Verification code sent", development_code=development_code)


@app.post("/api/v1/auth/login", response_model=TokenResponse)
async def login(payload: LoginRequest, session: AsyncSession = Depends(get_session)) -> TokenResponse:
    email = payload.email.strip().lower()
    if email in {"admin", "admin@spark.example.com"}:
        if get_settings().app_environment != "development":
            raise HTTPException(status_code=401, detail="Invalid email or password")
        email = "admin@spark.example.com"
    user = await session.scalar(select(User).where(User.email == email))
    if user is None or user.password_hash is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.email_verified:
        raise HTTPException(status_code=403, detail="Email is not verified")
    return TokenResponse(access_token=create_access_token(user.id))


@app.post("/api/v1/auth/verify-email", response_model=MessageResponse)
async def verify_email(payload: VerifyCodeRequest, session: AsyncSession = Depends(get_session)) -> MessageResponse:
    user = await session.scalar(select(User).where(User.email == payload.email.lower()))
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")
    auth_code = await valid_auth_code(session, user, AuthCodePurpose.verify_email, payload.code)
    user.email_verified = True
    await session.delete(auth_code)
    await session.commit()
    return MessageResponse(message="Email verified")


@app.post("/api/v1/auth/resend-verification", response_model=MessageResponse)
async def resend_verification(payload: EmailRequest, session: AsyncSession = Depends(get_session)) -> MessageResponse:
    user = await session.scalar(select(User).where(User.email == payload.email.lower()))
    if user is None or user.email_verified:
        return MessageResponse(message="If verification is required, a code was sent")
    code = await issue_auth_code(session, user, AuthCodePurpose.verify_email)
    development_code = await deliver_auth_code(user.email, code, AuthCodePurpose.verify_email)
    return MessageResponse(message="Verification code sent", development_code=development_code)


@app.post("/api/v1/auth/forgot-password", response_model=MessageResponse)
async def forgot_password(payload: EmailRequest, session: AsyncSession = Depends(get_session)) -> MessageResponse:
    user = await session.scalar(select(User).where(User.email == payload.email.lower()))
    if user is None or user.password_hash is None:
        return MessageResponse(message="If the account exists, a reset code was sent")
    code = await issue_auth_code(session, user, AuthCodePurpose.password_reset)
    development_code = await deliver_auth_code(user.email, code, AuthCodePurpose.password_reset)
    return MessageResponse(message="Password reset code sent", development_code=development_code)


@app.post("/api/v1/auth/reset-password", response_model=MessageResponse)
async def reset_password(payload: ResetPasswordRequest, session: AsyncSession = Depends(get_session)) -> MessageResponse:
    user = await session.scalar(select(User).where(User.email == payload.email.lower()))
    if user is None or user.password_hash is None:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")
    auth_code = await valid_auth_code(session, user, AuthCodePurpose.password_reset, payload.code)
    user.password_hash = hash_password(payload.new_password)
    await session.delete(auth_code)
    await session.commit()
    return MessageResponse(message="Password updated")


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
        user.email_verified = True
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
        email_verified=True,
        name=name,
        account_type="admin" if get_settings().is_admin_email(normalized_email) else "user",
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


@app.post("/api/v1/opportunities", response_model=OpportunityResponse, status_code=status.HTTP_201_CREATED)
async def create_opportunity(
    payload: OpportunityCreate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> Opportunity:
    if user.account_type not in {"organization", "admin"}:
        raise HTTPException(status_code=403, detail="Only organizations and administrators can publish opportunities")
    opportunity = Opportunity(
        owner_id=user.id,
        organizer=user.organization_name or user.name,
        **payload.model_dump(),
    )
    session.add(opportunity)
    await session.commit()
    await session.refresh(opportunity)
    return opportunity


@app.post("/api/v1/event-proposals", response_model=EventProposalResponse, status_code=status.HTTP_201_CREATED)
async def propose_event(
    payload: EventProposalCreate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> EventProposalResponse:
    proposal = EventProposal(
        author_id=user.id,
        event_data=payload.event.model_dump(mode="json"),
        message=payload.message.strip(),
    )
    session.add(proposal)
    admin_ids = list(await session.scalars(select(User.id).where(User.account_type == "admin")))
    for admin_id in admin_ids:
        session.add(Notification(
            user_id=admin_id,
            title="Новое предложение события",
            message=f"{user.name} предлагает событие «{payload.event.title}».",
        ))
    await session.commit()
    await session.refresh(proposal)
    return EventProposalResponse(
        id=proposal.id,
        author_id=user.id,
        author_name=user.name,
        event=payload.event,
        message=proposal.message,
        status=proposal.status,
        created_at=proposal.created_at,
    )


@app.get("/api/v1/event-proposals", response_model=list[EventProposalResponse])
async def list_event_proposals(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[EventProposalResponse]:
    if user.account_type != "admin":
        raise HTTPException(status_code=403, detail="Administrator access required")
    rows = (await session.execute(
        select(EventProposal, User)
        .join(User, User.id == EventProposal.author_id)
        .order_by(EventProposal.created_at.desc())
    )).all()
    return [
        EventProposalResponse(
            id=proposal.id,
            author_id=author.id,
            author_name=author.name,
            event=OpportunityCreate(**proposal.event_data),
            message=proposal.message,
            status=proposal.status,
            created_at=proposal.created_at,
        )
        for proposal, author in rows
    ]


@app.patch("/api/v1/event-proposals/{proposal_id}", response_model=EventProposalResponse)
async def decide_event_proposal(
    proposal_id: uuid.UUID,
    payload: EventProposalDecision,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> EventProposalResponse:
    if user.account_type != "admin":
        raise HTTPException(status_code=403, detail="Administrator access required")
    proposal = await session.scalar(
        select(EventProposal).where(EventProposal.id == proposal_id).with_for_update()
    )
    if proposal is None:
        raise HTTPException(status_code=404, detail="Event proposal not found")
    if proposal.status != "pending":
        raise HTTPException(status_code=409, detail="Event proposal has already been reviewed")
    author = await session.get(User, proposal.author_id)
    if author is None:
        raise HTTPException(status_code=404, detail="Proposal author not found")
    event = OpportunityCreate(**proposal.event_data)
    proposal.status = payload.status
    if payload.status == "approved":
        session.add(Opportunity(
            owner_id=author.id,
            organizer=author.organization_name or author.name,
            **event.model_dump(),
        ))
    session.add(Notification(
        user_id=author.id,
        title="Предложение события рассмотрено",
        message=f"Событие «{event.title}» {'опубликовано' if payload.status == 'approved' else 'отклонено'}.",
    ))
    await session.commit()
    await session.refresh(proposal)
    return EventProposalResponse(
        id=proposal.id,
        author_id=author.id,
        author_name=author.name,
        event=event,
        message=proposal.message,
        status=proposal.status,
        created_at=proposal.created_at,
    )


@app.get("/api/v1/opportunities/{opportunity_id}/attendance", response_model=AttendanceResponse)
async def attendance_state(opportunity_id: uuid.UUID, user: User = Depends(current_user),
                           session: AsyncSession = Depends(get_session)) -> AttendanceResponse:
    opportunity = await session.get(Opportunity, opportunity_id)
    if opportunity is None or not opportunity.published:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    attendance = await session.scalar(select(OpportunityAttendance).where(
        OpportunityAttendance.user_id == user.id, OpportunityAttendance.opportunity_id == opportunity_id))
    friend_ids = select(Friendship.addressee_id).where(
        Friendship.requester_id == user.id, Friendship.status == FriendshipStatus.accepted
    ).union(select(Friendship.requester_id).where(
        Friendship.addressee_id == user.id, Friendship.status == FriendshipStatus.accepted))
    friends = (await session.scalars(select(User).join(
        OpportunityAttendance, OpportunityAttendance.user_id == User.id
    ).where(OpportunityAttendance.opportunity_id == opportunity_id, User.id.in_(friend_ids))
        .order_by(User.name))).all()
    return AttendanceResponse(going=attendance is not None, attended=attendance.attended if attendance else False,
                              friends=[AttendingFriend(id=f.id, name=f.name) for f in friends])


@app.put("/api/v1/opportunities/{opportunity_id}/attendance", status_code=status.HTTP_204_NO_CONTENT)
async def mark_going(opportunity_id: uuid.UUID, user: User = Depends(current_user),
                     session: AsyncSession = Depends(get_session)) -> None:
    opportunity = await session.get(Opportunity, opportunity_id)
    if opportunity is None or not opportunity.published:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    await session.execute(pg_insert(OpportunityAttendance).values(id=uuid.uuid4(), user_id=user.id,
        opportunity_id=opportunity_id).on_conflict_do_nothing(index_elements=["user_id", "opportunity_id"]))
    await session.commit()


@app.delete("/api/v1/opportunities/{opportunity_id}/attendance", status_code=status.HTTP_204_NO_CONTENT)
async def unmark_going(opportunity_id: uuid.UUID, user: User = Depends(current_user),
                       session: AsyncSession = Depends(get_session)) -> None:
    await session.execute(delete(OpportunityAttendance).where(OpportunityAttendance.user_id == user.id,
        OpportunityAttendance.opportunity_id == opportunity_id))
    await session.commit()


@app.put("/api/v1/opportunities/{opportunity_id}/attendance/attended", status_code=status.HTTP_204_NO_CONTENT)
async def mark_attended(opportunity_id: uuid.UUID, user: User = Depends(current_user),
                        session: AsyncSession = Depends(get_session)) -> None:
    opportunity = await session.get(Opportunity, opportunity_id)
    if opportunity is None or not opportunity.published:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    if opportunity.starts_at is None or opportunity.starts_at > date.today():
        raise HTTPException(status_code=409, detail="Attendance can be added after the event starts")
    attendance = await session.scalar(select(OpportunityAttendance).where(
        OpportunityAttendance.user_id == user.id, OpportunityAttendance.opportunity_id == opportunity_id))
    if attendance is None:
        raise HTTPException(status_code=409, detail="Mark your plans first")
    attendance.attended = True
    await session.commit()


@app.post("/api/v1/opportunities/{opportunity_id}/invite/{friend_id}", status_code=status.HTTP_204_NO_CONTENT)
async def invite_to_opportunity(opportunity_id: uuid.UUID, friend_id: uuid.UUID,
                                user: User = Depends(current_user),
                                session: AsyncSession = Depends(get_session)) -> None:
    opportunity = await session.get(Opportunity, opportunity_id)
    if opportunity is None or not opportunity.published:
        raise HTTPException(status_code=404, detail="Opportunity not found")
    friendship = await friendship_between(user.id, friend_id, session)
    if friendship is None or friendship.status != FriendshipStatus.accepted:
        raise HTTPException(status_code=403, detail="You can invite only friends")
    session.add(Notification(user_id=friend_id, title="Приглашение на событие",
                             message=f"{user.name} приглашает вас на «{opportunity.title}»."))
    await session.commit()


@app.get("/api/v1/bookmarks", response_model=list[OpportunityResponse])
async def list_bookmarks(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[Opportunity]:
    query = (
        select(Opportunity)
        .join(Bookmark, Bookmark.opportunity_id == Opportunity.id)
        .where(Bookmark.user_id == user.id, Opportunity.published.is_(True))
        .order_by(Opportunity.deadline.asc())
    )
    return list((await session.scalars(query)).all())


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


@app.delete("/api/v1/opportunities/{opportunity_id}/bookmark", status_code=status.HTTP_204_NO_CONTENT)
async def remove_bookmark(
    opportunity_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    existing = await session.scalar(
        select(Bookmark).where(
            Bookmark.user_id == user.id,
            Bookmark.opportunity_id == opportunity_id,
        )
    )
    if existing is not None:
        await session.delete(existing)
        await session.commit()


@app.get("/api/v1/projects", response_model=list[ProjectResponse])
async def list_projects(session: AsyncSession = Depends(get_session)) -> list[Project]:
    query = select(Project).options(selectinload(Project.roles)).order_by(Project.created_at.desc())
    return list((await session.scalars(query)).unique().all())


@app.post("/api/v1/recommendations/projects", response_model=list[ModelMatch])
async def recommend_projects(user: User = Depends(current_user),
                             session: AsyncSession = Depends(get_session)) -> list[ModelMatch]:
    settings = get_settings()
    if not settings.ai_ollama_url or not settings.ai_ollama_model:
        raise HTTPException(status_code=503, detail="AI recommendations are not configured")
    if not user.skills and not user.interests:
        return []
    query = (select(Project).options(selectinload(Project.roles))
             .where(Project.owner_id != user.id, Project.roles.any(ProjectRole.is_open.is_(True)))
             .order_by(Project.created_at.desc()).limit(12))
    projects = list((await session.scalars(query)).unique().all())
    candidates = [{"id": str(project.id), "title": project.title[:120], "category": project.category[:80],
                   "summary": project.summary[:220],
                   "roles": [{"title": role.title[:80], "skills": role.skills[:120]}
                             for role in project.roles if role.is_open][:5]}
                  for project in projects]
    try:
        await asyncio.wait_for(ai_request_slot.acquire(), timeout=1)
        try:
            return await rank_projects(settings.ai_ollama_url, settings.ai_ollama_model,
                                       [value[:120] for value in user.skills],
                                       [value[:120] for value in user.interests], candidates)
        finally:
            ai_request_slot.release()
    except (httpx.HTTPError, ValueError, TimeoutError) as error:
        raise HTTPException(status_code=503, detail="AI recommendations temporarily unavailable") from error


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


@app.patch("/api/v1/projects/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: uuid.UUID,
    payload: ProjectUpdate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> Project:
    project = await session.get(Project, project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Only the project owner can edit it")

    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(project, field, value)
    await session.commit()
    query = select(Project).options(selectinload(Project.roles)).where(Project.id == project.id)
    return (await session.scalars(query)).one()


@app.delete("/api/v1/projects/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_project(
    project_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    project = await session.get(Project, project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Only the project owner can delete it")
    await session.delete(project)
    await session.commit()


async def owned_project_for_role(
    role_id: uuid.UUID,
    user: User,
    session: AsyncSession,
) -> tuple[ProjectRole, Project]:
    role = await session.get(ProjectRole, role_id)
    if role is None:
        raise HTTPException(status_code=404, detail="Project role not found")
    project = await session.get(Project, role.project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Only the project owner can manage roles")
    return role, project


@app.post(
    "/api/v1/projects/{project_id}/roles",
    response_model=RoleResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_project_role(
    project_id: uuid.UUID,
    payload: RoleCreate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> ProjectRole:
    project = await session.get(Project, project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Only the project owner can manage roles")
    role = ProjectRole(project_id=project.id, title=payload.title, skills=payload.skills)
    session.add(role)
    await session.commit()
    await session.refresh(role)
    return role


@app.patch("/api/v1/project-roles/{role_id}", response_model=RoleResponse)
async def update_project_role(
    role_id: uuid.UUID,
    payload: RoleUpdate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> ProjectRole:
    role, _ = await owned_project_for_role(role_id, user, session)
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(role, field, value)
    await session.commit()
    await session.refresh(role)
    return role


@app.delete("/api/v1/project-roles/{role_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_project_role(
    role_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    role, _ = await owned_project_for_role(role_id, user, session)
    await session.delete(role)
    await session.commit()


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
    project = await session.get(Project, role.project_id)
    if project is not None and project.owner_id != user.id:
        session.add(
            Notification(
                user_id=project.owner_id,
                title="Новый отклик",
                message=f"{user.name} откликнулся на роль «{role.title}» в проекте «{project.title}».",
            )
        )
    await session.commit()
    await session.refresh(application)
    return {"id": application.id}


def application_response(
    application: Application,
    applicant: User,
    role: ProjectRole,
    project: Project,
) -> ApplicationResponse:
    return ApplicationResponse(
        id=application.id,
        user_id=applicant.id,
        user_name=applicant.name,
        role_id=role.id,
        role_title=role.title,
        project_id=project.id,
        project_title=project.title,
        status=application.status.value,
    )


@app.get("/api/v1/applications/mine", response_model=list[ApplicationResponse])
async def my_applications(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[ApplicationResponse]:
    query = (
        select(Application, User, ProjectRole, Project)
        .join(User, User.id == Application.user_id)
        .join(ProjectRole, ProjectRole.id == Application.project_role_id)
        .join(Project, Project.id == ProjectRole.project_id)
        .where(Application.user_id == user.id)
    )
    rows = (await session.execute(query)).all()
    return [application_response(*row) for row in rows]


@app.get("/api/v1/applications/received", response_model=list[ApplicationResponse])
async def received_applications(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[ApplicationResponse]:
    query = (
        select(Application, User, ProjectRole, Project)
        .join(User, User.id == Application.user_id)
        .join(ProjectRole, ProjectRole.id == Application.project_role_id)
        .join(Project, Project.id == ProjectRole.project_id)
        .where(Project.owner_id == user.id)
    )
    rows = (await session.execute(query)).all()
    return [application_response(*row) for row in rows]


@app.patch("/api/v1/applications/{application_id}", response_model=ApplicationResponse)
async def decide_application(
    application_id: uuid.UUID,
    payload: ApplicationStatusUpdate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> ApplicationResponse:
    query = (
        select(Application, User, ProjectRole, Project)
        .join(User, User.id == Application.user_id)
        .join(ProjectRole, ProjectRole.id == Application.project_role_id)
        .join(Project, Project.id == ProjectRole.project_id)
        .where(Application.id == application_id)
    )
    row = (await session.execute(query)).one_or_none()
    if row is None:
        raise HTTPException(status_code=404, detail="Application not found")
    application, applicant, role, project = row
    if project.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Only the project owner can decide applications")

    # Serialize decisions for a project so that two accepted applications cannot
    # occupy one role or race while creating the team's chat.
    await session.execute(select(Project.id).where(Project.id == project.id).with_for_update())
    await session.refresh(application)
    await session.refresh(role)
    if application.status != ApplicationStatus.pending:
        raise HTTPException(status_code=409, detail="Application has already been decided")
    if payload.status == "accepted" and not role.is_open:
        raise HTTPException(status_code=409, detail="Project role is already closed")

    application.status = ApplicationStatus(payload.status)
    decision_text = "принята" if payload.status == "accepted" else "отклонена"
    session.add(
        Notification(
            user_id=application.user_id,
            title="Решение по заявке",
            message=f"Ваша заявка на роль «{role.title}» в проекте «{project.title}» {decision_text}.",
        )
    )
    if payload.status == "accepted":
        role.is_open = False
        await session.execute(
            update(Application)
            .where(
                Application.project_role_id == role.id,
                Application.id != application.id,
            )
            .values(status=ApplicationStatus.rejected)
        )
        await create_project_chat_if_team_complete(project, session)
    await session.commit()
    return application_response(application, applicant, role, project)


async def create_project_chat_if_team_complete(
    project: Project,
    session: AsyncSession,
) -> ProjectChat | None:
    roles = list(await session.scalars(select(ProjectRole).where(ProjectRole.project_id == project.id)))
    accepted_role_ids = set(await session.scalars(
        select(Application.project_role_id)
        .join(ProjectRole, ProjectRole.id == Application.project_role_id)
        .where(ProjectRole.project_id == project.id, Application.status == ApplicationStatus.accepted)
    ))
    if not roles or any(role.is_open or role.id not in accepted_role_ids for role in roles):
        return None

    chat = await session.scalar(select(ProjectChat).where(ProjectChat.project_id == project.id))
    if chat is None:
        chat = ProjectChat(project_id=project.id)
        session.add(chat)
        await session.flush()

    accepted_user_ids = set(
        await session.scalars(
            select(Application.user_id)
            .join(ProjectRole, ProjectRole.id == Application.project_role_id)
            .where(
                ProjectRole.project_id == project.id,
                Application.status == ApplicationStatus.accepted,
            )
        )
    )
    member_ids = accepted_user_ids | {project.owner_id}
    existing_ids = set(
        await session.scalars(select(ChatMember.user_id).where(ChatMember.chat_id == chat.id))
    )
    for member_id in member_ids - existing_ids:
        session.add(ChatMember(chat_id=chat.id, user_id=member_id))
        session.add(
            Notification(
                user_id=member_id,
                title="Команда собрана",
                message=f"Проект «{project.title}» готов к работе. Проектный чат уже открыт.",
            )
        )
    return chat


@app.delete("/api/v1/applications/{application_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_application(
    application_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    application = await session.get(Application, application_id)
    if application is None:
        raise HTTPException(status_code=404, detail="Application not found")
    if application.user_id != user.id:
        raise HTTPException(status_code=403, detail="Only the applicant can cancel it")
    if application.status.value == "accepted":
        raise HTTPException(status_code=409, detail="Accepted application cannot be cancelled")
    await session.delete(application)
    await session.commit()


@app.get("/api/v1/profile/me", response_model=ProfileResponse)
async def my_profile(user: User = Depends(current_user)) -> User:
    return user


@app.patch("/api/v1/profile/me", response_model=ProfileResponse)
async def update_my_profile(
    payload: ProfileUpdate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    for field, value in payload.model_dump(exclude_none=True).items():
        if isinstance(value, list):
            value = [item.strip() for item in value if item.strip()]
        setattr(user, field, value)
    await session.commit()
    await session.refresh(user)
    return user


@app.patch("/api/v1/profile/organization", response_model=ProfileResponse)
async def enable_organization_profile(
    payload: OrganizationProfileUpdate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    name = payload.organization_name.strip()
    if len(name) < 2:
        raise HTTPException(status_code=422, detail="Organization name is too short")
    if user.account_type in {"admin", "organization"}:
        raise HTTPException(status_code=409, detail="Account already has publishing access")
    if user.organization_status == "pending":
        raise HTTPException(status_code=409, detail="Organization application is already pending")
    user.organization_name = name
    user.organization_status = "pending"
    admin_ids = list(await session.scalars(select(User.id).where(User.account_type == "admin")))
    for admin_id in admin_ids:
        session.add(Notification(user_id=admin_id, title="Заявка организации", message=f"{user.name}: {name}"))
    await session.commit()
    await session.refresh(user)
    return user


@app.get("/api/v1/organization-applications", response_model=list[OrganizationApplicationResponse])
async def list_organization_applications(
    user: User = Depends(current_user), session: AsyncSession = Depends(get_session)
) -> list[OrganizationApplicationResponse]:
    if user.account_type != "admin":
        raise HTTPException(status_code=403, detail="Administrator access required")
    applicants = (await session.scalars(select(User).where(User.organization_status == "pending"))).all()
    return [OrganizationApplicationResponse.model_validate(applicant, from_attributes=True) for applicant in applicants]


@app.patch("/api/v1/organization-applications/{user_id}", response_model=OrganizationApplicationResponse)
async def decide_organization_application(
    user_id: uuid.UUID, payload: OrganizationDecision,
    user: User = Depends(current_user), session: AsyncSession = Depends(get_session)
) -> OrganizationApplicationResponse:
    if user.account_type != "admin":
        raise HTTPException(status_code=403, detail="Administrator access required")
    applicant = await session.scalar(select(User).where(User.id == user_id).with_for_update())
    if applicant is None:
        raise HTTPException(status_code=404, detail="Application not found")
    if applicant.organization_status != "pending":
        raise HTTPException(status_code=409, detail="Application is not pending")
    applicant.organization_status = payload.status
    if payload.status == "approved":
        applicant.account_type = "organization"
    session.add(Notification(user_id=applicant.id, title="Заявка организации рассмотрена", message=(
        "Профиль организации подтверждён." if payload.status == "approved" else "Заявка организации отклонена. Вы можете подать её снова."
    )))
    await session.commit()
    await session.refresh(applicant)
    return OrganizationApplicationResponse.model_validate(applicant, from_attributes=True)


async def friendship_between(
    first_id: uuid.UUID,
    second_id: uuid.UUID,
    session: AsyncSession,
) -> Friendship | None:
    return await session.scalar(
        select(Friendship).where(
            or_(
                and_(Friendship.requester_id == first_id, Friendship.addressee_id == second_id),
                and_(Friendship.requester_id == second_id, Friendship.addressee_id == first_id),
            )
        )
    )


def friendship_label(friendship: Friendship | None, user_id: uuid.UUID) -> str:
    if friendship is None:
        return "none"
    if friendship.status == FriendshipStatus.accepted:
        return "friends"
    return "pending_sent" if friendship.requester_id == user_id else "pending_received"


@app.get("/api/v1/profiles/{profile_id}", response_model=PublicProfileResponse)
async def public_profile(
    profile_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> PublicProfileResponse:
    profile = await session.get(User, profile_id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    status_value = "self" if profile.id == user.id else friendship_label(
        await friendship_between(user.id, profile.id, session), user.id
    )
    memberships = (await session.execute(
        select(Project.id, Project.title, ProjectRole.title, ProjectRole.id)
        .join(ProjectRole, ProjectRole.project_id == Project.id)
        .join(Application, Application.project_role_id == ProjectRole.id)
        .where(Application.user_id == profile.id, Application.status == ApplicationStatus.accepted)
    )).all()
    owned = (await session.execute(select(Project.id, Project.title, Project.owner_role)
        .where(Project.owner_id == profile.id))).all()
    attended_events = (await session.scalars(select(Opportunity).join(
        OpportunityAttendance, OpportunityAttendance.opportunity_id == Opportunity.id
    ).where(OpportunityAttendance.user_id == profile.id, OpportunityAttendance.attended.is_(True),
            Opportunity.published.is_(True)))).all()
    return PublicProfileResponse(
        id=profile.id,
        name=profile.name,
        region=profile.region,
        bio=profile.bio,
        skills=profile.skills,
        interests=profile.interests,
        friendship_status=status_value,
        projects=([PortfolioProject(id=row[0], title=row[1], role=row[2]) for row in owned] +
                  [PortfolioProject(id=row[0], title=row[1], role=row[2], role_id=row[3]) for row in memberships]),
        events=[PortfolioEvent(id=event.id, title=event.title, starts_at=event.starts_at) for event in attended_events],
    )


@app.get("/api/v1/profiles/{profile_id}/avatar", response_model=AvatarRequest)
async def public_profile_avatar(
    profile_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> AvatarRequest:
    profile = await session.get(User, profile_id)
    if profile is None or profile.avatar_data is None:
        raise HTTPException(status_code=404, detail="Avatar not found")
    return AvatarRequest(
        data=base64.b64encode(profile.avatar_data).decode(),
        content_type=profile.avatar_content_type or "image/jpeg",
    )


@app.get("/api/v1/friends", response_model=list[FriendResponse])
async def list_friends(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[FriendResponse]:
    friendships = list(
        await session.scalars(
            select(Friendship)
            .where(or_(Friendship.requester_id == user.id, Friendship.addressee_id == user.id))
            .order_by(Friendship.created_at.desc())
        )
    )
    responses: list[FriendResponse] = []
    for friendship in friendships:
        other_id = friendship.addressee_id if friendship.requester_id == user.id else friendship.requester_id
        other = await session.get(User, other_id)
        if other is not None:
            responses.append(
                FriendResponse(
                    friendship_id=friendship.id,
                    user_id=other.id,
                    name=other.name,
                    region=other.region,
                    status=friendship_label(friendship, user.id),
                )
            )
    return responses


@app.post("/api/v1/friends/{profile_id}", response_model=FriendResponse, status_code=status.HTTP_201_CREATED)
async def request_friendship(
    profile_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> FriendResponse:
    if profile_id == user.id:
        raise HTTPException(status_code=409, detail="Cannot add yourself as a friend")
    other = await session.get(User, profile_id)
    if other is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    existing = await friendship_between(user.id, profile_id, session)
    if existing is not None:
        raise HTTPException(status_code=409, detail="Friendship already exists")
    friendship = Friendship(requester_id=user.id, addressee_id=profile_id)
    session.add(friendship)
    session.add(
        Notification(
            user_id=profile_id,
            title="Новая заявка в друзья",
            message=f"{user.name} хочет добавить вас в друзья.",
        )
    )
    await session.commit()
    await session.refresh(friendship)
    return FriendResponse(
        friendship_id=friendship.id,
        user_id=other.id,
        name=other.name,
        region=other.region,
        status="pending_sent",
    )


@app.patch("/api/v1/friends/{friendship_id}/accept", response_model=FriendResponse)
async def accept_friendship(
    friendship_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> FriendResponse:
    friendship = await session.get(Friendship, friendship_id)
    if friendship is None or friendship.addressee_id != user.id:
        raise HTTPException(status_code=404, detail="Friend request not found")
    friendship.status = FriendshipStatus.accepted
    requester = await session.get(User, friendship.requester_id)
    session.add(
        Notification(
            user_id=friendship.requester_id,
            title="Заявка принята",
            message=f"{user.name} теперь у вас в друзьях.",
        )
    )
    await session.commit()
    return FriendResponse(
        friendship_id=friendship.id,
        user_id=friendship.requester_id,
        name=requester.name if requester else "Пользователь",
        region=requester.region if requester else "",
        status="friends",
    )


@app.delete("/api/v1/friends/{friendship_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_friendship(
    friendship_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    friendship = await session.get(Friendship, friendship_id)
    if friendship is None or user.id not in (friendship.requester_id, friendship.addressee_id):
        raise HTTPException(status_code=404, detail="Friendship not found")
    await session.delete(friendship)
    await session.commit()


async def require_chat_member(
    chat_id: uuid.UUID,
    user_id: uuid.UUID,
    session: AsyncSession,
) -> ProjectChat:
    chat = await session.get(ProjectChat, chat_id)
    membership = await session.scalar(
        select(ChatMember).where(ChatMember.chat_id == chat_id, ChatMember.user_id == user_id)
    )
    if chat is None or membership is None:
        raise HTTPException(status_code=404, detail="Chat not found")
    return chat


@app.get("/api/v1/chats/{chat_id}/workspace", response_model=TeamWorkspaceData)
async def get_workspace(chat_id: uuid.UUID, user: User = Depends(current_user),
                        session: AsyncSession = Depends(get_session)) -> TeamWorkspaceData:
    await require_chat_member(chat_id, user.id, session)
    workspace = await session.get(TeamWorkspace, chat_id)
    return TeamWorkspaceData(links=workspace.links, meeting=workspace.meeting) if workspace else TeamWorkspaceData()


@app.put("/api/v1/chats/{chat_id}/workspace", response_model=TeamWorkspaceData)
async def update_workspace(chat_id: uuid.UUID, payload: TeamWorkspaceData, user: User = Depends(current_user),
                           session: AsyncSession = Depends(get_session)) -> TeamWorkspaceData:
    await require_chat_member(chat_id, user.id, session)
    await session.execute(pg_insert(TeamWorkspace).values(chat_id=chat_id, links=payload.links, meeting=payload.meeting)
        .on_conflict_do_update(index_elements=["chat_id"], set_={"links": payload.links, "meeting": payload.meeting}))
    await session.commit()
    return payload


@app.get("/api/v1/chats/{chat_id}/tasks", response_model=list[TeamTaskResponse])
async def list_team_tasks(chat_id: uuid.UUID, user: User = Depends(current_user),
                          session: AsyncSession = Depends(get_session)) -> list[TeamTask]:
    await require_chat_member(chat_id, user.id, session)
    return list(await session.scalars(select(TeamTask).where(TeamTask.chat_id == chat_id).order_by(TeamTask.created_at)))


@app.post("/api/v1/chats/{chat_id}/tasks", response_model=TeamTaskResponse, status_code=status.HTTP_201_CREATED)
async def create_team_task(chat_id: uuid.UUID, payload: TeamTaskCreate, user: User = Depends(current_user),
                           session: AsyncSession = Depends(get_session)) -> TeamTask:
    await require_chat_member(chat_id, user.id, session)
    title = payload.title.strip()
    if not title:
        raise HTTPException(status_code=422, detail="Task title cannot be empty")
    task = TeamTask(chat_id=chat_id, title=title)
    session.add(task)
    await session.commit()
    await session.refresh(task)
    return task


@app.patch("/api/v1/chats/{chat_id}/tasks/{task_id}", response_model=TeamTaskResponse)
async def update_team_task(chat_id: uuid.UUID, task_id: uuid.UUID, payload: TeamTaskUpdate,
                           user: User = Depends(current_user), session: AsyncSession = Depends(get_session)) -> TeamTask:
    await require_chat_member(chat_id, user.id, session)
    task = await session.scalar(select(TeamTask).where(TeamTask.id == task_id, TeamTask.chat_id == chat_id))
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    task.done = payload.done
    await session.commit()
    return task


@app.delete("/api/v1/chats/{chat_id}/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_team_task(chat_id: uuid.UUID, task_id: uuid.UUID, user: User = Depends(current_user),
                           session: AsyncSession = Depends(get_session)) -> None:
    await require_chat_member(chat_id, user.id, session)
    await session.execute(delete(TeamTask).where(TeamTask.id == task_id, TeamTask.chat_id == chat_id))
    await session.commit()


@app.get("/api/v1/chats", response_model=list[ChatResponse])
async def list_chats(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[ChatResponse]:
    rows = (
        await session.execute(
            select(ProjectChat, Project)
            .join(ChatMember, ChatMember.chat_id == ProjectChat.id)
            .join(Project, Project.id == ProjectChat.project_id)
            .where(ChatMember.user_id == user.id)
            .order_by(ProjectChat.created_at.desc())
        )
    ).all()
    responses: list[ChatResponse] = []
    for chat, project in rows:
        member_count = await session.scalar(
            select(func.count(ChatMember.id)).where(ChatMember.chat_id == chat.id)
        )
        last_message = await session.scalar(
            select(ChatMessage)
            .where(ChatMessage.chat_id == chat.id)
            .order_by(ChatMessage.created_at.desc())
            .limit(1)
        )
        responses.append(
            ChatResponse(
                id=chat.id,
                project_id=project.id,
                project_title=project.title,
                member_count=member_count or 0,
                last_message=last_message.text if last_message else None,
                last_message_at=last_message.created_at if last_message else None,
            )
        )
    return responses


@app.get("/api/v1/chats/{chat_id}/messages", response_model=list[ChatMessageResponse])
async def list_chat_messages(
    chat_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[ChatMessageResponse]:
    await require_chat_member(chat_id, user.id, session)
    rows = (
        await session.execute(
            select(ChatMessage, User)
            .join(User, User.id == ChatMessage.sender_id)
            .where(ChatMessage.chat_id == chat_id)
            .order_by(ChatMessage.created_at.asc())
            .limit(500)
        )
    ).all()
    return [
        ChatMessageResponse(
            id=message.id,
            chat_id=message.chat_id,
            sender_id=message.sender_id,
            sender_name=sender.name,
            text=message.text,
            created_at=message.created_at,
        )
        for message, sender in rows
    ]


@app.post(
    "/api/v1/chats/{chat_id}/messages",
    response_model=ChatMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def send_chat_message(
    chat_id: uuid.UUID,
    payload: ChatMessageCreate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> ChatMessageResponse:
    chat = await require_chat_member(chat_id, user.id, session)
    message = ChatMessage(chat_id=chat.id, sender_id=user.id, text=payload.text.strip())
    session.add(message)
    project = await session.get(Project, chat.project_id)
    recipient_ids = await session.scalars(
        select(ChatMember.user_id).where(
            ChatMember.chat_id == chat.id,
            ChatMember.user_id != user.id,
        )
    )
    for recipient_id in recipient_ids:
        session.add(
            Notification(
                user_id=recipient_id,
                title=project.title if project else "Новое сообщение",
                message=f"{user.name}: {message.text[:120]}",
            )
        )
    await session.commit()
    await session.refresh(message)
    return ChatMessageResponse(
        id=message.id,
        chat_id=message.chat_id,
        sender_id=message.sender_id,
        sender_name=user.name,
        text=message.text,
        created_at=message.created_at,
    )


@app.delete("/api/v1/profile/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    await session.delete(user)
    await session.commit()


@app.get("/api/v1/notifications", response_model=list[NotificationResponse])
async def list_notifications(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[Notification]:
    query = (
        select(Notification)
        .where(Notification.user_id == user.id)
        .order_by(Notification.created_at.desc())
        .limit(100)
    )
    return list((await session.scalars(query)).all())


@app.patch("/api/v1/notifications/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_notification_read(
    notification_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    notification = await session.get(Notification, notification_id)
    if notification is None or notification.user_id != user.id:
        raise HTTPException(status_code=404, detail="Notification not found")
    notification.is_read = True
    await session.commit()


@app.get("/api/v1/profile/avatar", response_model=AvatarRequest)
async def profile_avatar(user: User = Depends(current_user)) -> AvatarRequest:
    if user.avatar_data is None:
        raise HTTPException(status_code=404, detail="Avatar not found")
    return AvatarRequest(
        data=base64.b64encode(user.avatar_data).decode(),
        content_type=user.avatar_content_type or "image/jpeg",
    )


@app.put("/api/v1/profile/avatar", status_code=status.HTTP_204_NO_CONTENT)
async def update_profile_avatar(
    payload: AvatarRequest,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    try:
        image_data = payload.decoded_data()
    except ValueError as error:
        raise HTTPException(status_code=422, detail="Invalid avatar data") from error
    if len(image_data) > 2_000_000:
        raise HTTPException(status_code=413, detail="Avatar is too large")
    if not image_data:
        raise HTTPException(status_code=422, detail="Invalid avatar data")
    user.avatar_data = image_data
    user.avatar_content_type = payload.content_type
    await session.commit()


@app.delete("/api/v1/profile/avatar", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile_avatar(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    user.avatar_data = None
    user.avatar_content_type = None
    await session.commit()


@app.get("/api/v1/achievements", response_model=list[AchievementResponse])
async def list_achievements(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> list[Achievement]:
    query = (
        select(Achievement)
        .where(Achievement.user_id == user.id)
        .order_by(Achievement.issued_at.desc())
    )
    return list((await session.scalars(query)).all())


@app.post(
    "/api/v1/achievements",
    response_model=AchievementResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_achievement(
    payload: AchievementCreate,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> Achievement:
    achievement = Achievement(user_id=user.id, **payload.model_dump())
    session.add(achievement)
    await session.commit()
    await session.refresh(achievement)
    return achievement


@app.delete("/api/v1/achievements/{achievement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_achievement(
    achievement_id: uuid.UUID,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    achievement = await session.get(Achievement, achievement_id)
    if achievement is None:
        raise HTTPException(status_code=404, detail="Achievement not found")
    if achievement.user_id != user.id:
        raise HTTPException(status_code=403, detail="Achievement belongs to another user")
    await session.delete(achievement)
    await session.commit()
