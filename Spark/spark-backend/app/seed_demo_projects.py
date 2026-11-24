"""Create clearly labelled sample projects in the local development database."""

import asyncio
import uuid

from sqlalchemy.dialects.postgresql import insert

from .config import get_settings
from .database import SessionFactory, engine
from .models import Project, ProjectRole, User

DEMO_NAMESPACE = uuid.UUID("7906f429-e193-48b7-b1c5-1f571437a983")


def demo_id(value: str) -> uuid.UUID:
    return uuid.uuid5(DEMO_NAMESPACE, value)


PROJECTS = [
    ("learn", "EdTech", "[Демо] Учимся вместе", "Мобильное приложение для совместного изучения языков и коротких уроков.", "iOS-разработчик", "Swift, SwiftUI, iOS"),
    ("finance", "FinTech", "[Демо] Финансы без сложностей", "Помогаем студентам планировать бюджет и понимать личные финансы.", "iOS-разработчик", "Swift, SwiftUI, FinTech"),
    ("design", "EdTech", "[Демо] Дизайн учебной платформы", "Проектируем удобный интерфейс платформы обучения и проверяем прототипы на пользователях.", "UX/UI дизайнер", "Figma, дизайн интерфейсов, прототипирование"),
    ("eco", "Экология", "[Демо] Зелёный город", "Карта экологических инициатив и волонтёрских событий для городских сообществ.", "Дизайнер продукта", "Figma, исследования, UI/UX"),
    ("health", "HealthTech", "[Демо] Забота рядом", "Прототип приложения для поиска проверенных волонтёрских инициатив в сфере здоровья.", "Backend-разработчик", "Python, FastAPI, PostgreSQL"),
]


async def main() -> None:
    if get_settings().app_environment != "development":
        raise RuntimeError("Demo projects are available only in development")
    owner_id = demo_id("owner")
    async with SessionFactory() as session:
        await session.execute(insert(User).values(
            id=owner_id, email="demo-projects@spark.example.com", name="Демо-команда Spark",
            email_verified=False, skills=[], interests=[],
        ).on_conflict_do_nothing())
        if await session.get(User, owner_id) is None:
            raise RuntimeError("Demo owner could not be created")
        for key, category, title, summary, role, skills in PROJECTS:
            project_id = demo_id(key)
            await session.execute(insert(Project).values(
                id=project_id, owner_id=owner_id, category=category, title=title,
                summary=summary, owner_role="Координатор демо-проекта",
            ).on_conflict_do_nothing())
            await session.execute(insert(ProjectRole).values(
                id=demo_id(f"{key}-role"), project_id=project_id, title=role, skills=skills,
                is_open=True,
            ).on_conflict_do_nothing())
        await session.commit()
    await engine.dispose()
    print(f"Demo projects ready: {len(PROJECTS)}")


if __name__ == "__main__":
    asyncio.run(main())
