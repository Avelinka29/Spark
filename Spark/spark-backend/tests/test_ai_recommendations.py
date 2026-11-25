import json
import uuid

import httpx
import pytest

from app.ai_recommendations import rank_projects


@pytest.mark.asyncio
async def test_only_known_projects_are_returned() -> None:
    project_id = uuid.uuid4()
    unknown_id = uuid.uuid4()
    requests = []

    def respond(request: httpx.Request) -> httpx.Response:
        requests.append(json.loads(request.content))
        return httpx.Response(200, json={"message": {"content": json.dumps({"matches": [
            {"id": str(unknown_id), "reason": "Unknown"},
            {"id": str(project_id), "reason": "Подходит Swift"},
            {"id": str(project_id), "reason": "Дубликат"},
        ]})}})

    matches = await rank_projects("http://model", "test-model", ["Swift"], ["EdTech"],
        [{"id": str(project_id), "title": "Project", "roles": [{"title": "iOS", "skills": "Swift"}]}], transport=httpx.MockTransport(respond))
    assert [item.id for item in matches] == [project_id]
    assert matches[0].reason == "Навык Swift указан для роли «iOS»."
    assert requests[0]["stream"] is False
    assert "Swift" in requests[0]["messages"][1]["content"]


@pytest.mark.asyncio
async def test_hallucinated_skills_are_not_shown() -> None:
    project_id = uuid.uuid4()
    def respond(_: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"message": {"content": json.dumps({"matches": [
            {"id": str(project_id), "reason": "Нужен Swift и Figma"}
        ]})}})
    matches = await rank_projects("http://model", "test", ["Swift", "Figma"], [],
        [{"id": str(project_id), "roles": [{"title": "Backend", "skills": "Python"}]}],
        transport=httpx.MockTransport(respond))
    assert matches == []


@pytest.mark.asyncio
async def test_invalid_output_is_rejected() -> None:
    def respond(_: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"message": {"content": "not json"}})

    with pytest.raises(ValueError, match="Invalid AI response"):
        await rank_projects("http://model", "test-model", [], [],
            [{"id": str(uuid.uuid4())}], transport=httpx.MockTransport(respond))


@pytest.mark.asyncio
async def test_model_connection_failure_is_not_reported_as_a_match() -> None:
    def fail(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("unavailable", request=request)

    with pytest.raises(httpx.ConnectError):
        await rank_projects("http://model", "test-model", ["Swift"], [],
            [{"id": str(uuid.uuid4())}], transport=httpx.MockTransport(fail))
