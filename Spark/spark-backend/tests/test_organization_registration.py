import uuid
from datetime import date, timedelta

import httpx
import pytest
from sqlalchemy import delete

from app.database import SessionFactory, engine
from app.main import app
from app.models import Opportunity, User
from app.security import create_access_token


@pytest.mark.asyncio
async def test_organizations_and_event_registrations() -> None:
    owner_id, user_id, other_id, pending_id, event_id, expired_id = (uuid.uuid4() for _ in range(6))
    try:
        async with SessionFactory() as session:
            session.add_all([
                User(id=owner_id, email=f"{owner_id}@example.com", name="Owner", account_type="organization", organization_status="approved", organization_name="Test university", email_verified=True),
                User(id=pending_id, email=f"{pending_id}@example.com", name="Pending", account_type="user", organization_status="pending", organization_name="Pending university", email_verified=True),
                User(id=user_id, email=f"{user_id}@example.com", name="User", email_verified=True),
                User(id=other_id, email=f"{other_id}@example.com", name="Other", email_verified=True),
            ])
            await session.flush()
            for identifier, deadline in [(event_id, date.today() + timedelta(days=10)), (expired_id, date.today() - timedelta(days=10))]:
                session.add(Opportunity(id=identifier, owner_id=owner_id, category="Мероприятия", title="Test event", summary="Summary", details="Details", organizer="Test university", location_name="Минск", starts_at=date.today() + timedelta(days=20), deadline=deadline, published=True, accepts_registrations=True))
            await session.commit()
        headers = lambda identifier: {"Authorization": f"Bearer {create_access_token(identifier)}"}
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
            directory = await client.get("/api/v1/organizations", params={"search": "Test university"})
            assert str(owner_id) in {item["id"] for item in directory.json()}
            assert (await client.get(f"/api/v1/organizations/{pending_id}")).status_code == 404
            detail = (await client.get(f"/api/v1/organizations/{owner_id}")).json()
            assert str(event_id) in {event["id"] for event in detail["events"]}
            followed = await client.post("/api/v1/follows", headers=headers(user_id), json={"kind": "organization", "value": str(owner_id)})
            assert followed.status_code == 200
            feed = (await client.get("/api/v1/follows/feed", headers=headers(user_id))).json()
            assert str(event_id) in {event["id"] for event in feed["opportunities"]}
            payload = {"name": "Participant", "email": "participant@example.com", "message": "Interested"}
            path = f"/api/v1/opportunities/{event_id}/registrations"
            assert (await client.post(path, json=payload)).status_code == 401
            assert (await client.post(f"/api/v1/opportunities/{expired_id}/registrations", headers=headers(user_id), json=payload)).status_code == 409
            response = await client.post(path, headers=headers(user_id), json=payload)
            assert response.status_code == 201
            assert (await client.post(path, headers=headers(user_id), json=payload)).status_code == 409
            assert (await client.get(path, headers=headers(other_id))).status_code == 404
            owner_results = (await client.get(path, headers=headers(owner_id))).json()
            assert len(owner_results) == 1 and owner_results[0]["email"] == payload["email"]
            assert (await client.delete(path + "/me", headers=headers(user_id))).status_code == 204
            assert (await client.get(path, headers=headers(owner_id))).json() == []
    finally:
        async with SessionFactory() as session:
            await session.execute(delete(Opportunity).where(Opportunity.id.in_([event_id, expired_id])))
            await session.execute(delete(User).where(User.id.in_([owner_id, user_id, other_id, pending_id])))
            await session.commit()
        await engine.dispose()
