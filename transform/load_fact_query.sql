-- Replaces one day of meta.fact_query with the raw events that ended on that day
-- {day} is filled in by run_pipeline.py using the format YYYY-MM-DD (ISO 8601 ftw!)
-- The day is deleted first, so that running again doesn't duplicate anything

DELETE FROM meta.fact_query WHERE query_date = DATE '{day}';

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
-- Filter using end_time directly so that only the day's raw partition is read.
-- The simpler date(end_time AT TIME ZONE 'UTC') = DATE '{day}' selects the same
-- rows, but Trino can't prune partitions with it and would scan the entirety of raw
WHERE end_time >= TIMESTAMP '{day} 00:00:00 UTC'
  AND end_time < TIMESTAMP '{day} 00:00:00 UTC' + INTERVAL '1' DAY
