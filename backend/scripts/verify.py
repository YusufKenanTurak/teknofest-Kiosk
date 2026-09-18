from __future__ import annotations

import argparse
import asyncio
import json
import os
from typing import Any

import asyncpg

EXPECTED_TABLES = {
    "schema_migrations",
    "engineering_departments",
    "questions",
    "question_options",
    "test_sessions",
    "test_answers",
    "test_results",
    "application_events",
    "application_logs",
    "application_errors",
    "connection_logs",
}

EXPECTED_VIEWS = {
    "v_session_overview",
    "v_department_distribution",
    "v_question_option_stats",
    "v_question_unanswered",
    "v_daily_sessions",
    "v_hourly_sessions",
    "v_error_overview",
}


def _env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise SystemExit(f"{name} is required")
    return value


async def _connect(*, user: str, password: str, database: str, host: str, port: int):
    return await asyncpg.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        database=database,
        timeout=10,
    )


async def verify(admin: dict[str, Any], app: dict[str, Any], database: str) -> dict[str, Any]:
    report: dict[str, Any] = {"ok": True, "checks": [], "warnings": []}

    def check(name: str, passed: bool, detail: str = "") -> None:
        report["checks"].append({"name": name, "passed": passed, "detail": detail})
        if not passed:
            report["ok"] = False

    conn = await _connect(database=database, **admin)
    try:
        tables = {
            row["tablename"]
            for row in await conn.fetch(
                "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
            )
        }
        missing = sorted(EXPECTED_TABLES - tables)
        check("tables", not missing, f"missing={missing}" if missing else "all present")

        views = {
            row["viewname"]
            for row in await conn.fetch(
                "SELECT viewname FROM pg_views WHERE schemaname = 'public'"
            )
        }
        missing_views = sorted(EXPECTED_VIEWS - views)
        check("views", not missing_views, f"missing={missing_views}" if missing_views else "all present")

        fks = await conn.fetch(
            """
            SELECT conname
            FROM pg_constraint
            WHERE contype = 'f' AND connamespace = 'public'::regnamespace
            """
        )
        check("foreign_keys", len(fks) >= 6, f"count={len(fks)}")

        indexes = await conn.fetch(
            """
            SELECT indexname
            FROM pg_indexes
            WHERE schemaname = 'public'
              AND indexname LIKE 'idx_%'
            """
        )
        check("indexes", len(indexes) >= 10, f"count={len(indexes)}")

        dept_count = await conn.fetchval("SELECT COUNT(*) FROM engineering_departments")
        q_count = await conn.fetchval("SELECT COUNT(*) FROM questions")
        o_count = await conn.fetchval("SELECT COUNT(*) FROM question_options")
        check("seed_departments", dept_count == 7, f"count={dept_count}")
        check("seed_questions", q_count == 15, f"count={q_count}")
        check("seed_options", o_count == 60, f"count={o_count}")

        migrations = await conn.fetch("SELECT version FROM schema_migrations ORDER BY version")
        applied = [row["version"] for row in migrations]
        check(
            "migrations",
            applied == ["001_init.sql", "002_stats_views.sql", "003_grants.sql"],
            f"applied={applied}",
        )

        inherited = [
            row["rolname"]
            for row in await conn.fetch(
                """
                SELECT r.rolname
                FROM pg_roles r
                JOIN pg_auth_members m ON r.oid = m.roleid
                JOIN pg_roles u ON u.oid = m.member
                WHERE u.rolname = 'appuser'
                """
            )
        ]
        question_acl = {
            row["privilege_type"]
            for row in await conn.fetch(
                """
                SELECT privilege_type
                FROM information_schema.role_table_grants
                WHERE table_schema = 'public'
                  AND table_name = 'questions'
                  AND grantee = 'appuser'
                """
            )
        }
        check(
            "questions_table_acl_select_only",
            question_acl == {"SELECT"},
            f"acl={sorted(question_acl)}",
        )
        if {"pg_read_all_data", "pg_write_all_data"} & set(inherited):
            report["warnings"].append(
                "appuser inherits "
                + ", ".join(sorted(set(inherited) & {"pg_read_all_data", "pg_write_all_data"}))
                + " (cluster-wide). Table ACLs on this database cannot hide DML. "
                "If appuser is exclusive to this app, REVOKE those predefined roles."
            )

        owner = await conn.fetchval(
            "SELECT pg_catalog.pg_get_userbyid(datdba) FROM pg_database WHERE datname = current_database()"
        )
        check("database_owner_not_appuser", owner != "appuser", f"owner={owner}")
    finally:
        await conn.close()

    app_conn = await _connect(database=database, **app)
    try:
        await app_conn.execute("SELECT 1 FROM questions LIMIT 1")
        check("appuser_select_questions", True, "ok")

        try:
            await app_conn.execute("CREATE TABLE appuser_should_not_create (id int)")
            check("appuser_cannot_create_table", False, "CREATE TABLE succeeded")
            await app_conn.execute("DROP TABLE appuser_should_not_create")
        except asyncpg.InsufficientPrivilegeError:
            check("appuser_cannot_create_table", True, "permission denied")

        try:
            await app_conn.execute("CREATE SCHEMA appuser_schema")
            check("appuser_cannot_create_schema", False, "CREATE SCHEMA succeeded")
        except asyncpg.InsufficientPrivilegeError:
            check("appuser_cannot_create_schema", True, "permission denied")
    finally:
        await app_conn.close()

    postgres = await _connect(database="postgres", **app)
    try:
        try:
            await postgres.execute(f'DROP DATABASE "{database}"')
            check("appuser_cannot_drop_database", False, "DROP DATABASE succeeded")
        except asyncpg.PostgresError as exc:
            check("appuser_cannot_drop_database", True, type(exc).__name__)
    finally:
        await postgres.close()

    return report


async def main() -> None:
    parser = argparse.ArgumentParser(description="Validate schema and least-privilege roles")
    parser.add_argument("--host", default=os.environ.get("PG_HOST", "10.6.228.154"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("PG_PORT", "5432")))
    parser.add_argument("--database", default=os.environ.get("PG_DATABASE", "teknofestKiosk"))
    parser.add_argument("--admin-user", default=os.environ.get("PG_ADMIN_USER", "dev_admin"))
    parser.add_argument("--app-user", default=os.environ.get("PG_APP_USER", os.environ.get("PG_USER", "appuser")))
    args = parser.parse_args()
    admin = {
        "host": args.host,
        "port": args.port,
        "user": args.admin_user,
        "password": _env("PG_ADMIN_PASSWORD"),
    }
    app = {
        "host": args.host,
        "port": args.port,
        "user": args.app_user,
        "password": _env("PG_PASSWORD"),
    }
    report = await verify(admin, app, args.database)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    if not report["ok"]:
        raise SystemExit(1)


if __name__ == "__main__":
    asyncio.run(main())
