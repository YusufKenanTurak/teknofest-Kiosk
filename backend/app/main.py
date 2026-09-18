from __future__ import annotations

import time
import traceback
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exception_handlers import (
    http_exception_handler,
    request_validation_exception_handler,
)
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.config import get_settings
from app.db import close_pool, create_pool, get_pool
from app.observability import CorrelationIdMiddleware, correlation_from_request
from app.repositories.logs import LogRepository
from app.routes.api import router as api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.settings = settings
    started = time.perf_counter()
    try:
        await create_pool(settings)
        duration = int((time.perf_counter() - started) * 1000)
        async with get_pool().acquire() as conn:
            await LogRepository(conn).add_connection(
                component="postgresql",
                status="startup",
                duration_ms=duration,
                application_version=settings.application_version,
            )
    except Exception:
        # Startup connection failure is logged only if a later process can reach DB.
        raise
    yield
    await close_pool()


app = FastAPI(
    title="Teknofest Kiosk API",
    version="1.0.0",
    lifespan=lifespan,
)
app.add_middleware(CorrelationIdMiddleware)
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/health/db")
async def health_db(request: Request):
    started = time.perf_counter()
    try:
        async with get_pool().acquire() as conn:
            await conn.execute("SELECT 1")
        return {
            "status": "ok",
            "duration_ms": int((time.perf_counter() - started) * 1000),
            "correlation_id": str(correlation_from_request(request)),
        }
    except Exception as exc:
        duration = int((time.perf_counter() - started) * 1000)
        try:
            async with get_pool().acquire() as conn:
                await LogRepository(conn).add_connection(
                    component="postgresql",
                    status="health_fail",
                    duration_ms=duration,
                    error_message=str(exc),
                    correlation_id=correlation_from_request(request),
                    application_version=request.app.state.settings.application_version,
                )
        except Exception:
            pass
        return JSONResponse(
            status_code=503,
            content={"status": "error", "duration_ms": duration},
        )


@app.middleware("http")
async def access_log(request: Request, call_next):
    started = time.perf_counter()
    try:
        response = await call_next(request)
    except (StarletteHTTPException, RequestValidationError):
        raise
    except Exception as exc:
        correlation_id = correlation_from_request(request)
        await _record_unhandled(request, exc, correlation_id)
        response = JSONResponse(
            status_code=500,
            content={
                "detail": "Internal server error",
                "correlation_id": str(correlation_id),
            },
        )
    duration = int((time.perf_counter() - started) * 1000)
    if request.url.path.startswith("/api/"):
        try:
            async with get_pool().acquire() as conn:
                await LogRepository(conn).add_log(
                    level="info" if response.status_code < 500 else "error",
                    event_type="API_RESPONSE",
                    message="API request",
                    endpoint=request.url.path,
                    http_method=request.method,
                    status_code=response.status_code,
                    duration_ms=duration,
                    correlation_id=correlation_from_request(request),
                    application_version=request.app.state.settings.application_version,
                )
        except Exception:
            pass
    return response


async def _record_unhandled(request: Request, exc: Exception, correlation_id) -> None:
    try:
        async with get_pool().acquire() as conn:
            await LogRepository(conn).add_error(
                message=str(exc),
                exception_type=type(exc).__name__,
                stack_trace=traceback.format_exc(),
                endpoint=request.url.path,
                http_method=request.method,
                status_code=500,
                correlation_id=correlation_id,
                application_version=getattr(
                    getattr(request.app.state, "settings", None),
                    "application_version",
                    None,
                ),
            )
    except Exception:
        pass


@app.exception_handler(Exception)
async def unhandled_error(request: Request, exc: Exception):
    if isinstance(exc, RequestValidationError):
        return await request_validation_exception_handler(request, exc)
    if isinstance(exc, StarletteHTTPException):
        return await http_exception_handler(request, exc)
    correlation_id = correlation_from_request(request)
    await _record_unhandled(request, exc, correlation_id)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "correlation_id": str(correlation_id),
        },
    )


if get_settings().app_env in {"test", "dev", "development"}:

    @app.get("/api/v1/__debug/boom")
    async def debug_boom():
        raise RuntimeError("intentional-test-error")
