import asyncio
import base64
import os
import uuid

import httpx
from sqlalchemy import delete, text

from app.database import SessionFactory, engine
from app.models import User


BASE_URL = os.getenv("TEST_BASE_URL", "http://api:8000")


def create_verified_user(client: httpx.Client, email: str, name: str) -> dict[str, str]:
    password = "spark-social-password"
    registration = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": password, "name": name},
    )
    assert registration.status_code == 201
    verification = client.post(
        "/api/v1/auth/verify-email",
        json={"email": email, "code": registration.json()["development_code"]},
    )
    assert verification.status_code == 200
    login = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login.status_code == 200
    return {"Authorization": f"Bearer {login.json()['access_token']}"}


def test_full_user_scenario() -> None:
    email = f"spark-{uuid.uuid4()}@example.com"

    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            health = client.get("/health")
            assert health.status_code == 200
            assert health.json() == {"status": "ok", "database": "ok"}

            liveness = client.get("/health/live")
            assert liveness.status_code == 200
            assert liveness.json() == {"status": "ok"}

            opportunities = client.get("/api/v1/opportunities")
            assert opportunities.status_code == 200
            assert len(opportunities.json()) >= 4
            opportunity_id = opportunities.json()[0]["id"]

            registration = client.post(
                "/api/v1/auth/register",
                json={"email": email, "password": "spark-test-password", "name": "Spark Test"},
            )
            assert registration.status_code == 201
            verification_code = registration.json()["development_code"]
            assert verification_code

            verification = client.post(
                "/api/v1/auth/verify-email",
                json={"email": email, "code": verification_code},
            )
            assert verification.status_code == 200

            login = client.post(
                "/api/v1/auth/login",
                json={"email": email, "password": "spark-test-password"},
            )
            assert login.status_code == 200
            token = login.json()["access_token"]
            headers = {"Authorization": f"Bearer {token}"}

            forgot = client.post("/api/v1/auth/forgot-password", json={"email": email})
            assert forgot.status_code == 200
            reset_code = forgot.json()["development_code"]
            assert reset_code

            reset = client.post(
                "/api/v1/auth/reset-password",
                json={
                    "email": email,
                    "code": reset_code,
                    "new_password": "spark-updated-password",
                },
            )
            assert reset.status_code == 200

            updated_login = client.post(
                "/api/v1/auth/login",
                json={"email": email, "password": "spark-updated-password"},
            )
            assert updated_login.status_code == 200

            profile = client.get("/api/v1/profile/me", headers=headers)
            assert profile.status_code == 200
            assert profile.json()["email"] == email

            avatar_data = base64.b64encode(b"spark-avatar-test").decode()
            avatar_update = client.put(
                "/api/v1/profile/avatar",
                headers=headers,
                json={"data": avatar_data, "content_type": "image/jpeg"},
            )
            assert avatar_update.status_code == 204
            avatar = client.get("/api/v1/profile/avatar", headers=headers)
            assert avatar.status_code == 200
            assert avatar.json()["data"] == avatar_data

            achievement = client.post(
                "/api/v1/achievements",
                headers=headers,
                json={
                    "title": "Hackathon Finalist",
                    "issuer": "Spark Test",
                    "issued_at": "2026-11-12",
                },
            )
            assert achievement.status_code == 201
            achievement_id = achievement.json()["id"]

            achievements = client.get("/api/v1/achievements", headers=headers)
            assert achievements.status_code == 200
            assert achievement_id in {item["id"] for item in achievements.json()}

            deleted_achievement = client.delete(
                f"/api/v1/achievements/{achievement_id}",
                headers=headers,
            )
            assert deleted_achievement.status_code == 204

            bookmark = client.post(
                f"/api/v1/opportunities/{opportunity_id}/bookmark",
                headers=headers,
            )
            assert bookmark.status_code == 204

            bookmarks = client.get("/api/v1/bookmarks", headers=headers)
            assert bookmarks.status_code == 200
            assert opportunity_id in {item["id"] for item in bookmarks.json()}

            removed_bookmark = client.delete(
                f"/api/v1/opportunities/{opportunity_id}/bookmark",
                headers=headers,
            )
            assert removed_bookmark.status_code == 204

            created = client.post(
                "/api/v1/projects",
                headers=headers,
                json={
                    "category": "EdTech",
                    "title": "Integration Test Project",
                    "summary": "Project created by the complete API integration test.",
                    "owner_role": "iOS Developer",
                    "roles": [
                        {"title": "Backend Developer", "skills": "FastAPI"},
                        {"title": "Designer", "skills": "Figma"},
                    ],
                },
            )
            assert created.status_code == 201
            project = created.json()
            assert project["title"] == "Integration Test Project"
            assert len(project["roles"]) == 2

            role_id = project["roles"][0]["id"]
            application = client.post(
                f"/api/v1/project-roles/{role_id}/applications",
                headers=headers,
            )
            assert application.status_code == 201

            application_id = application.json()["id"]
            mine = client.get("/api/v1/applications/mine", headers=headers)
            assert mine.status_code == 200
            assert application_id in {item["id"] for item in mine.json()}

            received = client.get("/api/v1/applications/received", headers=headers)
            assert received.status_code == 200
            assert application_id in {item["id"] for item in received.json()}

            accepted = client.patch(
                f"/api/v1/applications/{application_id}",
                headers=headers,
                json={"status": "accepted"},
            )
            assert accepted.status_code == 200
            assert accepted.json()["status"] == "accepted"

            notifications = client.get("/api/v1/notifications", headers=headers)
            assert notifications.status_code == 200
            assert notifications.json()
            notification_id = notifications.json()[0]["id"]
            marked_read = client.patch(
                f"/api/v1/notifications/{notification_id}/read",
                headers=headers,
            )
            assert marked_read.status_code == 204

            second_role_id = project["roles"][1]["id"]
            second_application = client.post(
                f"/api/v1/project-roles/{second_role_id}/applications",
                headers=headers,
            )
            assert second_application.status_code == 201
            cancelled = client.delete(
                f"/api/v1/applications/{second_application.json()['id']}",
                headers=headers,
            )
            assert cancelled.status_code == 204

            updated_project = client.patch(
                f"/api/v1/projects/{project['id']}",
                headers=headers,
                json={"title": "Updated Integration Project"},
            )
            assert updated_project.status_code == 200
            assert updated_project.json()["title"] == "Updated Integration Project"

            added_role = client.post(
                f"/api/v1/projects/{project['id']}/roles",
                headers=headers,
                json={"title": "QA Engineer", "skills": "Testing"},
            )
            assert added_role.status_code == 201

            updated_role = client.patch(
                f"/api/v1/project-roles/{added_role.json()['id']}",
                headers=headers,
                json={"skills": "Swift Testing"},
            )
            assert updated_role.status_code == 200
            assert updated_role.json()["skills"] == "Swift Testing"

            deleted_role = client.delete(
                f"/api/v1/project-roles/{added_role.json()['id']}",
                headers=headers,
            )
            assert deleted_role.status_code == 204

            deleted_project = client.delete(
                f"/api/v1/projects/{project['id']}",
                headers=headers,
            )
            assert deleted_project.status_code == 204

            deleted_account = client.delete("/api/v1/profile/me", headers=headers)
            assert deleted_account.status_code == 204

            login_after_deletion = client.post(
                "/api/v1/auth/login",
                json={"email": email, "password": "spark-updated-password"},
            )
            assert login_after_deletion.status_code == 401
    finally:
        asyncio.run(delete_test_user(email))


