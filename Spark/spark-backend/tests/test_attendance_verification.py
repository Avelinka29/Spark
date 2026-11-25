import uuid
from datetime import date, timedelta

import httpx
import pytest
from sqlalchemy import delete

from app.database import SessionFactory, engine
from app.main import app
from app.models import Opportunity, OpportunityAttendance, User
from app.security import create_access_token


@pytest.mark.asyncio
async def test_only_verified_event_owner_can_verify_another_participant() -> None:
    owner_id, participant_id, stranger_id, event_id, future_id = (uuid.uuid4() for _ in range(5))
    try:
        async with SessionFactory() as session:
            session.add_all([User(id=owner_id, email=f"{owner_id}@example.com", name="Organizer", account_type="organization", organization_status="approved"),
                             User(id=participant_id, email=f"{participant_id}@example.com", name="Participant"),
                             User(id=stranger_id, email=f"{stranger_id}@example.com", name="Stranger")])
            await session.flush()
            for identifier, day in [(event_id, date.today() - timedelta(days=1)), (future_id, date.today() + timedelta(days=1))]:
                session.add(Opportunity(id=identifier, owner_id=owner_id, category="Мероприятия", title="Test event", summary="Test summary", details="Test details", organizer="Organizer", location_name="Минск", starts_at=day, published=True))
            await session.flush()
            session.add_all([OpportunityAttendance(user_id=participant_id, opportunity_id=event_id, attended=True),
                             OpportunityAttendance(user_id=participant_id, opportunity_id=future_id, attended=True),
                             OpportunityAttendance(user_id=owner_id, opportunity_id=event_id, attended=True)])
            await session.commit()
        headers = lambda identifier: {"Authorization": f"Bearer {create_access_token(identifier)}"}
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
            path = f"/api/v1/opportunities/{event_id}/attendance/participants/{participant_id}/verify"
            assert (await client.put(path, headers=headers(stranger_id))).status_code == 403
            assert (await client.put(f"/api/v1/opportunities/{event_id}/attendance/participants/{owner_id}/verify", headers=headers(owner_id))).status_code == 403
            assert (await client.put(f"/api/v1/opportunities/{future_id}/attendance/participants/{participant_id}/verify", headers=headers(owner_id))).status_code == 409
            assert (await client.put(path, headers=headers(owner_id))).status_code == 204
            profile = await client.get(f"/api/v1/profiles/{participant_id}", headers=headers(participant_id))
            assert next(item for item in profile.json()["events"] if item["id"] == str(event_id))["verified"] is True
            assert (await client.put("/api/v1/profile/portfolio-visibility", headers=headers(participant_id), json={"portfolio_public": False})).status_code == 200
            hidden = (await client.get(f"/api/v1/profiles/{participant_id}", headers=headers(stranger_id))).json()
            assert hidden["portfolio_visible"] is False and hidden["events"] == [] and hidden["projects"] == []
            own_profile = (await client.get(f"/api/v1/profiles/{participant_id}", headers=headers(participant_id))).json()
            assert own_profile["portfolio_visible"] is True and own_profile["events"]
            assert (await client.delete(path, headers=headers(stranger_id))).status_code == 403
            assert (await client.delete(path, headers=headers(owner_id))).status_code == 204
            profile = await client.get(f"/api/v1/profiles/{participant_id}", headers=headers(participant_id))
            assert next(item for item in profile.json()["events"] if item["id"] == str(event_id))["verified"] is False
    finally:
        async with SessionFactory() as session:
            await session.execute(delete(Opportunity).where(Opportunity.id.in_([event_id, future_id])))
            await session.execute(delete(User).where(User.id.in_([owner_id, participant_id, stranger_id])))
            await session.commit()
        await engine.dispose()
