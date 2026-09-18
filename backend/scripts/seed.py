from __future__ import annotations

import argparse
import asyncio
import json
import os
from pathlib import Path
from uuid import UUID

import asyncpg

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "db" / "seed" / "catalog.json"

DEPT_NUMBERS = {"B": 1, "K": 2, "Ç": 3, "M": 4, "E": 5, "İ": 6, "N": 7}


def dept_id(code: str) -> UUID:
    return UUID(f"00000000-0000-4000-a000-{DEPT_NUMBERS[code]:012d}")


def question_id(number: int) -> UUID:
    return UUID(f"00000000-0000-4000-b000-{number:012d}")


def option_id(number: int, code: str) -> UUID:
    letter = "ABCD".index(code) + 1
    return UUID(f"00000000-0000-4000-c000-{number:08d}{letter:04d}")


async def seed(conn: asyncpg.Connection) -> None:
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    async with conn.transaction():
        for dept in catalog["departments"]:
            await conn.execute(
                """
                INSERT INTO engineering_departments (
                    id, code, name, description, slogan, emoji, sort_order
                ) VALUES ($1, $2, $3, $4, $5, $6, $7)
                ON CONFLICT (code) DO UPDATE SET
                    name = EXCLUDED.name,
                    description = EXCLUDED.description,
                    slogan = EXCLUDED.slogan,
                    emoji = EXCLUDED.emoji,
                    sort_order = EXCLUDED.sort_order,
                    is_active = TRUE
                """,
                dept_id(dept["code"]),
                dept["code"],
                dept["name"],
                dept["description"],
                dept["slogan"],
                dept["emoji"],
                dept["sort_order"],
            )
        for question in catalog["questions"]:
            qid = question_id(question["number"])
            await conn.execute(
                """
                INSERT INTO questions (id, question_number, question_text)
                VALUES ($1, $2, $3)
                ON CONFLICT (question_number) DO UPDATE SET
                    question_text = EXCLUDED.question_text,
                    is_active = TRUE
                """,
                qid,
                question["number"],
                question["text"],
            )
            for option in question["options"]:
                await conn.execute(
                    """
                    INSERT INTO question_options (
                        id, question_id, option_code, option_text, department_id
                    ) VALUES ($1, $2, $3, $4, $5)
                    ON CONFLICT (question_id, option_code) DO UPDATE SET
                        option_text = EXCLUDED.option_text,
                        department_id = EXCLUDED.department_id,
                        is_active = TRUE
                    """,
                    option_id(question["number"], option["code"]),
                    qid,
                    option["code"],
                    option["text"],
                    dept_id(option["department"]),
                )
    print("Seed completed (idempotent).")


async def main() -> None:
    parser = argparse.ArgumentParser(description="Idempotent catalog seed (dev_admin)")
    parser.add_argument("--host", default=os.environ.get("PG_HOST", "10.6.228.154"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("PG_PORT", "5432")))
    parser.add_argument("--database", default=os.environ.get("PG_DATABASE", "teknofestKiosk"))
    parser.add_argument("--admin-user", default=os.environ.get("PG_ADMIN_USER", "dev_admin"))
    args = parser.parse_args()
    password = os.environ.get("PG_ADMIN_PASSWORD")
    if not password:
        raise SystemExit("PG_ADMIN_PASSWORD is required")
    conn = await asyncpg.connect(
        host=args.host,
        port=args.port,
        user=args.admin_user,
        password=password,
        database=args.database,
        timeout=15,
    )
    try:
        await seed(conn)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
