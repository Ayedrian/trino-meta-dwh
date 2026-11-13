-- =============================================================================
-- One row per Trino QueryCompletedEvent, we keep only the fields that the Meta
-- DWH currently needs. This is an "upstream" table which the Meta DWH only reads
-- from, it's not part of the Meta DWH model. The "real" table would be written
-- to by something like Trino's Kafka event listener and have more fields, this table
-- is just here for the demo.
--
-- Only completed events are read, as they contain the final state of the query
-- + stats + tables read
-- I've deliberately left out: SQL text, write stats, context.groups,
-- cluster/environment
--
-- The inputs array lists the base tables that a query read, so we don't have to
-- expand views, that's done by Trino
--
-- Each column's comment has the name of the QueryCompletedEvent field that it comes from
-- =============================================================================

-- "if not exists" so that demo can be re-run
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.trino_query_completed (
    query_id               VARCHAR                     COMMENT 'metadata.queryId',
    query_state            VARCHAR                     COMMENT 'metadata.queryState, FINISHED or FAILED',
    user                   VARCHAR                     COMMENT 'context.user',
    end_time               timestamp(6) with time zone COMMENT 'endTime',
    cpu_time_ms            BIGINT                      COMMENT 'statistics.cpuTime in milliseconds',
    physical_input_bytes   BIGINT                      COMMENT 'statistics.physicalInputBytes',
    peak_user_memory_bytes BIGINT                      COMMENT 'statistics.peakUserMemoryBytes',
    inputs ARRAY(ROW(
        catalog_name         VARCHAR,
        schema_name          VARCHAR,
        table_name           VARCHAR,
        physical_input_bytes BIGINT
    )) COMMENT 'ioMetadata.inputs, fields from catalogName, schema, table and physicalInputBytes'
)
WITH (
    format = 'PARQUET',
    partitioning = ARRAY['day(end_time)'] -- partition by UTC days
);
