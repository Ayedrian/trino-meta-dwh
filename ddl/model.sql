-- =============================================================================
-- The Meta Data Warehouse model: Comments describing meaning for every column
-- so that both people and AI agents can read and understand the model
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS meta;

CREATE TABLE IF NOT EXISTS meta.fact_query (
    query_id               VARCHAR                     COMMENT 'Trino query ID, unique per query',
    query_state            VARCHAR                     COMMENT 'Final state of the query, FINISHED or FAILED',
    user                   VARCHAR                     COMMENT 'The user that ran the query',
    end_time               timestamp(6) with time zone COMMENT 'The time when the query ended',
    query_date             DATE                        COMMENT 'UTC day of end_time, the partition and the unit of daily loads',
    cpu_time_ms            BIGINT                      COMMENT 'Additive CPU time for all tasks in ms',
    physical_input_bytes   BIGINT                      COMMENT 'Additive bytes read for all inputs',
    peak_user_memory_bytes BIGINT                      COMMENT 'Peak user memory in bytes (not additive, aggregate with max)'
)
COMMENT 'One row per query, includes failed queries'
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['query_date']
);

CREATE TABLE IF NOT EXISTS meta.fact_query_table_access (
    query_id             VARCHAR COMMENT 'Trino query ID, joins to fact_query',
    query_date           DATE    COMMENT 'UTC day at queries end_time',
    user                 VARCHAR COMMENT 'The user that ran the query (copied from the query)',
    catalog_name         VARCHAR COMMENT 'Catalog of the table that was read',
    schema_name          VARCHAR COMMENT 'Schema of the table that was read',
    table_name           VARCHAR COMMENT 'Name of the table that was read, views are expanded to their base tables',
    physical_input_bytes BIGINT  COMMENT 'Additive bytes read from this table by this query, summed up for every scan of the table'
)
COMMENT 'One row per query and table read'
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['query_date']
);

CREATE TABLE IF NOT EXISTS meta.user_team_membership (
    user       VARCHAR COMMENT 'The user, same as in fact_query',
    team       VARCHAR COMMENT 'Team the user was on from valid_from up to the day BEFORE valid_to',
    valid_from DATE    COMMENT 'First UTC day the user was on this team',
    valid_to   DATE    COMMENT 'First UTC day the user was no longer on this team, 9999-12-31 while still on it'
)
COMMENT 'One row per user and continuous period on one team (SCD Type 2), users without a team have no rows and count as unknown'
WITH (
    format = 'PARQUET'
);
