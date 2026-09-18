CREATE OR REPLACE VIEW v_session_overview AS
SELECT
    COUNT(*) AS total_tests,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_tests,
    COUNT(*) FILTER (WHERE status = 'abandoned') AS abandoned_tests,
    COUNT(*) FILTER (WHERE status = 'error') AS error_tests,
    COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress_tests,
    CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
            100.0 * COUNT(*) FILTER (WHERE status = 'completed') / COUNT(*),
            2
        )
    END AS completion_rate_pct,
    ROUND(AVG(duration_ms) FILTER (WHERE status = 'completed')) AS avg_duration_ms,
    MIN(duration_ms) FILTER (WHERE status = 'completed') AS min_duration_ms,
    MAX(duration_ms) FILTER (WHERE status = 'completed') AS max_duration_ms
FROM test_sessions;

CREATE OR REPLACE VIEW v_department_distribution AS
SELECT
    d.code,
    d.name,
    COUNT(r.id) AS result_count,
    CASE
        WHEN SUM(COUNT(r.id)) OVER () = 0 THEN 0
        ELSE ROUND(
            100.0 * COUNT(r.id) / SUM(COUNT(r.id)) OVER (),
            2
        )
    END AS result_pct
FROM engineering_departments d
LEFT JOIN test_results r ON r.primary_department_id = d.id
GROUP BY d.id, d.code, d.name, d.sort_order
ORDER BY d.sort_order, d.code;

CREATE OR REPLACE VIEW v_question_option_stats AS
SELECT
    q.question_number,
    q.question_text,
    o.option_code,
    o.option_text,
    d.code AS department_code,
    COUNT(a.id) AS selected_count,
    COUNT(DISTINCT s.id) FILTER (
        WHERE s.status IN ('completed', 'abandoned', 'error', 'in_progress')
    ) AS session_touch_count
FROM questions q
JOIN question_options o ON o.question_id = q.id
JOIN engineering_departments d ON d.id = o.department_id
LEFT JOIN test_answers a ON a.selected_option_id = o.id
LEFT JOIN test_sessions s ON s.id = a.session_id
GROUP BY
    q.question_number,
    q.question_text,
    o.option_code,
    o.option_text,
    d.code
ORDER BY q.question_number, o.option_code;

CREATE OR REPLACE VIEW v_question_unanswered AS
SELECT
    q.question_number,
    q.question_text,
    COUNT(s.id) AS completed_sessions,
    COUNT(a.id) AS answered_in_completed,
    CASE
        WHEN COUNT(s.id) = 0 THEN 0
        ELSE ROUND(
            100.0 * (COUNT(s.id) - COUNT(a.id)) / COUNT(s.id),
            2
        )
    END AS unanswered_pct
FROM questions q
LEFT JOIN test_sessions s ON s.status = 'completed'
LEFT JOIN test_answers a
    ON a.session_id = s.id
   AND a.question_id = q.id
GROUP BY q.question_number, q.question_text
ORDER BY q.question_number;

CREATE OR REPLACE VIEW v_daily_sessions AS
SELECT
    (started_at AT TIME ZONE 'UTC')::date AS day,
    COUNT(*) AS total_tests,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_tests,
    COUNT(*) FILTER (WHERE status = 'abandoned') AS abandoned_tests,
    COUNT(*) FILTER (WHERE status = 'error') AS error_tests,
    ROUND(AVG(duration_ms) FILTER (WHERE status = 'completed')) AS avg_duration_ms
FROM test_sessions
GROUP BY (started_at AT TIME ZONE 'UTC')::date
ORDER BY day;

CREATE OR REPLACE VIEW v_hourly_sessions AS
SELECT
    date_trunc('hour', started_at) AS hour_utc,
    COUNT(*) AS total_tests,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_tests
FROM test_sessions
GROUP BY date_trunc('hour', started_at)
ORDER BY hour_utc;

CREATE OR REPLACE VIEW v_error_overview AS
SELECT
    date_trunc('day', occurred_at) AS day_utc,
    COUNT(*) AS error_count,
    COUNT(*) FILTER (WHERE level = 'critical') AS critical_count
FROM application_errors
GROUP BY date_trunc('day', occurred_at)
ORDER BY day_utc;
