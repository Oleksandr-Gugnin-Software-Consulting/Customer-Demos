from core.utils import add, echo


def test_add_basic() -> None:
    assert add(2, 3) == 5


def test_echo_returns_value() -> None:
    assert echo({"a": 1}) == {"a": 1}
