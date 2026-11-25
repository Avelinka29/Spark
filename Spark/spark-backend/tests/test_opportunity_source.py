import pytest
from pydantic import ValidationError

from app.schemas import OpportunityCreate, ProjectUpdate


def test_event_source_requires_https_and_is_optional() -> None:
    data = dict(category="Мероприятия", title="Event", summary="Summary", details="Details",
                location_name="Минск", latitude=53.9, longitude=27.5)
    assert OpportunityCreate(**data).source_url is None
    assert OpportunityCreate(**data, source_url="https://example.org/event").source_url == "https://example.org/event"
    with pytest.raises(ValidationError):
        OpportunityCreate(**data, source_url="http://example.org/event")
    with pytest.raises(ValidationError):
        OpportunityCreate(**data, source_url="https://name:password@example.org/event")
    assert ProjectUpdate(result_url="").result_url == ""
    with pytest.raises(ValidationError):
        ProjectUpdate(result_url="http://example.org/result")