async def delete_test_user(email: str) -> None:
    async with SessionFactory() as session:
        await session.execute(delete(User).where(User.email == email))
        await session.commit()
    await engine.dispose()


async def make_test_admin(email: str) -> None:
    async with SessionFactory() as session:
        await session.execute(
            text("UPDATE users SET account_type = 'admin' WHERE email = :email"),
            {"email": email},
        )
        await session.commit()
    await engine.dispose()


def test_social_profile_and_project_chat() -> None:
    owner_email = f"spark-owner-{uuid.uuid4()}@example.com"
    member_email = f"spark-member-{uuid.uuid4()}@example.com"
    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            owner_headers = create_verified_user(client, owner_email, "Owner Test")
            member_headers = create_verified_user(client, member_email, "Member Test")

            updated = client.patch(
                "/api/v1/profile/me",
                headers=member_headers,
                json={
                    "region": "Минск",
                    "bio": "iOS developer",
                    "skills": ["Swift", "SwiftUI"],
                    "interests": ["EdTech"],
                },
            )
            assert updated.status_code == 200
            member_id = updated.json()["id"]
            owner_id = client.get("/api/v1/profile/me", headers=owner_headers).json()["id"]

            public_profile = client.get(f"/api/v1/profiles/{member_id}", headers=owner_headers)
            assert public_profile.status_code == 200
            assert public_profile.json()["skills"] == ["Swift", "SwiftUI"]

            friend_request = client.post(f"/api/v1/friends/{member_id}", headers=owner_headers)
            assert friend_request.status_code == 201
            friendship_id = friend_request.json()["friendship_id"]
            accepted_friend = client.patch(
                f"/api/v1/friends/{friendship_id}/accept",
                headers=member_headers,
            )
            assert accepted_friend.status_code == 200
            assert accepted_friend.json()["status"] == "friends"
            owner_friends = client.get("/api/v1/friends", headers=owner_headers)
            assert owner_friends.status_code == 200
            assert member_id in {item["user_id"] for item in owner_friends.json()}

            project_response = client.post(
                "/api/v1/projects",
                headers=owner_headers,
                json={
                    "category": "EdTech",
                    "title": "Social Integration Project",
                    "summary": "A project that verifies automatic team chat creation.",
                    "owner_role": "Founder",
                    "roles": [{"title": "iOS Developer", "skills": "SwiftUI"}],
                },
            )
            assert project_response.status_code == 201
            project = project_response.json()
            role_id = project["roles"][0]["id"]

            application = client.post(
                f"/api/v1/project-roles/{role_id}/applications",
                headers=member_headers,
            )
            assert application.status_code == 201
            decision = client.patch(
                f"/api/v1/applications/{application.json()['id']}",
                headers=owner_headers,
                json={"status": "accepted"},
            )
            assert decision.status_code == 200

            owner_chats = client.get("/api/v1/chats", headers=owner_headers)
            member_chats = client.get("/api/v1/chats", headers=member_headers)
            assert owner_chats.status_code == 200
            assert member_chats.status_code == 200
            assert len(owner_chats.json()) == 1
            chat_id = owner_chats.json()[0]["id"]
            assert owner_chats.json()[0]["member_count"] == 2

            sent = client.post(
                f"/api/v1/chats/{chat_id}/messages",
                headers=member_headers,
                json={"text": "Команда, начинаем работу!"},
            )
            assert sent.status_code == 201
            messages = client.get(f"/api/v1/chats/{chat_id}/messages", headers=owner_headers)
            assert messages.status_code == 200
            assert messages.json()[-1]["text"] == "Команда, начинаем работу!"
            owner_notifications = client.get("/api/v1/notifications", headers=owner_headers)
            assert any("Команда, начинаем" in item["message"] for item in owner_notifications.json())

            removed = client.delete(f"/api/v1/friends/{friendship_id}", headers=owner_headers)
            assert removed.status_code == 204
            assert owner_id != member_id
    finally:
        asyncio.run(delete_test_user(owner_email))
        asyncio.run(delete_test_user(member_email))


