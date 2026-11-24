import uuid

import httpx
import pytest
from sqlalchemy import delete

import app.main as main_module
from app.ai_recommendations import ModelMatch
from app.config import get_settings
from app.database import SessionFactory, engine
from app.models import Project, ProjectRole, User
from app.security import create_access_token


@pytest.mark.asyncio
async def test_ai_recommendations_use_authenticated_profile_and_open_projects(monkeypatch) -> None:
    user_id, owner_id = uuid.uuid4(), uuid.uuid4()
    project_id = uuid.uuid4()
    settings = get_settings()
    monkeypatch.setattr(settings, "ai_ollama_url", "http://model")
    monkeypatch.setattr(settings, "ai_ollama_model", "fake")
    captured = {}

    async def fake_rank(url, model, skills, interests, projects):
        captured.update(skills=skills, interests=interests, projects=projects)
        return [ModelMatch(id=project_id, reason="Нужен Swift")]

    monkeypatch.setattr(main_module, "rank_projects", fake_rank)
    try:
        async with SessionFactory() as session:
            session.add_all([
                User(id=user_id, email=f"{user_id}@example.com", name="Candidate", skills=["Swift"], interests=["EdTech"]),
                User(id=owner_id, email=f"{owner_id}@example.com", name="Owner"),
            ])
            await session.flush()
            session.add(Project(id=project_id, owner_id=owner_id, category="EdTech", title="Learning", summary="A learning project", owner_role="Founder"))
            await session.flush()
            session.add(ProjectRole(project_id=project_id, title="iOS", skills="Swift"))
            await session.commit()
        transport = httpx.ASGITransport(app=main_module.app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.post("/api/v1/recommendations/projects", headers={
                "Authorization": f"Bearer {create_access_token(user_id)}"
            })
        assert response.status_code == 200
        assert response.json() == [{"id": str(project_id), "reason": "Нужен Swift"}]
        assert captured["skills"] == ["Swift"]
        assert captured["interests"] == ["EdTech"]
        assert str(project_id) in {item["id"] for item in captured["projects"]}
        assert all("email" not in item for item in captured["projects"])
    finally:
        async with SessionFactory() as session:
            await session.execute(delete(User).where(User.id.in_([user_id, owner_id])))
            await session.commit()
        await engine.dispose()
