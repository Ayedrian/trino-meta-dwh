-- Repopulates meta.fact_query from raw events
-- Emptied first, so that running again doesn't duplicate anything

DELETE FROM meta.fact_query;

INSERT INTO meta.fact_query
    (query_id, query_state, user, end_time, query_date, cpu_time_ms, physical_input_bytes, peak_user_memory_bytes)
SELECT
    query_id,
    query_state,
    user,
    end_time,
    date(end_time AT TIME ZONE 'UTC'),
    cpu_time_ms,
    physical_input_bytes,
    peak_user_memory_bytes
FROM raw.trino_query_completed
