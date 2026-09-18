from __future__ import annotations

import uuid
from typing import Any

from starlette.types import ASGIApp, Receive, Scope, Send

CORRELATION_HEADER = "X-Correlation-ID"


def new_id() -> uuid.UUID:
    return uuid.uuid4()


def resolve_correlation_id(value: str | None) -> uuid.UUID:
    if not value:
        return uuid.uuid4()
    try:
        return uuid.UUID(value)
    except ValueError:
        return uuid.uuid4()


class CorrelationIdMiddleware:
    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        raw = None
        for key, value in scope.get("headers", []):
            if key.lower() == b"x-correlation-id":
                raw = value.decode("latin-1")
                break
        correlation_id = resolve_correlation_id(raw)
        state = scope.setdefault("state", {})
        state["correlation_id"] = correlation_id

        async def send_wrapper(message: dict) -> None:
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                headers.append(
                    (b"x-correlation-id", str(correlation_id).encode("ascii"))
                )
                message = {**message, "headers": headers}
            await send(message)

        await self.app(scope, receive, send_wrapper)


def correlation_from_request(request: Any) -> uuid.UUID:
    value = getattr(getattr(request, "state", None), "correlation_id", None)
    return value if isinstance(value, uuid.UUID) else uuid.uuid4()


def json_safe(metadata: dict[str, Any] | None) -> dict[str, Any]:
    blocked = {
        "password",
        "pg_password",
        "authorization",
        "token",
        "secret",
        "api_key",
        "apikey",
        "refresh_token",
        "jwt",
    }
    safe: dict[str, Any] = {}
    for key, value in (metadata or {}).items():
        if key.lower() in blocked:
            continue
        safe[key] = value
    return safe
