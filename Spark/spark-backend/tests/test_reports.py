import uuid

import httpx
import pytest
from sqlalchemy import delete

from app.database import SessionFactory, engine
from app.main import app
from app.models import User
from app.security import create_access_token


@pytest.mark.asyncio
async def test_reports_require_auth_and_only_admin_can_moderate() -> None:
    reporter_id, target_id, admin_id = (uuid.uuid4() for _ in range(3))
    try:
        async with SessionFactory() as session:
            session.add_all([User(id=reporter_id, email=f"{reporter_id}@example.com", name="Reporter"),
                             User(id=target_id, email=f"{target_id}@example.com", name="Target"),
                             User(id=admin_id, email=f"{admin_id}@example.com", name="Admin", account_type="admin")])
            await session.commit()
        headers = lambda identifier: {"Authorization": f"Bearer {create_access_token(identifier)}"}
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
            payload = {"kind": "user", "target_id": str(target_id), "reason": "Problem requiring review"}
            assert (await client.post("/api/v1/reports", json=payload)).status_code == 401
            assert (await client.get("/api/v1/admin/reports", headers=headers(reporter_id))).status_code == 403
            assert (await client.post("/api/v1/reports", headers=headers(reporter_id), json={**payload, "target_id": str(reporter_id)})).status_code == 400
            report = await client.post("/api/v1/reports", headers=headers(reporter_id), json=payload)
            assert report.status_code == 201
            report_id = report.json()["id"]
            assert report_id in {r["id"] for r in (await client.get("/api/v1/admin/reports", headers=headers(admin_id))).json()}
            assert (await client.patch(f"/api/v1/admin/reports/{report_id}", headers=headers(reporter_id), json={"status": "reviewed"})).status_code == 403
            assert (await client.patch(f"/api/v1/admin/reports/{report_id}", headers=headers(admin_id), json={"status": "reviewed"})).status_code == 200
    finally:
        async with SessionFactory() as session:
            await session.execute(delete(User).where(User.id.in_([reporter_id, target_id, admin_id])))
            await session.commit()
        await engine.dispose()
