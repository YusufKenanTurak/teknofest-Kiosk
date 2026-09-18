import os
from collections.abc import AsyncIterator

from contextlib import asynccontextmanager

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

os.environ.setdefault("PG_HOST", "10.6.228.154")
os.environ.setdefault("PG_PORT", "5432")
os.environ.setdefault("PG_DATABASE", "teknofestKiosk")
os.environ.setdefault("PG_USER", "appuser")
os.environ.setdefault("APP_ENV", "test")
os.environ.setdefault("APP_VERSION", "1.0.0")

from app.config import get_settings  # noqa: E402
from app.main import app  # noqa: E402


@asynccontextmanager
async def _api_client() -> AsyncIterator[AsyncClient]:
    get_settings.cache_clear()
    async with app.router.lifespan_context(app):
        transport = ASGITransport(app=app, raise_app_exceptions=False)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            yield ac


@pytest.fixture(autouse=True)
def _require_database(request: pytest.FixtureRequest):
    if request.path.name == "test_scoring.py":
        return
    if not os.environ.get("PG_PASSWORD"):
        pytest.skip("PG_PASSWORD is required for database tests")


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    if not os.environ.get("PG_PASSWORD"):
        pytest.skip("PG_PASSWORD is required for API integration tests")
    async with _api_client() as ac:
        yield ac
