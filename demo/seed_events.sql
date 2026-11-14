-- =============================================================================
-- A few randomly generated query events for the demo, spread out over a few days.
-- On 2026-11-10 to 12 all queries have finished, there are no duplicates.
-- 2026-11-13 holds the edge cases, one event per case. The mentioned table names
-- don't exist in the demo but the model only reads the table names so that's fine
--
--
-- The raw table is first emptied, so that loading this file again doesn't duplicate
-- the events
--
-- Edge cases on 2026-11-13:
--   00011  alice reads orders, the event arrived twice (exact copies)
--   00012  bob's query FAILED after reading customers, a table he never read before
--   00013  dan's self-join scans page_views twice (52418306 + 38904117 bytes)
--          and sessions once
--   00014  svc_reporting's nightly job ends at 2026-11-14 00:30:00 +01:00,
--          which is 2026-11-13 23:30:00 UTC
--   00015  dan's BI tool asks for metadata, reading only system.runtime.queries
--          and iceberg.information_schema.columns, so the query has no bridge rows
--          but its 87 ms of CPU count for dan's team
--   00016  alice reads orders and its Iceberg metadata table orders$snapshots
--   Metadata inputs count as 0 bytes, the value doesn't matter since they're dropped
--
-- Expected answers:
--
-- Raw events, fact_query rows and bridge rows per UTC day:
--               events  facts  bridge
--   2026-11-10  4       4      6
--   2026-11-11  3       3      5
--   2026-11-12  3       3      4
--   2026-11-13  7       6      6
--
-- Distinct users per table          2026-11-10 to 12   2026-11-10 to 11   2026-11-10 to 13   2026-11-13
--   iceberg.analytics.page_views    4                  3                  4                  1
--   iceberg.analytics.sessions      3                  2                  4                  1
--   iceberg.sales.orders            4                  3                  4                  2
--   iceberg.sales.customers         2                  2                  3                  1
--
-- Bridge row of 00013 for page_views: physical_input_bytes 91322423
-- Bridge rows of 00016: orders only, with physical_input_bytes 28563190
-- No bridge row has catalog system, schema information_schema or a $ in its table name
--
-- Totals, counting the duplicate once  2026-11-10 to 12   2026-11-10 to 13
--   cpu_time_ms                        18022              27643
--   physical_input_bytes               683671918          979925954
--
-- Counting the duplicate twice would give 28061 and 1011133508 over 2026-11-10 to 13
-- =============================================================================

DELETE FROM raw.trino_query_completed;

INSERT INTO raw.trino_query_completed
    (query_id, query_state, user, end_time, cpu_time_ms, physical_input_bytes, peak_user_memory_bytes, inputs)
