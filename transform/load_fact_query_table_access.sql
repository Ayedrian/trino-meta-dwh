-- Replaces one day from meta.fact_query_table_access with the inputs of the raw events that ended on that day
-- {day} is filled in by run_pipeline.py using the format YYYY-MM-DD
-- The day is deleted first, so that running again doesn't duplicate anything
--
-- Trino lists every table scan as its own inputs entry, meaning that a query
-- which scans a table twice (e.g. a self-join) is grouped into one row with the bytes summed
--
-- Raw events can arrive more than once, so only one row per query_id is kept
-- before unnesting, similar to load_fact_query.sql
--
-- Only data tables count as table usage. Inputs from the system catalog,
-- from information_schema and from Iceberg metadata tables (names with a $,
-- e.g. orders$snapshots) are dropped, since they represent mostly background calls
-- by tools.

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
FROM (
    SELECT *, row_number() OVER (PARTITION BY query_id) AS copy_number
    FROM raw.trino_query_completed
    -- Filter using end_time directly so that only the day's raw partition is read.
    -- The simpler date(end_time AT TIME ZONE 'UTC') = DATE '{day}' selects the same
    -- rows, but Trino can't prune partitions with it and would scan the entirety of raw
    WHERE end_time >= TIMESTAMP '{day} 00:00:00 UTC'
      AND end_time < TIMESTAMP '{day} 00:00:00 UTC' + INTERVAL '1' DAY
) AS e
CROSS JOIN UNNEST(e.inputs) AS i
WHERE e.copy_number = 1
  AND i.catalog_name <> 'system'
  AND i.schema_name <> 'information_schema'
  AND i.table_name NOT LIKE '%$%'
GROUP BY 1, 2, 3, 4, 5, 6
