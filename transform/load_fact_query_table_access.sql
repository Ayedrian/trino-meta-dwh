-- Replaces one day from meta.fact_query_table_access with the inputs of the raw events that ended on that day
-- {day} is filled in by run_pipeline.py using the format YYYY-MM-DD
-- The day is deleted first, so that running again doesn't duplicate anything
--
-- Trino lists every table scan as its own inputs entry, meaning that a query
-- which scans a table twice (e.g. a self-join) is grouped into one row with the bytes summed

DELETE FROM meta.fact_query_table_access WHERE query_date = DATE '{day}';

INSERT INTO meta.fact_query_table_access
    (query_id, query_date, user, catalog_name, schema_name, table_name, physical_input_bytes)
SELECT
    e.query_id,
    date(e.end_time AT TIME ZONE 'UTC'),
    e.user,
    i.catalog_name,
    i.schema_name,
    i.table_name,
    sum(i.physical_input_bytes)
FROM raw.trino_query_completed AS e
CROSS JOIN UNNEST(e.inputs) AS i
-- Filter using end_time directly so that only the day's raw partition is read.
-- The simpler date(end_time AT TIME ZONE 'UTC') = DATE '{day}' selects the same
-- rows, but Trino can't prune partitions with it and would scan the entirety of raw
WHERE e.end_time >= TIMESTAMP '{day} 00:00:00 UTC'
  AND e.end_time < TIMESTAMP '{day} 00:00:00 UTC' + INTERVAL '1' DAY
GROUP BY 1, 2, 3, 4, 5, 6
