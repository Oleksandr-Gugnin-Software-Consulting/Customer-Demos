"""Small utility functions used by unit tests."""

from typing import Any


def add(a: int, b: int) -> int:
    """Return the sum of two integers."""
    return a + b


def echo(value: Any) -> Any:
    """Return the value back (used in simple tests)."""
    return value
