from __future__ import annotations

import argparse
import asyncio
import os
from pathlib import Path

import asyncpg

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = ROOT / "db" / "migrations"


def _env(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default)
    if value is None or value == "":
        raise SystemExit(f"{name} is required")
    return value


async def ensure_database(admin: dict, database: str) -> None:
    conn = await asyncpg.connect(database="postgres", timeout=10, **admin)
    try:
        exists = await conn.fetchval(
            "SELECT 1 FROM pg_database WHERE datname = $1",
            database,
        )
        if exists:
            print(f"Database {database} already exists")
            return
        await conn.execute(f'CREATE DATABASE "{database}" OWNER "{admin["user"]}"')
        print(f"Created database {database}")
    finally:
        await conn.close()


async def apply_migrations(admin: dict, database: str) -> None:
    conn = await asyncpg.connect(database=database, timeout=15, **admin)
    try:
        await conn.execute(
            """
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version TEXT PRIMARY KEY,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
            """
        )
        version = await conn.fetchval("SHOW server_version_num")
        files = sorted(p for p in MIGRATIONS.glob("*.sql"))
        for path in files:
            key = path.name
            already = await conn.fetchval(
                "SELECT 1 FROM schema_migrations WHERE version = $1",
                key,
            )
            if already:
                print(f"skip {key}")
                continue
            sql = path.read_text(encoding="utf-8")
            if int(version) < 140000:
                sql = sql.replace("EXECUTE FUNCTION", "EXECUTE PROCEDURE")
            async with conn.transaction():
                await conn.execute(sql)
                await conn.execute(
                    "INSERT INTO schema_migrations(version) VALUES ($1)",
                    key,
                )
            print(f"applied {key}")
    finally:
        await conn.close()


async def main() -> None:
    parser = argparse.ArgumentParser(description="Apply Teknofest Kiosk migrations as dev_admin")
    parser.add_argument("--host", default=os.environ.get("PG_HOST", "10.6.228.154"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("PG_PORT", "5432")))
    parser.add_argument("--database", default=os.environ.get("PG_DATABASE", "teknofestKiosk"))
    parser.add_argument("--admin-user", default=os.environ.get("PG_ADMIN_USER", "dev_admin"))
    parser.add_argument("--app-user", default=os.environ.get("PG_APP_USER", "appuser"))
    args = parser.parse_args()
    admin_password = _env("PG_ADMIN_PASSWORD")
    admin = {
        "host": args.host,
        "port": args.port,
        "user": args.admin_user,
        "password": admin_password,
    }
    await ensure_database(admin, args.database)
    await apply_migrations(admin, args.database)


if __name__ == "__main__":
    asyncio.run(main())
