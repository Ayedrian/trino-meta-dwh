-- =============================================================================
-- A few generated daily HR exports for the demo, one for each day that has
-- events in seed_events.sql. svc_reporting is a service account that's missing
-- from the export, its usage ends up under "unknown". erin and frank have no
-- events (as in they never queried tables), they are added here to
-- check how team changes turn into membership rows.
--
-- The snapshot table is first emptied, so that loading this file again doesn't
-- duplicate the rows
--
-- Expected answers:
--
-- Team per user and day ("-" means not in the export)
--                  2026-11-10          2026-11-11          2026-11-12
--   alice          data-platform       data-platform       data-platform
--   bob            product-analytics   product-analytics   data-platform
--   dan            product-analytics   product-analytics   product-analytics
--   erin           data-platform       product-analytics   data-platform
--   frank          product-analytics   -                   product-analytics
--   svc_reporting  -                   -                   -
--
-- Rows per snapshot day: 5, 4, 5
--
-- Rows of meta.user_team_membership (valid_to is the first day the row no longer applies)
--   user   team               valid_from  valid_to
--   alice  data-platform      2026-11-10  9999-12-31
--   bob    product-analytics  2026-11-10  2026-11-12
--   bob    data-platform      2026-11-12  9999-12-31
--   dan    product-analytics  2026-11-10  9999-12-31
--   erin   data-platform      2026-11-10  2026-11-11
--   erin   product-analytics  2026-11-11  2026-11-12
--   erin   data-platform      2026-11-12  9999-12-31
--   frank  product-analytics  2026-11-10  2026-11-11
--   frank  product-analytics  2026-11-12  9999-12-31
--
-- CPU and bytes per team, from the events in seed_events.sql
--                      2026-11-10 to 12          2026-11-10 to 11
--                      cpu_time_ms  bytes        cpu_time_ms  bytes
--   product-analytics  14402        452460198    12748        410185649
--   data-platform      3065         173746913    1084         115156756
--   unknown            555          57464807     322          36412131
--   total              18022        683671918    14154        561754536
--
-- bob's CPU is 3577 + 1863 for product-analytics and 1981 for data-platform,
-- the period 2026-11-10 to 11 ends before his switch
-- =============================================================================

DELETE FROM raw.hr_user_team_snapshot;

INSERT INTO raw.hr_user_team_snapshot (snapshot_date, user, team)
VALUES
    -- 2026-11-10
    (DATE '2026-11-10', 'alice', 'data-platform'),
    (DATE '2026-11-10', 'bob',   'product-analytics'),
    (DATE '2026-11-10', 'dan',   'product-analytics'),
    (DATE '2026-11-10', 'erin',  'data-platform'),
    (DATE '2026-11-10', 'frank', 'product-analytics'),
    -- 2026-11-11
    (DATE '2026-11-11', 'alice', 'data-platform'),
    (DATE '2026-11-11', 'bob',   'product-analytics'),
    (DATE '2026-11-11', 'dan',   'product-analytics'),
    (DATE '2026-11-11', 'erin',  'product-analytics'),
    -- 2026-11-12
    (DATE '2026-11-12', 'alice', 'data-platform'),
    (DATE '2026-11-12', 'bob',   'data-platform'),
    (DATE '2026-11-12', 'dan',   'product-analytics'),
    (DATE '2026-11-12', 'erin',  'data-platform'),
    (DATE '2026-11-12', 'frank', 'product-analytics')
