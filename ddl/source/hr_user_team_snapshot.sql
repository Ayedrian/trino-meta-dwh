-- =============================================================================
-- One row per user and day, from the daily export of HR's user-to-team mapping
-- (for example from LDAP). Every export from HR is a full list of users with
-- their current team, and every day's export is kept. This is an "upstream"
-- table which the Meta DWH only reads from, it's not part of the Meta DWH model.
-- The "real" export would most likely have additional fields (name, manager, department),
-- this table is just here for the demo.
--
-- Service accounts have to be in the export too, mapped to the team that owns
-- them, otherwise their usage ends up under the team "unknown"
-- =============================================================================

-- "if not exists" so that demo can be re-run
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.hr_user_team_snapshot (
    snapshot_date DATE    COMMENT 'Day of the export, the team applies to the whole UTC day',
    user          VARCHAR COMMENT 'Directory login, same as the Trino user name (context.user)',
    team          VARCHAR COMMENT 'Team the user belongs to on snapshot_date, one team per user and day'
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['snapshot_date'] -- one partition per daily export
);
