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
