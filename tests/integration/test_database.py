import pytest


@pytest.mark.database
def test_database_placeholder() -> None:
    # Placeholder that would exercise DB-related logic in real project
    assert 1 + 1 == 2
