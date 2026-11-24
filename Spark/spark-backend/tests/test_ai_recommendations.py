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
        [{"id": str(project_id), "title": "Project"}], transport=httpx.MockTransport(respond))
    assert [item.id for item in matches] == [project_id]
    assert matches[0].reason == "Подходит Swift"
    assert requests[0]["stream"] is False
    assert "Swift" in requests[0]["messages"][1]["content"]


@pytest.mark.asyncio
async def test_invalid_output_is_rejected() -> None:
    def respond(_: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"message": {"content": "not json"}})

    with pytest.raises(ValueError, match="Invalid AI response"):
        await rank_projects("http://model", "test-model", [], [],
            [{"id": str(uuid.uuid4())}], transport=httpx.MockTransport(respond))
