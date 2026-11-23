"""Create the requested local development administrator without resetting existing users."""

import asyncio

from sqlalchemy import select

from .config import get_settings
from .database import SessionFactory, engine
from .models import User
from .security import hash_password


async def main() -> None:
    if get_settings().app_environment != "development":
        raise RuntimeError("The development administrator is forbidden outside development")
    async with SessionFactory() as session:
        existing = await session.scalar(select(User).where(User.email == "admin@spark.example.com"))
        if existing:
            raise RuntimeError("admin@spark.example.com already exists; no account was changed")
        session.add(User(email="admin@spark.example.com", name="Администратор", password_hash=hash_password("admin"),
                         email_verified=True, account_type="admin"))
        await session.commit()
    await engine.dispose()
    print("Development administrator created. Login: admin")


if __name__ == "__main__":
    asyncio.run(main())
