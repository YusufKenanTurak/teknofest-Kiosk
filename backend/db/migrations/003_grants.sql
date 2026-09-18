-- Runtime role: appuser. Administration stays with the migration user.
-- Cluster-level predefined roles (pg_read_all_data / pg_write_all_data) are
-- not revoked here: appuser is shared. Table ACLs below still document the
-- intended least-privilege surface for this database.
REVOKE ALL ON DATABASE "teknofestKiosk" FROM PUBLIC;
GRANT CONNECT ON DATABASE "teknofestKiosk" TO appuser;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO appuser;

GRANT SELECT ON
    engineering_departments,
    questions,
    question_options,
    v_session_overview,
    v_department_distribution,
    v_question_option_stats,
    v_question_unanswered,
    v_daily_sessions,
    v_hourly_sessions,
    v_error_overview
TO appuser;

GRANT SELECT, INSERT, UPDATE ON test_sessions TO appuser;
GRANT SELECT, INSERT ON test_answers TO appuser;
GRANT SELECT, INSERT ON test_results TO appuser;
GRANT INSERT, SELECT ON application_events TO appuser;
GRANT INSERT, SELECT ON application_logs TO appuser;
GRANT INSERT, SELECT ON application_errors TO appuser;
GRANT INSERT, SELECT ON connection_logs TO appuser;

GRANT USAGE, SELECT ON SEQUENCE application_events_id_seq TO appuser;
GRANT USAGE, SELECT ON SEQUENCE application_logs_id_seq TO appuser;
GRANT USAGE, SELECT ON SEQUENCE application_errors_id_seq TO appuser;
GRANT USAGE, SELECT ON SEQUENCE connection_logs_id_seq TO appuser;

REVOKE DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public FROM appuser;
REVOKE CREATE ON SCHEMA public FROM appuser;
