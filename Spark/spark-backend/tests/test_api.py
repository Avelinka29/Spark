import asyncio
import os
import uuid

import httpx
from sqlalchemy import delete

from app.database import SessionFactory
from app.models import User


BASE_URL = os.getenv("TEST_BASE_URL", "http://api:8000")


def test_full_user_scenario() -> None:
    email = f"spark-{uuid.uuid4()}@example.com"

    try:
        with httpx.Client(base_url=BASE_URL, timeout=10) as client:
            health = client.get("/health")
            assert health.status_code == 200
            assert health.json() == {"status": "ok"}

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

            deleted_project = client.delete(
                f"/api/v1/projects/{project['id']}",
                headers=headers,
            )
            assert deleted_project.status_code == 204
    finally:
        asyncio.run(delete_test_user(email))


async def delete_test_user(email: str) -> None:
    async with SessionFactory() as session:
        await session.execute(delete(User).where(User.email == email))
        await session.commit()
