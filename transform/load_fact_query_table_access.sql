-- Repopulates meta.fact_query_table_access from raw events
-- Emptied first, so that running again doesn't duplicate anything
--
-- Trino lists every table scan as its own inputs entry, meaning that a query
-- which scans a table twice (e.g. a self-join) is grouped into one row with the bytes summed

DELETE FROM meta.fact_query_table_access;

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
GROUP BY 1, 2, 3, 4, 5, 6
