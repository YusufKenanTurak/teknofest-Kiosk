from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any

import asyncpg

from app.scoring import CALCULATION_VERSION, calculate_result, tally


class TestRepository:
    def __init__(self, conn: asyncpg.Connection) -> None:
        self._conn = conn

    async def create_session(
        self,
        *,
        session_id: uuid.UUID,
        session_token: str,
        correlation_id: uuid.UUID,
        kiosk_id: str | None,
        application_version: str | None,
    ) -> dict[str, Any]:
        row = await self._conn.fetchrow(
            """
            INSERT INTO test_sessions (
                id, session_token, kiosk_id, application_version,
                correlation_id, status
            ) VALUES ($1, $2, $3, $4, $5, 'in_progress')
            RETURNING id, session_token, correlation_id, status, started_at
            """,
            session_id,
            session_token,
            kiosk_id,
            application_version,
            correlation_id,
        )
        return dict(row)

    async def get_session_by_token(self, session_token: str) -> dict[str, Any] | None:
        row = await self._conn.fetchrow(
            """
            SELECT id, session_token, kiosk_id, application_version,
                   correlation_id, status, started_at, completed_at, duration_ms
            FROM test_sessions
            WHERE session_token = $1
            """,
            session_token,
        )
        return dict(row) if row else None

    async def get_session(self, session_id: uuid.UUID) -> dict[str, Any] | None:
        row = await self._conn.fetchrow(
            """
            SELECT id, session_token, kiosk_id, application_version,
                   correlation_id, status, started_at, completed_at, duration_ms
            FROM test_sessions
            WHERE id = $1
            """,
            session_id,
        )
        return dict(row) if row else None

    async def get_session_for_update(self, session_id: uuid.UUID) -> dict[str, Any] | None:
        row = await self._conn.fetchrow(
            """
            SELECT id, session_token, kiosk_id, application_version,
                   correlation_id, status, started_at, completed_at, duration_ms
            FROM test_sessions
            WHERE id = $1
            FOR UPDATE
            """,
            session_id,
        )
        return dict(row) if row else None

    async def find_option(
        self, question_number: int, option_code: str
    ) -> dict[str, Any] | None:
        row = await self._conn.fetchrow(
            """
            SELECT o.id AS option_id, q.id AS question_id, d.code AS department_code
            FROM questions q
            JOIN question_options o ON o.question_id = q.id
            JOIN engineering_departments d ON d.id = o.department_id
            WHERE q.question_number = $1
              AND BTRIM(o.option_code) = BTRIM($2)
              AND q.is_active
              AND o.is_active
            """,
            question_number,
            option_code,
        )
        return dict(row) if row else None

    async def insert_answer(
        self,
        *,
        answer_id: uuid.UUID,
        session_id: uuid.UUID,
        question_id: uuid.UUID,
        option_id: uuid.UUID,
        response_time_ms: int | None,
    ) -> bool:
        result = await self._conn.execute(
            """
            INSERT INTO test_answers (
                id, session_id, question_id, selected_option_id, response_time_ms
            ) VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (session_id, question_id) DO NOTHING
            """,
            answer_id,
            session_id,
            question_id,
            option_id,
            response_time_ms,
        )
        return result.split()[-1] == "1"

    async def list_answer_codes(self, session_id: uuid.UUID) -> list[str]:
        rows = await self._conn.fetch(
            """
            SELECT d.code
            FROM test_answers a
            JOIN question_options o ON o.id = a.selected_option_id
            JOIN engineering_departments d ON d.id = o.department_id
            JOIN questions q ON q.id = a.question_id
            WHERE a.session_id = $1
            ORDER BY q.question_number
            """,
            session_id,
        )
        return [row["code"] for row in rows]

    async def complete_session(
        self,
        *,
        session_id: uuid.UUID,
        result_id: uuid.UUID,
        department_code: str,
        codes: list[str],
    ) -> dict[str, Any]:
        dept = await self._conn.fetchrow(
            "SELECT id, code, name, description, slogan, emoji FROM engineering_departments WHERE code = $1",
            department_code,
        )
        if dept is None:
            raise RuntimeError(f"Unknown department code {department_code}")

        now = datetime.now(timezone.utc)
        session = await self.get_session(session_id)
        if session is None:
            raise RuntimeError("Session missing during complete")
        started = session["started_at"]
        duration = int((now - started).total_seconds() * 1000)
        scores = tally(codes)

        await self._conn.execute(
            """
            UPDATE test_sessions
            SET status = 'completed',
                completed_at = $2,
                duration_ms = $3
            WHERE id = $1 AND status = 'in_progress'
            """,
            session_id,
            now,
            duration,
        )
        await self._conn.execute(
            """
            INSERT INTO test_results (
                id, session_id, primary_department_id, score_breakdown,
                calculation_version, completed_at
            ) VALUES ($1, $2, $3, $4::jsonb, $5, $6)
            ON CONFLICT (session_id) DO NOTHING
            """,
            result_id,
            session_id,
            dept["id"],
            json.dumps(scores, ensure_ascii=False),
            CALCULATION_VERSION,
            now,
        )
        return {
            "department_code": dept["code"],
            "department_name": dept["name"],
            "description": dept["description"],
            "slogan": dept["slogan"],
            "emoji": dept["emoji"],
            "score_breakdown": scores,
            "calculation_version": CALCULATION_VERSION,
            "duration_ms": duration,
        }

    async def abandon_session(self, session_id: uuid.UUID) -> None:
        now = datetime.now(timezone.utc)
        session = await self.get_session(session_id)
        if session is None or session["status"] != "in_progress":
            return
        duration = int((now - session["started_at"]).total_seconds() * 1000)
        await self._conn.execute(
            """
            UPDATE test_sessions
            SET status = 'abandoned',
                completed_at = $2,
                duration_ms = $3
            WHERE id = $1 AND status = 'in_progress'
            """,
            session_id,
            now,
            duration,
        )

    async def mark_error(self, session_id: uuid.UUID) -> None:
        await self._conn.execute(
            """
            UPDATE test_sessions
            SET status = 'error',
                completed_at = COALESCE(completed_at, now())
            WHERE id = $1 AND status = 'in_progress'
            """,
            session_id,
        )

    async def get_result(self, session_id: uuid.UUID) -> dict[str, Any] | None:
        row = await self._conn.fetchrow(
            """
            SELECT r.calculation_version, r.score_breakdown, r.completed_at,
                   d.code, d.name, d.description, d.slogan, d.emoji
            FROM test_results r
            JOIN engineering_departments d ON d.id = r.primary_department_id
            WHERE r.session_id = $1
            """,
            session_id,
        )
        return dict(row) if row else None


def winner_from_codes(codes: list[str]) -> str:
    return calculate_result(codes)
