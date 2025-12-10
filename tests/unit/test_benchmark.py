import pytest


@pytest.mark.benchmark
def test_simple_benchmark() -> None:
    # Small deterministic workload used by performance job
    total = sum(range(1000))
    assert total == 499500
