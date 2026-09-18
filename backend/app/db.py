from __future__ import annotations

from collections.abc import AsyncIterator

import asyncpg

from app.config import Settings

_pool: asyncpg.Pool | None = None


async def create_pool(settings: Settings) -> asyncpg.Pool:
    global _pool
    _pool = await asyncpg.create_pool(
        host=settings.pg_host,
        port=settings.pg_port,
        user=settings.pg_user,
        password=settings.pg_password,
        database=settings.pg_database,
        min_size=1,
        max_size=settings.pool_size,
        command_timeout=15,
        timeout=10,
        server_settings={"timezone": "UTC", "application_name": "teknofest-kiosk-api"},
    )
    return _pool


def get_pool() -> asyncpg.Pool:
    if _pool is None:
        raise RuntimeError("Database pool is not initialized.")
    return _pool


async def close_pool() -> None:
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None


async def connection() -> AsyncIterator[asyncpg.Connection]:
    pool = get_pool()
    async with pool.acquire() as conn:
        yield conn
