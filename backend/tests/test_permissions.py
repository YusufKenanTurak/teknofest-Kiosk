from __future__ import annotations

import os

import asyncpg
import pytest


def _kwargs(user: str, password: str, database: str) -> dict:
    return {
        "host": os.environ.get("PG_HOST", "10.6.228.154"),
        "port": int(os.environ.get("PG_PORT", "5432")),
        "user": user,
        "password": password,
        "database": database,
        "timeout": 10,
    }


@pytest.mark.asyncio
async def test_appuser_cannot_manage_database_or_schema():
    password = os.environ["PG_PASSWORD"]
    database = os.environ.get("PG_DATABASE", "teknofestKiosk")
    conn = await asyncpg.connect(**_kwargs("appuser", password, database))
    try:
        with pytest.raises(asyncpg.InsufficientPrivilegeError):
            await conn.execute("CREATE TABLE appuser_pwn (id int)")
        with pytest.raises(asyncpg.InsufficientPrivilegeError):
            await conn.execute("CREATE SCHEMA appuser_pwn")
        with pytest.raises(asyncpg.PostgresError):
            await conn.execute("CREATE ROLE appuser_extra")
    finally:
        await conn.close()

    postgres = await asyncpg.connect(**_kwargs("appuser", password, "postgres"))
    try:
        with pytest.raises(asyncpg.PostgresError):
            await postgres.execute(f'DROP DATABASE "{database}"')
        with pytest.raises(asyncpg.PostgresError):
            await postgres.execute("CREATE DATABASE appuser_should_not_create")
    finally:
        await postgres.close()


@pytest.mark.asyncio
async def test_appuser_catalog_table_acl_is_select_only():
    password = os.environ["PG_PASSWORD"]
    database = os.environ.get("PG_DATABASE", "teknofestKiosk")
    conn = await asyncpg.connect(**_kwargs("appuser", password, database))
    try:
        count = await conn.fetchval("SELECT COUNT(*) FROM questions")
        assert count == 15
        grants = await conn.fetch(
            """
            SELECT privilege_type
            FROM information_schema.role_table_grants
            WHERE table_schema = 'public'
              AND table_name = 'questions'
              AND grantee = 'appuser'
            """
        )
        assert {row["privilege_type"] for row in grants} == {"SELECT"}
    finally:
        await conn.close()
