from __future__ import annotations

import secrets
import uuid

import asyncpg
from fastapi import HTTPException

from app.observability import new_id
from app.repositories.logs import LogRepository
from app.repositories.tests import TestRepository, winner_from_codes


class TestService:
    def __init__(self, conn: asyncpg.Connection, app_version: str) -> None:
        self._conn = conn
        self._tests = TestRepository(conn)
        self._logs = LogRepository(conn)
        self._app_version = app_version

    async def start(
        self,
        *,
        correlation_id: uuid.UUID,
        kiosk_id: str | None,
        application_version: str | None,
    ) -> dict:
        session_id = new_id()
        token = secrets.token_urlsafe(32)
        version = application_version or self._app_version
        row = await self._tests.create_session(
            session_id=session_id,
            session_token=token,
            correlation_id=correlation_id,
            kiosk_id=kiosk_id,
            application_version=version,
        )
        await self._logs.add_event(
            event_type="TEST_STARTED",
            message="Test session started",
            application_version=version,
            kiosk_id=kiosk_id,
            session_id=session_id,
            correlation_id=correlation_id,
        )
        return {
            "session_id": str(row["id"]),
            "session_token": row["session_token"],
            "correlation_id": str(row["correlation_id"]),
            "status": row["status"],
            "started_at": row["started_at"].isoformat(),
        }

    async def submit_answer(
        self,
        *,
        session_id: uuid.UUID,
        session_token: str,
        correlation_id: uuid.UUID,
        question_number: int,
        option_code: str,
        response_time_ms: int | None,
    ) -> dict:
        session = await self._require_session(session_id, session_token)
        if session["status"] != "in_progress":
            raise HTTPException(status_code=409, detail="Session is not in progress.")
        option = await self._tests.find_option(question_number, option_code.upper())
        if option is None:
            raise HTTPException(status_code=404, detail="Question or option not found.")
        inserted = await self._tests.insert_answer(
            answer_id=new_id(),
            session_id=session_id,
            question_id=option["question_id"],
            option_id=option["option_id"],
            response_time_ms=response_time_ms,
        )
        if inserted:
            await self._logs.add_event(
                event_type="QUESTION_ANSWERED",
                message=f"Answered question {question_number}",
                application_version=session["application_version"],
                kiosk_id=session["kiosk_id"],
                session_id=session_id,
                correlation_id=correlation_id,
                metadata={"question_number": question_number, "option_code": option_code.upper()},
            )
        return {"accepted": True, "duplicate": not inserted}

    async def complete(
        self,
        *,
        session_id: uuid.UUID,
        session_token: str,
        correlation_id: uuid.UUID,
    ) -> dict:
        async with self._conn.transaction():
            session = await self._tests.get_session_for_update(session_id)
            if session is None or session["session_token"] != session_token:
                raise HTTPException(status_code=404, detail="Session not found.")
            if session["status"] == "completed":
                existing = await self._tests.get_result(session_id)
                if existing:
                    return _result_payload(existing)
            if session["status"] != "in_progress":
                raise HTTPException(status_code=409, detail="Session cannot be completed.")

            codes = await self._tests.list_answer_codes(session_id)
            if len(codes) != 15:
                raise HTTPException(
                    status_code=409,
                    detail=f"Test is incomplete ({len(codes)}/15 answers).",
                )
            winner = winner_from_codes(codes)
            payload = await self._tests.complete_session(
                session_id=session_id,
                result_id=new_id(),
                department_code=winner,
                codes=codes,
            )
            await self._logs.add_event(
                event_type="TEST_COMPLETED",
                message="Test session completed",
                application_version=session["application_version"],
                kiosk_id=session["kiosk_id"],
                session_id=session_id,
                correlation_id=correlation_id,
                metadata={"department_code": winner},
            )
        return payload

    async def abandon(
        self,
        *,
        session_id: uuid.UUID,
        session_token: str,
        correlation_id: uuid.UUID,
    ) -> dict:
        session = await self._require_session(session_id, session_token)
        await self._tests.abandon_session(session_id)
        await self._logs.add_event(
            event_type="TEST_ABANDONED",
            message="Test session abandoned",
            application_version=session["application_version"],
            kiosk_id=session["kiosk_id"],
            session_id=session_id,
            correlation_id=correlation_id,
        )
        return {"status": "abandoned"}

    async def result(self, session_id: uuid.UUID, session_token: str) -> dict:
        await self._require_session(session_id, session_token)
        existing = await self._tests.get_result(session_id)
        if existing is None:
            raise HTTPException(status_code=404, detail="Result not found.")
        return _result_payload(existing)

    async def _require_session(self, session_id: uuid.UUID, session_token: str) -> dict:
        session = await self._tests.get_session(session_id)
        if session is None or session["session_token"] != session_token:
            raise HTTPException(status_code=404, detail="Session not found.")
        return session


def _result_payload(row: dict) -> dict:
    breakdown = row["score_breakdown"]
    if isinstance(breakdown, str):
        import json

        breakdown = json.loads(breakdown)
    return {
        "department_code": row["code"],
        "department_name": row["name"],
        "description": row["description"],
        "slogan": row["slogan"],
        "emoji": row["emoji"],
        "score_breakdown": breakdown,
        "calculation_version": row["calculation_version"],
        "completed_at": row.get("completed_at").isoformat() if row.get("completed_at") else None,
    }