VALUES
    -- 2026-11-10
    ('20261110_081540_00001_x7k2p', 'FINISHED', 'alice', TIMESTAMP '2026-11-10 08:15:42 UTC', 612, 69629981, 27331196, ARRAY[
        ROW('iceberg', 'analytics', 'page_views', 69629981)]),
    ('20261110_100211_00002_x7k2p', 'FINISHED', 'bob', TIMESTAMP '2026-11-10 10:02:19 UTC', 3577, 120629751, 99462329, ARRAY[
        ROW('iceberg', 'analytics', 'page_views', 9305560),
        ROW('iceberg', 'analytics', 'sessions', 111324191)]),
    ('20261110_143648_00003_x7k2p', 'FINISHED', 'alice', TIMESTAMP '2026-11-10 14:37:05 UTC', 260, 29138771, 10287343, ARRAY[
        ROW('iceberg', 'sales', 'orders', 4814725),
        ROW('iceberg', 'sales', 'customers', 24324046)]),
    ('20261110_232947_00004_x7k2p', 'FINISHED', 'svc_reporting', TIMESTAMP '2026-11-10 23:30:00 UTC', 322, 36412131, 12350498, ARRAY[
        ROW('iceberg', 'sales', 'orders', 36412131)]),
    -- 2026-11-11
    ('20261111_090529_00005_x7k2p', 'FINISHED', 'bob', TIMESTAMP '2026-11-11 09:05:31 UTC', 1863, 73241515, 25950086, ARRAY[
        ROW('iceberg', 'analytics', 'page_views', 73241515)]),
    ('20261111_114722_00006_x7k2p', 'FINISHED', 'dan', TIMESTAMP '2026-11-11 11:48:56 UTC', 7308, 216314383, 148975191, ARRAY[
        ROW('iceberg', 'sales', 'orders', 54633363),
        ROW('iceberg', 'sales', 'customers', 158417793),
        ROW('iceberg', 'analytics', 'page_views', 3263227)]),
    ('20261111_162007_00007_x7k2p', 'FINISHED', 'alice', TIMESTAMP '2026-11-11 16:20:08 UTC', 212, 16388004, 14258368, ARRAY[
        ROW('iceberg', 'analytics', 'sessions', 16388004)]),
    -- 2026-11-12
    ('20261112_094115_00008_x7k2p', 'FINISHED', 'svc_reporting', TIMESTAMP '2026-11-12 09:41:27 UTC', 233, 21052676, 16699952, ARRAY[
        ROW('iceberg', 'analytics', 'page_views', 16100840),
        ROW('iceberg', 'analytics', 'sessions', 4951836)]),
    ('20261112_131246_00009_x7k2p', 'FINISHED', 'bob', TIMESTAMP '2026-11-12 13:12:50 UTC', 1981, 58590157, 41646601, ARRAY[
        ROW('iceberg', 'sales', 'orders', 58590157)]),
    ('20261112_175502_00010_x7k2p', 'FINISHED', 'dan', TIMESTAMP '2026-11-12 17:55:03 UTC', 1654, 42274549, 19656568, ARRAY[
        ROW('iceberg', 'sales', 'customers', 42274549)]),
    -- 2026-11-13, edge cases
    ('20261113_084209_00011_x7k2p', 'FINISHED', 'alice', TIMESTAMP '2026-11-13 08:42:17 UTC', 418, 31207554, 11840227, ARRAY[
        ROW('iceberg', 'sales', 'orders', 31207554)]),
    ('20261113_084209_00011_x7k2p', 'FINISHED', 'alice', TIMESTAMP '2026-11-13 08:42:17 UTC', 418, 31207554, 11840227, ARRAY[
        ROW('iceberg', 'sales', 'orders', 31207554)]),
    ('20261113_110152_00012_x7k2p', 'FAILED', 'bob', TIMESTAMP '2026-11-13 11:03:48 UTC', 2954, 87316402, 64120931, ARRAY[
        ROW('iceberg', 'sales', 'customers', 87316402)]),
    ('20261113_152633_00013_x7k2p', 'FINISHED', 'dan', TIMESTAMP '2026-11-13 15:27:36 UTC', 5126, 112056408, 87245119, ARRAY[
        ROW('iceberg', 'analytics', 'page_views', 52418306),
        ROW('iceberg', 'analytics', 'page_views', 38904117),
        ROW('iceberg', 'analytics', 'sessions', 20733985)]),
    ('20261113_232948_00014_x7k2p', 'FINISHED', 'svc_reporting', TIMESTAMP '2026-11-14 00:30:00 +01:00', 305, 37110482, 12614373, ARRAY[
        ROW('iceberg', 'sales', 'orders', 37110482)]),
    ('20261113_091403_00015_x7k2p', 'FINISHED', 'dan', TIMESTAMP '2026-11-13 09:14:05 UTC', 87, 0, 2118436, ARRAY[
        ROW('system', 'runtime', 'queries', 0),
        ROW('iceberg', 'information_schema', 'columns', 0)]),
    ('20261113_134958_00016_x7k2p', 'FINISHED', 'alice', TIMESTAMP '2026-11-13 13:50:22 UTC', 731, 28563190, 19402875, ARRAY[
        ROW('iceberg', 'sales', 'orders', 28563190),
        ROW('iceberg', 'sales', 'orders$snapshots', 0)])
