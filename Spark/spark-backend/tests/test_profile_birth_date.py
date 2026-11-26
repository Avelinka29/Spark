import uuid
from datetime import date, timedelta
import httpx
import pytest
from sqlalchemy import delete
from app.database import SessionFactory, engine
from app.main import app
from app.models import User
from app.security import create_access_token

@pytest.mark.asyncio
async def test_birth_date_is_private_validated_and_removable():
    user_id, other_id = uuid.uuid4(), uuid.uuid4()
    try:
        async with SessionFactory() as session:
            session.add_all([User(id=user_id, email=f"{user_id}@example.com", name="First Last"), User(id=other_id, email=f"{other_id}@example.com", name="Other Person")])
            await session.commit()
        headers = {"Authorization": f"Bearer {create_access_token(user_id)}"}
        other_headers = {"Authorization": f"Bearer {create_access_token(other_id)}"}
        async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app), base_url="http://test") as client:
            response = await client.patch('/api/v1/profile/me', headers=headers, json={"birth_date": "2000-05-15"})
            assert response.status_code == 200 and response.json()["birth_date"] == "2000-05-15"
            public = await client.get(f'/api/v1/profiles/{user_id}', headers=other_headers)
            assert public.status_code == 200 and "birth_date" not in public.json()
            future = (date.today() + timedelta(days=1)).isoformat()
            assert (await client.patch('/api/v1/profile/me', headers=headers, json={"birth_date": future})).status_code == 422
            response = await client.patch('/api/v1/profile/me', headers=headers, json={"birth_date": None})
            assert response.status_code == 200 and response.json()["birth_date"] is None
    finally:
        async with SessionFactory() as session:
            await session.execute(delete(User).where(User.id.in_([user_id, other_id])))
            await session.commit()
        await engine.dispose()
