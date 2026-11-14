-- =============================================================================
-- Example queries based on the task's questions. Table, team and period are
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
  AND query_date BETWEEN DATE '2026-11-10' AND DATE '2026-11-12';

-- How many resources did team Y consume during a specified period of time?
-- Every query counts fully towards the team that the user was on the day it
-- completed, so a user that switched teams during the period has their earlier
-- queries attributed to the old team, and later ones to the new team.
-- Users without a team fall under 'unknown', which can be queried for like
-- any other team
SELECT
    sum(f.cpu_time_ms)          AS cpu_time_ms,
    sum(f.physical_input_bytes) AS physical_input_bytes
FROM meta.fact_query AS f
LEFT JOIN meta.user_team_membership AS m
    ON m.user = f.user
   AND f.query_date >= m.valid_from
   AND f.query_date < m.valid_to
WHERE coalesce(m.team, 'unknown') = 'product-analytics'
  AND f.query_date BETWEEN DATE '2026-11-10' AND DATE '2026-11-12';

-- How did the usage of team Y change over time?
-- One row per week (weeks start on Monday) with the team's queries, distinct users,
-- CPU and bytes, with users assigned to teams as in the previous query. Distinct
-- users are counted per week from the facts, never summed up from days.
-- Change 'week' (and week_start) to 'day' or 'month' for another grain, and let the
-- period start and end on the grain's boundaries so the first and last rows are whole.
-- Weeks without any queries from the team have no row
SELECT
    date_trunc('week', f.query_date) AS week_start,
    count(*)                         AS queries,
    count(DISTINCT f.user)           AS distinct_users,
    sum(f.cpu_time_ms)               AS cpu_time_ms,
    sum(f.physical_input_bytes)      AS physical_input_bytes
FROM meta.fact_query AS f
LEFT JOIN meta.user_team_membership AS m
    ON m.user = f.user
   AND f.query_date >= m.valid_from
   AND f.query_date < m.valid_to
WHERE coalesce(m.team, 'unknown') = 'product-analytics'
  AND f.query_date BETWEEN DATE '2026-11-09' AND DATE '2026-11-15'
GROUP BY 1
ORDER BY 1;
