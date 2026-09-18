from __future__ import annotations

import json
import os
import uuid
from pathlib import Path

import asyncpg
import pytest
from httpx import AsyncClient

from app.config import get_settings
from app.db import get_pool
from app.scoring import calculate_result

CATALOG = json.loads(
    (Path(__file__).resolve().parents[1] / "db" / "seed" / "catalog.json").read_text(
        encoding="utf-8"
    )
)
OPTION_CODES = [question["options"][0]["code"] for question in CATALOG["questions"]]
EXPECTED_WINNER = calculate_result(
    [question["options"][0]["department"] for question in CATALOG["questions"]]
)


def _admin_kwargs() -> dict:
    return {
        "host": os.environ.get("PG_HOST", "10.6.228.154"),
        "port": int(os.environ.get("PG_PORT", "5432")),
        "user": os.environ.get("PG_ADMIN_USER", "dev_admin"),
        "password": os.environ["PG_ADMIN_PASSWORD"],
        "database": os.environ.get("PG_DATABASE", "teknofestKiosk"),
        "timeout": 10,
    }


async def _start(client: AsyncClient, correlation_id: str | None = None) -> dict:
    headers = {}
    if correlation_id:
        headers["X-Correlation-ID"] = correlation_id
    response = await client.post(
        "/api/v1/tests",
        json={"kiosk_id": "pytest-kiosk", "application_version": "1.0.0-test"},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    return response.json()


async def _answer(client: AsyncClient, session: dict, number: int, code: str) -> dict:
    response = await client.post(
        f"/api/v1/tests/{session['session_id']}/answers",
        json={"question_number": number, "option_code": code, "response_time_ms": 120},
        headers={"X-Session-Token": session["session_token"]},
    )
    assert response.status_code == 200, response.text
    return response.json()


@pytest.mark.asyncio
async def test_health_and_db(client: AsyncClient):
    health = await client.get("/health")
    assert health.status_code == 200
    db = await client.get("/health/db")
    assert db.status_code == 200
    assert db.json()["status"] == "ok"
    assert "X-Correlation-ID" in db.headers


@pytest.mark.asyncio
async def test_runtime_uses_appuser():
    settings = get_settings()
    assert settings.pg_user == "appuser"
    assert settings.pg_user != "dev_admin"


@pytest.mark.asyncio
async def test_catalog_has_fifteen_questions(client: AsyncClient):
    response = await client.get("/api/v1/questions")
    assert response.status_code == 200
    questions = response.json()["questions"]
    assert len(questions) == 15
    assert [q["number"] for q in questions] == list(range(1, 16))
    for question in questions:
        assert len(question["options"]) == 4


@pytest.mark.asyncio
async def test_full_session_answers_result_and_stats(client: AsyncClient):
    correlation_id = str(uuid.uuid4())
    session = await _start(client, correlation_id)
    assert session["status"] == "in_progress"
    assert client.headers is not None
    assert session["correlation_id"] == correlation_id

    for index, code in enumerate(OPTION_CODES, start=1):
        body = await _answer(client, session, index, code)
        assert body["accepted"] is True
        assert body["duplicate"] is False

    complete = await client.post(
        f"/api/v1/tests/{session['session_id']}/complete",
        headers={"X-Session-Token": session["session_token"]},
    )
    assert complete.status_code == 200, complete.text
    payload = complete.json()
    assert payload["department_code"] == EXPECTED_WINNER
    assert payload["calculation_version"] == "score-v1-endscan"
    assert sum(payload["score_breakdown"].values()) == 15

    result = await client.get(
        f"/api/v1/tests/{session['session_id']}/result",
        headers={"X-Session-Token": session["session_token"]},
    )
    assert result.status_code == 200
    assert result.json()["department_code"] == EXPECTED_WINNER

    overview = await client.get("/api/v1/statistics/overview")
    assert overview.status_code == 200
    body = overview.json()
    assert body["total_tests"] >= 1
    assert body["completed_tests"] >= 1
    assert "completion_rate_pct" in body
    assert "avg_duration_ms" in body

    departments = await client.get("/api/v1/statistics/departments")
    assert departments.status_code == 200
    codes = {item["code"] for item in departments.json()["departments"]}
    assert codes == {"B", "K", "Ç", "M", "E", "İ", "N"}
    winner_row = next(
        item
        for item in departments.json()["departments"]
        if item["code"] == EXPECTED_WINNER
    )
    assert winner_row["result_count"] >= 1

    questions = await client.get("/api/v1/statistics/questions")
    assert questions.status_code == 200
    assert len(questions.json()["options"]) == 60

    daily = await client.get("/api/v1/statistics/daily")
    hourly = await client.get("/api/v1/statistics/hourly")
    assert daily.status_code == 200
    assert hourly.status_code == 200
    assert daily.json()["days"]
    assert hourly.json()["hours"]


@pytest.mark.asyncio
async def test_duplicate_answer_is_ignored(client: AsyncClient):
    session = await _start(client)
    first = await _answer(client, session, 1, "A")
    second = await _answer(client, session, 1, "B")
    assert first["duplicate"] is False
    assert second["duplicate"] is True

    pool = get_pool()
    async with pool.acquire() as conn:
        count = await conn.fetchval(
            """
            SELECT COUNT(*) FROM test_answers a
            JOIN test_sessions s ON s.id = a.session_id
            WHERE s.session_token = $1
            """,
            session["session_token"],
        )
        option = await conn.fetchval(
            """
            SELECT o.option_code
            FROM test_answers a
            JOIN test_sessions s ON s.id = a.session_id
            JOIN question_options o ON o.id = a.selected_option_id
            JOIN questions q ON q.id = a.question_id
            WHERE s.session_token = $1 AND q.question_number = 1
            """,
            session["session_token"],
        )
    assert count == 1
    assert str(option).strip() == "A"


@pytest.mark.asyncio
async def test_incomplete_complete_rolls_back(client: AsyncClient):
    session = await _start(client)
    await _answer(client, session, 1, "A")
    response = await client.post(
        f"/api/v1/tests/{session['session_id']}/complete",
        headers={"X-Session-Token": session["session_token"]},
    )
    assert response.status_code == 409

    pool = get_pool()
    async with pool.acquire() as conn:
        status = await conn.fetchval(
            "SELECT status FROM test_sessions WHERE session_token = $1",
            session["session_token"],
        )
        results = await conn.fetchval(
            """
            SELECT COUNT(*) FROM test_results r
            JOIN test_sessions s ON s.id = r.session_id
            WHERE s.session_token = $1
            """,
            session["session_token"],
        )
    assert status == "in_progress"
    assert results == 0


@pytest.mark.asyncio
async def test_correlation_id_is_stored(client: AsyncClient):
    correlation_id = str(uuid.uuid4())
    session = await _start(client, correlation_id)
    pool = get_pool()
    async with pool.acquire() as conn:
        stored = await conn.fetchval(
            """
            SELECT correlation_id FROM application_events
            WHERE session_id = $1::uuid AND event_type = 'TEST_STARTED'
            ORDER BY id DESC LIMIT 1
            """,
            session["session_id"],
        )
        session_cid = await conn.fetchval(
            "SELECT correlation_id FROM test_sessions WHERE id = $1::uuid",
            session["session_id"],
        )
    assert str(stored) == correlation_id
    assert str(session_cid) == correlation_id


@pytest.mark.asyncio
async def test_unhandled_error_is_persisted(client: AsyncClient):
    correlation_id = str(uuid.uuid4())
    response = await client.get(
        "/api/v1/__debug/boom",
        headers={"X-Correlation-ID": correlation_id},
    )
    assert response.status_code == 500
    assert response.json()["correlation_id"] == correlation_id
    errors = await client.get("/api/v1/statistics/errors")
    assert errors.status_code == 200
    match = next(
        item
        for item in errors.json()["errors"]
        if item.get("correlation_id") == correlation_id
    )
    assert match["exception_type"] == "RuntimeError"


@pytest.mark.asyncio
async def test_pool_reconnects_after_restart():
    from tests.conftest import _api_client

    async with _api_client() as first:
        assert (await first.get("/health/db")).status_code == 200
    async with _api_client() as second:
        assert (await second.get("/health/db")).status_code == 200


@pytest.mark.asyncio
async def test_seed_second_run_does_not_duplicate():
    if not os.environ.get("PG_ADMIN_PASSWORD"):
        pytest.skip("PG_ADMIN_PASSWORD required")
    conn = await asyncpg.connect(**_admin_kwargs())
    try:
        before_q = await conn.fetchval("SELECT COUNT(*) FROM questions")
        before_o = await conn.fetchval("SELECT COUNT(*) FROM question_options")
        from importlib.util import module_from_spec, spec_from_file_location

        seed_path = Path(__file__).resolve().parents[1] / "scripts" / "seed.py"
        spec = spec_from_file_location("kiosk_seed", seed_path)
        module = module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(module)
        await module.seed(conn)
        after_q = await conn.fetchval("SELECT COUNT(*) FROM questions")
        after_o = await conn.fetchval("SELECT COUNT(*) FROM question_options")
        after_d = await conn.fetchval("SELECT COUNT(*) FROM engineering_departments")
    finally:
        await conn.close()
    assert before_q == after_q == 15
    assert before_o == after_o == 60
    assert after_d == 7
