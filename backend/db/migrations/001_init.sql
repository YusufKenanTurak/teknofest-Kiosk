CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS engineering_departments (
    id UUID PRIMARY KEY,
    code VARCHAR(8) NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    slogan TEXT NOT NULL DEFAULT '',
    emoji TEXT NOT NULL DEFAULT '',
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_engineering_departments_code UNIQUE (code),
    CONSTRAINT ck_engineering_departments_code CHECK (code IN ('B', 'K', 'Ç', 'M', 'E', 'İ', 'N'))
);

CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY,
    question_number INT NOT NULL,
    question_text TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_questions_number UNIQUE (question_number),
    CONSTRAINT ck_questions_number CHECK (question_number BETWEEN 1 AND 15)
);

CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY,
    question_id UUID NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    option_code CHAR(1) NOT NULL,
    option_text TEXT NOT NULL,
    department_id UUID NOT NULL REFERENCES engineering_departments (id) ON DELETE RESTRICT,
    score_weight INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_question_options_code UNIQUE (question_id, option_code),
    CONSTRAINT ck_question_options_code CHECK (option_code IN ('A', 'B', 'C', 'D')),
    CONSTRAINT ck_question_options_weight CHECK (score_weight >= 0)
);

CREATE TABLE IF NOT EXISTS test_sessions (
    id UUID PRIMARY KEY,
    session_token TEXT NOT NULL,
    kiosk_id TEXT,
    application_version TEXT,
    correlation_id UUID NOT NULL,
    status TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    duration_ms INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_test_sessions_token UNIQUE (session_token),
    CONSTRAINT ck_test_sessions_status CHECK (
        status IN ('in_progress', 'completed', 'abandoned', 'error')
    ),
    CONSTRAINT ck_test_sessions_duration CHECK (duration_ms IS NULL OR duration_ms >= 0)
);

CREATE TABLE IF NOT EXISTS test_answers (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES test_sessions (id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions (id) ON DELETE RESTRICT,
    selected_option_id UUID NOT NULL REFERENCES question_options (id) ON DELETE RESTRICT,
    answered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    response_time_ms INT,
    CONSTRAINT uq_test_answers_session_question UNIQUE (session_id, question_id),
    CONSTRAINT ck_test_answers_response_time CHECK (
        response_time_ms IS NULL OR response_time_ms >= 0
    )
);

CREATE TABLE IF NOT EXISTS test_results (
    id UUID PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES test_sessions (id) ON DELETE CASCADE,
    primary_department_id UUID NOT NULL REFERENCES engineering_departments (id) ON DELETE RESTRICT,
    score_breakdown JSONB NOT NULL DEFAULT '{}'::jsonb,
    calculation_version TEXT NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_test_results_session UNIQUE (session_id)
);

CREATE TABLE IF NOT EXISTS application_events (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    event_type TEXT NOT NULL,
    message TEXT NOT NULL DEFAULT '',
    application_version TEXT,
    kiosk_id TEXT,
    session_id UUID,
    correlation_id UUID,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS application_logs (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    level TEXT NOT NULL,
    event_type TEXT NOT NULL,
    message TEXT NOT NULL,
    application_version TEXT,
    kiosk_id TEXT,
    session_id UUID,
    correlation_id UUID,
    endpoint TEXT,
    http_method TEXT,
    status_code INT,
    duration_ms INT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT ck_application_logs_level CHECK (
        level IN ('debug', 'info', 'warning', 'error')
    )
);

CREATE TABLE IF NOT EXISTS application_errors (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    level TEXT NOT NULL DEFAULT 'error',
    exception_type TEXT,
    message TEXT NOT NULL,
    stack_trace TEXT,
    endpoint TEXT,
    http_method TEXT,
    status_code INT,
    correlation_id UUID,
    session_id UUID,
    kiosk_id TEXT,
    application_version TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT ck_application_errors_level CHECK (
        level IN ('warning', 'error', 'critical')
    )
);

CREATE TABLE IF NOT EXISTS connection_logs (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    component TEXT NOT NULL,
    status TEXT NOT NULL,
    duration_ms INT,
    error_message TEXT,
    application_version TEXT,
    kiosk_id TEXT,
    correlation_id UUID,
    CONSTRAINT ck_connection_logs_status CHECK (
        status IN ('startup', 'reconnect', 'health_ok', 'health_fail', 'error')
    )
);

DROP TRIGGER IF EXISTS trg_engineering_departments_updated_at ON engineering_departments;
CREATE TRIGGER trg_engineering_departments_updated_at
    BEFORE UPDATE ON engineering_departments
    FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

DROP TRIGGER IF EXISTS trg_questions_updated_at ON questions;
CREATE TRIGGER trg_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

DROP TRIGGER IF EXISTS trg_question_options_updated_at ON question_options;
CREATE TRIGGER trg_question_options_updated_at
    BEFORE UPDATE ON question_options
    FOR EACH ROW EXECUTE PROCEDURE set_updated_at();

CREATE INDEX IF NOT EXISTS idx_question_options_question_id
    ON question_options (question_id);
CREATE INDEX IF NOT EXISTS idx_question_options_department_id
    ON question_options (department_id);

CREATE INDEX IF NOT EXISTS idx_test_sessions_started_at
    ON test_sessions (started_at);
CREATE INDEX IF NOT EXISTS idx_test_sessions_status
    ON test_sessions (status);
CREATE INDEX IF NOT EXISTS idx_test_sessions_status_started
    ON test_sessions (status, started_at);
CREATE INDEX IF NOT EXISTS idx_test_sessions_kiosk_started
    ON test_sessions (kiosk_id, started_at)
    WHERE kiosk_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_test_sessions_version
    ON test_sessions (application_version)
    WHERE application_version IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_test_sessions_correlation
    ON test_sessions (correlation_id);

CREATE INDEX IF NOT EXISTS idx_test_answers_session_id
    ON test_answers (session_id);
CREATE INDEX IF NOT EXISTS idx_test_answers_question_id
    ON test_answers (question_id);
CREATE INDEX IF NOT EXISTS idx_test_answers_option_id
    ON test_answers (selected_option_id);

CREATE INDEX IF NOT EXISTS idx_test_results_department
    ON test_results (primary_department_id);
CREATE INDEX IF NOT EXISTS idx_test_results_completed_at
    ON test_results (completed_at);

CREATE INDEX IF NOT EXISTS idx_application_events_occurred_at
    ON application_events (occurred_at);
CREATE INDEX IF NOT EXISTS idx_application_events_type_occurred
    ON application_events (event_type, occurred_at);
CREATE INDEX IF NOT EXISTS idx_application_events_session
    ON application_events (session_id)
    WHERE session_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_application_events_correlation
    ON application_events (correlation_id)
    WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_application_logs_occurred_at
    ON application_logs (occurred_at);
CREATE INDEX IF NOT EXISTS idx_application_logs_level_occurred
    ON application_logs (level, occurred_at);
CREATE INDEX IF NOT EXISTS idx_application_logs_correlation
    ON application_logs (correlation_id)
    WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_application_errors_occurred_at
    ON application_errors (occurred_at);
CREATE INDEX IF NOT EXISTS idx_application_errors_correlation
    ON application_errors (correlation_id)
    WHERE correlation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_connection_logs_occurred_at
    ON connection_logs (occurred_at);
CREATE INDEX IF NOT EXISTS idx_connection_logs_status_occurred
    ON connection_logs (status, occurred_at);
