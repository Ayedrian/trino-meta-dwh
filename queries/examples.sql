-- =============================================================================
-- Example queries based on the task's questions. Table and period are
-- specified with literals, you can change them to ask about something else.
-- Periods are whole UTC days, first and last day are inclusive
-- =============================================================================

-- How many distinct users queried the table X during a specified period of time?
-- Read from just the bridge, since it contains the user and the day of every query
SELECT count(DISTINCT user) AS distinct_users
FROM meta.fact_query_table_access
WHERE catalog_name = 'iceberg'
  AND schema_name = 'analytics'
  AND table_name = 'page_views'
  AND query_date BETWEEN DATE '2026-11-10' AND DATE '2026-11-12'
