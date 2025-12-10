"""Minimal FastAPI app with a /health endpoint used by Docker test."""

# test change to trigger CI jobs (no-op comment)

from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
async def health() -> dict:
    """Simple health endpoint for CI health checks."""
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
