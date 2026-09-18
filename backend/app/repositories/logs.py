from __future__ import annotations

import uuid
from typing import Any

import asyncpg

from app.observability import json_safe


class LogRepository:
    def __init__(self, conn: asyncpg.Connection) -> None:
        self._conn = conn

    async def add_event(
        self,
        *,
        event_type: str,
        message: str = "",
        application_version: str | None = None,
        kiosk_id: str | None = None,
        session_id: uuid.UUID | None = None,
        correlation_id: uuid.UUID | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        await self._conn.execute(
            """
            INSERT INTO application_events (
                event_type, message, application_version, kiosk_id,
                session_id, correlation_id, metadata
            ) VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb)
            """,
            event_type,
            message,
            application_version,
            kiosk_id,
            session_id,
            correlation_id,
            _json(metadata),
        )

    async def add_log(
        self,
        *,
        level: str,
        event_type: str,
        message: str,
        application_version: str | None = None,
        kiosk_id: str | None = None,
        session_id: uuid.UUID | None = None,
        correlation_id: uuid.UUID | None = None,
        endpoint: str | None = None,
        http_method: str | None = None,
        status_code: int | None = None,
        duration_ms: int | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        await self._conn.execute(
            """
            INSERT INTO application_logs (
                level, event_type, message, application_version, kiosk_id,
                session_id, correlation_id, endpoint, http_method, status_code,
                duration_ms, metadata
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::jsonb)
            """,
            level,
            event_type,
            message,
            application_version,
            kiosk_id,
            session_id,
            correlation_id,
            endpoint,
            http_method,
            status_code,
            duration_ms,
            _json(metadata),
        )

    async def add_error(
        self,
        *,
        message: str,
        exception_type: str | None = None,
        stack_trace: str | None = None,
        endpoint: str | None = None,
        http_method: str | None = None,
        status_code: int | None = None,
        correlation_id: uuid.UUID | None = None,
        session_id: uuid.UUID | None = None,
        kiosk_id: str | None = None,
        application_version: str | None = None,
        metadata: dict[str, Any] | None = None,
        level: str = "error",
    ) -> None:
        await self._conn.execute(
            """
            INSERT INTO application_errors (
                level, exception_type, message, stack_trace, endpoint,
                http_method, status_code, correlation_id, session_id,
                kiosk_id, application_version, metadata
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::jsonb)
            """,
            level,
            exception_type,
            message,
            _trim_stack(stack_trace),
            endpoint,
            http_method,
            status_code,
            correlation_id,
            session_id,
            kiosk_id,
            application_version,
            _json(metadata),
        )

    async def add_connection(
        self,
        *,
        component: str,
        status: str,
        duration_ms: int | None = None,
        error_message: str | None = None,
        application_version: str | None = None,
        kiosk_id: str | None = None,
        correlation_id: uuid.UUID | None = None,
    ) -> None:
        await self._conn.execute(
            """
            INSERT INTO connection_logs (
                component, status, duration_ms, error_message,
                application_version, kiosk_id, correlation_id
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            """,
            component,
            status,
            duration_ms,
            error_message,
            application_version,
            kiosk_id,
            correlation_id,
        )


def _json(metadata: dict[str, Any] | None) -> str:
    import json

    return json.dumps(json_safe(metadata), ensure_ascii=False)


def _trim_stack(stack_trace: str | None) -> str | None:
    if not stack_trace:
        return None
    return stack_trace[:8000]