def test_organization_can_publish_mapped_opportunity() -> None:
    email = f"spark-organization-{uuid.uuid4()}@example.com"
    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            headers = create_verified_user(client, email, "Organization Owner")
            forbidden = client.post(
                "/api/v1/opportunities",
                headers=headers,
                json={
                    "category": "Мероприятия",
                    "title": "Spark Demo Event",
                    "summary": "Demo event on the map",
                    "details": "An integration test event",
                    "location_name": "Минск",
                    "latitude": 53.9023,
                    "longitude": 27.5619,
                },
            )
            assert forbidden.status_code == 403

            organization = client.patch(
                "/api/v1/profile/organization",
                headers=headers,
                json={"organization_name": "Spark Test Organization"},
            )
            assert organization.status_code == 200
            assert organization.json()["account_type"] == "organization"

            created = client.post(
                "/api/v1/opportunities",
                headers=headers,
                json={
                    "category": "Мероприятия",
                    "title": "Spark Demo Event",
                    "summary": "Demo event on the map",
                    "details": "An integration test event",
                    "location_name": "Минск",
                    "latitude": 53.9023,
                    "longitude": 27.5619,
                },
            )
            assert created.status_code == 201
            assert created.json()["organizer"] == "Spark Test Organization"
            listed = client.get("/api/v1/opportunities")
            assert created.json()["id"] in {item["id"] for item in listed.json()}
    finally:
        asyncio.run(delete_test_user(email))


def test_user_can_propose_event_and_admin_can_publish_it() -> None:
    user_email = f"spark-proposer-{uuid.uuid4()}@example.com"
    admin_email = f"spark-admin-{uuid.uuid4()}@example.com"
    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            user_headers = create_verified_user(client, user_email, "Event Proposer")
            admin_headers = create_verified_user(client, admin_email, "Event Admin")
            asyncio.run(make_test_admin(admin_email))

            proposed = client.post(
                "/api/v1/event-proposals",
                headers=user_headers,
                json={
                    "event": {
                        "category": "Мероприятия",
                        "title": "User Proposed Event",
                        "summary": "Suggested for the Spark map",
                        "details": "The administrator should review this event",
                        "location_name": "Минск",
                        "latitude": 53.9023,
                        "longitude": 27.5619,
                    },
                    "message": "Пожалуйста, добавьте это событие на карту.",
                },
            )
            assert proposed.status_code == 201
            proposal_id = proposed.json()["id"]

            inbox = client.get("/api/v1/event-proposals", headers=admin_headers)
            assert inbox.status_code == 200
            assert proposal_id in {item["id"] for item in inbox.json()}

            approved = client.patch(
                f"/api/v1/event-proposals/{proposal_id}",
                headers=admin_headers,
                json={"status": "approved"},
            )
            assert approved.status_code == 200
            opportunities = client.get("/api/v1/opportunities")
            assert "User Proposed Event" in {item["title"] for item in opportunities.json()}
    finally:
        asyncio.run(delete_test_user(user_email))
        asyncio.run(delete_test_user(admin_email))
