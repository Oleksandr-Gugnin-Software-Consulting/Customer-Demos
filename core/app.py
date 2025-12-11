"""Minimal FastAPI app with a /health endpoint used by Docker test."""

# test change to trigger CI jobs (no-op comment)

from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
async def health() -> dict:
    """Simple health endpoint for CI health checks."""
    return {"status": "ok"}


if __name__ == "__main__":
    # The application is served by the Docker/CI `uvicorn` command defined
    # in the Dockerfile / CI steps. Avoid running uvicorn here to prevent
    # hardcoded network binding in module code (Bandit B104).
    # Example to run locally:
    #   uvicorn core.app:app --host 127.0.0.1 --port 8000
    pass
