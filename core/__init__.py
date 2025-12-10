"""Core package for demo CI.

Provides a tiny utility function and a FastAPI app used by CI jobs.
"""

__all__ = ["utils", "app"]

# ci-trigger: no-op change to cause CI to run all jobs

# Package version (no functional change) - used to trigger CI
__version__ = "0.0.1"
