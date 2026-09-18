from __future__ import annotations

import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, Header, Query, Request
from pydantic import BaseModel, Field

from app.db import get_pool
from app.observability import correlation_from_request
from app.repositories.stats import StatsRepository
from app.services.test_service import TestService

router = APIRouter()


class StartTestBody(BaseModel):
    kiosk_id: str | None = Field(default=None, max_length=64)
    application_version: str | None = Field(default=None, max_length=32)


class AnswerBody(BaseModel):
    question_number: int = Field(ge=1, le=15)
    option_code: str = Field(min_length=1, max_length=1)
    response_time_ms: int | None = Field(default=None, ge=0)


def _token(x_session_token: str = Header(..., alias="X-Session-Token")) -> str:
    return x_session_token


@router.post("/tests")
async def start_test(body: StartTestBody, request: Request):
    async with get_pool().acquire() as conn:
        service = TestService(conn, request.app.state.settings.application_version)
        return await service.start(
            correlation_id=correlation_from_request(request),
            kiosk_id=body.kiosk_id,
            application_version=body.application_version,
        )


@router.post("/tests/{session_id}/answers")
async def submit_answer(
    session_id: uuid.UUID,
    body: AnswerBody,
    request: Request,
    session_token: str = Depends(_token),
):
    async with get_pool().acquire() as conn:
        service = TestService(conn, request.app.state.settings.application_version)
        return await service.submit_answer(
            session_id=session_id,
            session_token=session_token,
            correlation_id=correlation_from_request(request),
            question_number=body.question_number,
            option_code=body.option_code,
            response_time_ms=body.response_time_ms,
        )


@router.post("/tests/{session_id}/complete")
async def complete_test(
    session_id: uuid.UUID,
    request: Request,
    session_token: str = Depends(_token),
):
    async with get_pool().acquire() as conn:
        service = TestService(conn, request.app.state.settings.application_version)
        return await service.complete(
            session_id=session_id,
            session_token=session_token,
            correlation_id=correlation_from_request(request),
        )


@router.post("/tests/{session_id}/abandon")
async def abandon_test(
    session_id: uuid.UUID,
    request: Request,
    session_token: str = Depends(_token),
):
    async with get_pool().acquire() as conn:
        service = TestService(conn, request.app.state.settings.application_version)
        return await service.abandon(
            session_id=session_id,
            session_token=session_token,
            correlation_id=correlation_from_request(request),
        )


@router.get("/tests/{session_id}/result")
async def get_result(
    session_id: uuid.UUID,
    request: Request,
    session_token: str = Depends(_token),
):
    async with get_pool().acquire() as conn:
        service = TestService(conn, request.app.state.settings.application_version)
        return await service.result(session_id, session_token)


@router.get("/questions")
async def list_questions():
    async with get_pool().acquire() as conn:
        return {"questions": await StatsRepository(conn).catalog()}


def _range(
    started_from: datetime | None = Query(default=None, alias="from"),
    started_to: datetime | None = Query(default=None, alias="to"),
):
    return started_from, started_to


@router.get("/statistics/overview")
async def stats_overview(bounds: tuple = Depends(_range)):
    async with get_pool().acquire() as conn:
        return await StatsRepository(conn).overview(*bounds)


@router.get("/statistics/departments")
async def stats_departments(bounds: tuple = Depends(_range)):
    async with get_pool().acquire() as conn:
        return {"departments": await StatsRepository(conn).departments(*bounds)}


@router.get("/statistics/questions")
async def stats_questions():
    async with get_pool().acquire() as conn:
        repo = StatsRepository(conn)
        return {
            "options": await repo.questions(),
            "unanswered": await repo.unanswered(),
        }


@router.get("/statistics/daily")
async def stats_daily(bounds: tuple = Depends(_range)):
    async with get_pool().acquire() as conn:
        return {"days": await StatsRepository(conn).daily(*bounds)}


@router.get("/statistics/hourly")
async def stats_hourly(bounds: tuple = Depends(_range)):
    async with get_pool().acquire() as conn:
        return {"hours": await StatsRepository(conn).hourly(*bounds)}


@router.get("/statistics/errors")
async def stats_errors(bounds: tuple = Depends(_range)):
    async with get_pool().acquire() as conn:
        return {"errors": await StatsRepository(conn).errors(*bounds)}


@router.get("/statistics/versions")
async def stats_versions():
    async with get_pool().acquire() as conn:
        return {"versions": await StatsRepository(conn).by_version()}


@router.get("/statistics/kiosks")
async def stats_kiosks():
    async with get_pool().acquire() as conn:
        return {"kiosks": await StatsRepository(conn).by_kiosk()}
