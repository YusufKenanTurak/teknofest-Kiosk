from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

import asyncpg


def _jsonable(row: Any) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in dict(row).items():
        if isinstance(value, Decimal):
            out[key] = int(value) if value == value.to_integral_value() else float(value)
        elif isinstance(value, UUID):
            out[key] = str(value)
        elif isinstance(value, datetime):
            out[key] = value.isoformat()
        elif isinstance(value, date):
            out[key] = value.isoformat()
        else:
            out[key] = value
    return out


class StatsRepository:
    def __init__(self, conn: asyncpg.Connection) -> None:
        self._conn = conn

    async def overview(self, started_from: datetime | None, started_to: datetime | None) -> dict:
        row = await self._conn.fetchrow(
            """
            SELECT
                COUNT(*) AS total_tests,
                COUNT(*) FILTER (WHERE status = 'completed') AS completed_tests,
                COUNT(*) FILTER (WHERE status = 'abandoned') AS abandoned_tests,
                COUNT(*) FILTER (WHERE status = 'error') AS error_tests,
                COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress_tests,
                CASE WHEN COUNT(*) = 0 THEN 0
                     ELSE ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'completed') / COUNT(*), 2)
                END AS completion_rate_pct,
                ROUND(AVG(duration_ms) FILTER (WHERE status = 'completed')) AS avg_duration_ms,
                MIN(duration_ms) FILTER (WHERE status = 'completed') AS min_duration_ms,
                MAX(duration_ms) FILTER (WHERE status = 'completed') AS max_duration_ms
            FROM test_sessions
            WHERE ($1::timestamptz IS NULL OR started_at >= $1)
              AND ($2::timestamptz IS NULL OR started_at < $2)
            """,
            started_from,
            started_to,
        )
        return _jsonable(row)

    async def departments(self, started_from: datetime | None, started_to: datetime | None) -> list[dict]:
        rows = await self._conn.fetch(
            """
            SELECT d.code, d.name, COUNT(filtered.id) AS result_count
            FROM engineering_departments d
            LEFT JOIN (
                SELECT r.id, r.primary_department_id
                FROM test_results r
                JOIN test_sessions s ON s.id = r.session_id
                WHERE ($1::timestamptz IS NULL OR s.started_at >= $1)
                  AND ($2::timestamptz IS NULL OR s.started_at < $2)
            ) filtered ON filtered.primary_department_id = d.id
            GROUP BY d.code, d.name, d.sort_order
            ORDER BY d.sort_order
            """,
            started_from,
            started_to,
        )
        return [_jsonable(r) for r in rows]

    async def questions(self) -> list[dict]:
        rows = await self._conn.fetch("SELECT * FROM v_question_option_stats")
        return [_jsonable(r) for r in rows]

    async def unanswered(self) -> list[dict]:
        rows = await self._conn.fetch(
            """
            SELECT
                q.question_number,
                q.question_text,
                COUNT(s.id) AS completed_sessions,
                COUNT(a.id) AS answered_in_completed,
                CASE WHEN COUNT(s.id) = 0 THEN 0
                     ELSE ROUND(100.0 * (COUNT(s.id) - COUNT(a.id)) / COUNT(s.id), 2)
                END AS unanswered_pct
            FROM questions q
            LEFT JOIN test_sessions s ON s.status = 'completed'
            LEFT JOIN test_answers a
                ON a.session_id = s.id AND a.question_id = q.id
            GROUP BY q.question_number, q.question_text
            ORDER BY q.question_number
            """
        )
        return [_jsonable(r) for r in rows]

    async def daily(self, started_from: datetime | None, started_to: datetime | None) -> list[dict]:
        rows = await self._conn.fetch(
            """
            SELECT
                (started_at AT TIME ZONE 'UTC')::date AS day,
                COUNT(*) AS total_tests,
                COUNT(*) FILTER (WHERE status = 'completed') AS completed_tests,
                COUNT(*) FILTER (WHERE status = 'abandoned') AS abandoned_tests
            FROM test_sessions
            WHERE ($1::timestamptz IS NULL OR started_at >= $1)
              AND ($2::timestamptz IS NULL OR started_at < $2)
            GROUP BY 1
            ORDER BY 1
            """,
            started_from,
            started_to,
        )
        return [_jsonable(r) for r in rows]

    async def hourly(self, started_from: datetime | None, started_to: datetime | None) -> list[dict]:
        rows = await self._conn.fetch(
            """
            SELECT
                date_trunc('hour', started_at) AS hour_utc,
                COUNT(*) AS total_tests,
                COUNT(*) FILTER (WHERE status = 'completed') AS completed_tests
            FROM test_sessions
            WHERE ($1::timestamptz IS NULL OR started_at >= $1)
              AND ($2::timestamptz IS NULL OR started_at < $2)
            GROUP BY 1
            ORDER BY 1
            """,
            started_from,
            started_to,
        )
        return [_jsonable(r) for r in rows]

    async def by_version(self) -> list[dict]:
        rows = await self._conn.fetch(
            """
            SELECT COALESCE(application_version, 'unknown') AS application_version,
                   COUNT(*) AS total_tests
            FROM test_sessions
            GROUP BY 1
            ORDER BY 2 DESC
            """
        )
        return [_jsonable(r) for r in rows]

    async def by_kiosk(self) -> list[dict]:
        rows = await self._conn.fetch(
            """
            SELECT COALESCE(kiosk_id, 'unknown') AS kiosk_id,
                   COUNT(*) AS total_tests
            FROM test_sessions
            GROUP BY 1
            ORDER BY 2 DESC
            """
        )
        return [_jsonable(r) for r in rows]

    async def errors(self, started_from: datetime | None, started_to: datetime | None) -> list[dict]:
        rows = await self._conn.fetch(
            """
            SELECT id, occurred_at, level, exception_type, message, endpoint,
                   status_code, correlation_id, session_id
            FROM application_errors
            WHERE ($1::timestamptz IS NULL OR occurred_at >= $1)
              AND ($2::timestamptz IS NULL OR occurred_at < $2)
            ORDER BY occurred_at DESC
            LIMIT 200
            """,
            started_from,
            started_to,
        )
        return [_jsonable(r) for r in rows]

    async def catalog(self) -> list[dict]:
        questions = await self._conn.fetch(
            """
            SELECT id, question_number, question_text
            FROM questions
            WHERE is_active
            ORDER BY question_number
            """
        )
        options = await self._conn.fetch(
            """
            SELECT o.question_id, o.option_code, o.option_text, d.code AS department_code
            FROM question_options o
            JOIN engineering_departments d ON d.id = o.department_id
            WHERE o.is_active
            ORDER BY o.option_code
            """
        )
        by_q: dict = {}
        for option in options:
            by_q.setdefault(option["question_id"], []).append(
                {
                    "code": option["option_code"],
                    "text": option["option_text"],
                    "department_code": option["department_code"],
                }
            )
        return [
            {
                "number": q["question_number"],
                "text": q["question_text"],
                "options": by_q.get(q["id"], []),
            }
            for q in questions
        ]
