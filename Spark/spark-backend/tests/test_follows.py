import uuid
from datetime import date, timedelta

import httpx
import pytest
from sqlalchemy import delete

from app.database import SessionFactory, engine
from app.main import app
from app.models import Opportunity, Project, User
from app.security import create_access_token


@pytest.mark.asyncio
async def test_follows_are_private_and_feed_uses_current_matching_data() -> None:
    user_id, other_id, project_id, future_id, past_id = (uuid.uuid4() for _ in range(5))
    try:
        async with SessionFactory() as session:
            session.add_all([User(id=user_id, email=f"{user_id}@example.com", name="User"),
                             User(id=other_id, email=f"{other_id}@example.com", name="Other")])
            await session.flush()
            session.add(Project(id=project_id, owner_id=other_id, title="Followed project", category="EdTech", summary="Learning project for testing", owner_role="Owner"))
            for event_id, day in [(future_id, date.today() + timedelta(days=10)), (past_id, date.today() - timedelta(days=10))]:
                session.add(Opportunity(id=event_id, title=f"EdTech {event_id}", category="Мероприятия", summary="Learning event", details="Details", organizer="Demo organizer", location_name="Минск", starts_at=day, published=True))
            await session.commit()
        headers = {"Authorization": f"Bearer {create_access_token(user_id)}"}
        other_headers = {"Authorization": f"Bearer {create_access_token(other_id)}"}
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
            first = await client.post("/api/v1/follows", headers=headers, json={"kind": "topic", "value": "EdTech"})
            duplicate = await client.post("/api/v1/follows", headers=headers, json={"kind": "topic", "value": "edtech"})
            assert first.status_code == 200 and duplicate.json()["id"] == first.json()["id"]
            assert (await client.post("/api/v1/follows", headers=headers, json={"kind": "project", "value": str(project_id)})).status_code == 200
            assert (await client.get("/api/v1/follows", headers=other_headers)).json() == []
            feed = (await client.get("/api/v1/follows/feed", headers=headers)).json()
            assert str(future_id) in {item["id"] for item in feed["opportunities"]}
            assert str(past_id) not in {item["id"] for item in feed["opportunities"]}
            assert str(project_id) in {item["id"] for item in feed["projects"]}
            result = await client.patch(f"/api/v1/projects/{project_id}", headers=other_headers, json={"result_url": "https://example.org/result"})
            assert result.status_code == 200 and result.json()["result_url"] == "https://example.org/result"
            assert (await client.patch(f"/api/v1/projects/{project_id}", headers=headers, json={"result_url": "https://example.org/other"})).status_code == 403
            owner_profile = (await client.get(f"/api/v1/profiles/{other_id}", headers=headers)).json()
            assert any(item["result_url"] == "https://example.org/result" for item in owner_profile["projects"])
            feedback = await client.put(f"/api/v1/recommendations/projects/{project_id}/feedback", headers=headers, json={"helpful": False})
            assert feedback.status_code == 204
            feedback_update = await client.put(f"/api/v1/recommendations/projects/{project_id}/feedback", headers=headers, json={"helpful": True})
            assert feedback_update.status_code == 204
            from app.models import RecommendationFeedback
            from sqlalchemy import select
            async with SessionFactory() as session:
                record = await session.scalar(select(RecommendationFeedback).where(RecommendationFeedback.user_id == user_id, RecommendationFeedback.project_id == project_id))
                assert record is not None and record.helpful is True
            await client.delete(f"/api/v1/follows/{first.json()['id']}", headers=other_headers)
            assert len((await client.get("/api/v1/follows", headers=headers)).json()) == 2
    finally:
        async with SessionFactory() as session:
            await session.execute(delete(Opportunity).where(Opportunity.id.in_([future_id, past_id])))
            await session.execute(delete(User).where(User.id.in_([user_id, other_id])))
            await session.commit()
        await engine.dispose()
