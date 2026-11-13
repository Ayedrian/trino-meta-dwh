-- Rebuilds meta.user_team_membership from the HR snapshots
-- Emptied first, so that running again doesn't duplicate anything
--
-- Days that have an export are numbered 1, 2, 3, ... and a user's days on one
-- team end up as one row as long as their day numbers don't have a gap. A move from
-- team A to B and back to A generates three rows, and a user missing from an export
-- (for example when leaving) has their row closed, even if they appear on the team
-- again at a later point in time. A day without an export isn't numbered, thus doesn't
-- close anyone's row.
--
-- valid_to = date of the next export after the row's last day, or 9999-12-31
-- in the case that the row reaches the latest export

DELETE FROM meta.user_team_membership;

INSERT INTO meta.user_team_membership (user, team, valid_from, valid_to)
WITH snapshot_days AS (
    SELECT
        snapshot_date,
        row_number() OVER (ORDER BY snapshot_date) AS day_number,
        lead(snapshot_date, 1, DATE '9999-12-31') OVER (ORDER BY snapshot_date) AS next_snapshot_date
    FROM (SELECT DISTINCT snapshot_date FROM raw.hr_user_team_snapshot)
),
numbered AS (
    SELECT
        s.user,
        s.team,
        s.snapshot_date,
        d.next_snapshot_date,
        -- stays the same while the user's days on this team continue with no gap
        d.day_number - row_number() OVER (PARTITION BY s.user, s.team ORDER BY s.snapshot_date) AS run_id
    FROM raw.hr_user_team_snapshot AS s
    JOIN snapshot_days AS d ON d.snapshot_date = s.snapshot_date
)
SELECT
    user,
    team,
    min(snapshot_date),
    max(next_snapshot_date)
FROM numbered
GROUP BY user, team, run_id
