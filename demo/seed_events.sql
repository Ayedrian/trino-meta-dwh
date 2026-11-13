-- =============================================================================
-- A few randomly generated query events for the demo, spread out over a few days.
-- All queries have finished, there are no duplicates. The mentioned table names
-- don't exist in the demo but the model only reads the table names so that's fine
--
--
-- The raw table is first emptied, so that loading this file again doesn't duplicate
-- the events
--
-- Expected answers:
--
-- Events per UTC day:
--   2026-11-10  4
--   2026-11-11  3
--   2026-11-12  3
--
-- Distinct users per table          2026-11-10 to 12   2026-11-10 to 11
--   iceberg.analytics.page_views    4                  3
--   iceberg.analytics.sessions      3                  2
--   iceberg.sales.orders            4                  3
--   iceberg.sales.customers         2                  2
--
-- Totals
--   cpu_time_ms           18022
--   physical_input_bytes  683671918
--   inputs entries        15
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
    ('20261110_232947_00004_x7k2p', 'FINISHED', 'charlie', TIMESTAMP '2026-11-10 23:30:00 UTC', 322, 36412131, 12350498, ARRAY[
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
    ('20261112_094115_00008_x7k2p', 'FINISHED', 'charlie', TIMESTAMP '2026-11-12 09:41:27 UTC', 233, 21052676, 16699952, ARRAY[
        ROW('iceberg', 'analytics', 'page_views', 16100840),
        ROW('iceberg', 'analytics', 'sessions', 4951836)]),
    ('20261112_131246_00009_x7k2p', 'FINISHED', 'bob', TIMESTAMP '2026-11-12 13:12:50 UTC', 1981, 58590157, 41646601, ARRAY[
        ROW('iceberg', 'sales', 'orders', 58590157)]),
    ('20261112_175502_00010_x7k2p', 'FINISHED', 'dan', TIMESTAMP '2026-11-12 17:55:03 UTC', 1654, 42274549, 19656568, ARRAY[
        ROW('iceberg', 'sales', 'customers', 42274549)])
