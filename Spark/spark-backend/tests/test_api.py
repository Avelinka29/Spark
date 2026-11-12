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
            token = registration.json()["access_token"]
            headers = {"Authorization": f"Bearer {token}"}

            profile = client.get("/api/v1/profile/me", headers=headers)
            assert profile.status_code == 200
            assert profile.json()["email"] == email

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
                    "roles": [{"title": "Backend Developer", "skills": "FastAPI"}],
                },
            )
            assert created.status_code == 201
            project = created.json()
            assert project["title"] == "Integration Test Project"
            assert len(project["roles"]) == 1

            role_id = project["roles"][0]["id"]
            application = client.post(
                f"/api/v1/project-roles/{role_id}/applications",
                headers=headers,
            )
            assert application.status_code == 201
    finally:
        asyncio.run(delete_test_user(email))


async def delete_test_user(email: str) -> None:
    async with SessionFactory() as session:
        await session.execute(delete(User).where(User.email == email))
        await session.commit()
