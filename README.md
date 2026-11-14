A small data model to turn Trino query events into historical usage statistics about Iceberg tables.

The example queries (how many distinct users queried a table, how many resources a team consumed etc.) from the test task can be run against a real Trino instance in a Docker container with Iceberg tables on the local disk instead of an S3 instance. The data is a few hand-written demo events and HR snapshots. The setup steps for that (requires Docker and Python 3.9 or newer) are below. Feel free to skip the setup if you're currently only interested in skimming the SQL and reading about my design choices and assumptions I've made throughout the task. That part starts at [Data model](#data-model).

**Contents:** [Running the demo](#running-the-demo) · [Data model](#data-model) · [Example queries](#example-queries) · [Users and teams](#users-and-teams) · [Queries over several tables and data sources](#queries-over-several-tables-and-data-sources) · [Resource metrics](#resource-metrics) · [How the data is updated](#how-the-data-is-updated) · [Additional metadata](#additional-metadata) · [Possible extensions](#possible-extensions)

## Running the demo

Requires Docker with Compose.

```sh
docker compose up -d --wait
```

Starts a single Trino container, its `iceberg` catalog uses a file-based metastore and keeps its data on the local disk inside the container. `--wait` returns once Trino is healthy, which can take a little while (30+ seconds).

Create the tables like so (needs Python 3.9 or newer):

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python setup_db.py
```

Insert a few demo events and daily HR user-to-team snapshots into the raw tables, running again replaces the values:

```sh
.venv/bin/python load_demo_data.py
```

Populate the model tables for the 10th to the 13th of November. The 13th holds edge cases (a duplicate event, a failed query etc.). Each day is replaced, so running it again doesn't add anything new, and duplicate events are counted once.

```sh
.venv/bin/python run_pipeline.py --start 2026-11-10 --end 2026-11-13
```

If no dates are specified, the pipeline simply loads the last 3 complete UTC days (the 3 days before today). That's what a daily scheduled run would do, so that events that arrive a day or two late are still picked up.
The demo events currently are on fixed dates in November 2026, when I worked on this repo, so a run without dates only finds them if those days are among the last 3.

To ask how many distinct users queried `iceberg.analytics.page_views` (expected: 4) and how much CPU and bytes the team `product-analytics` used (expected: 14402 ms and 452460198 bytes), both from the 10th to the 12th of November, and how the team's usage changes per week (expected: one row for the week starting 9 November, 6 queries by 2 users, 19615 ms):

```sh
docker compose exec -T trino trino --catalog iceberg --output-format ALIGNED < queries/examples.sql
```

To ask about another table, team or period, change the values in `queries/examples.sql`. Users who aren't in the HR export count as the team `unknown`. You can also connect any SQL client with a Trino driver to `localhost:8080` (any user name, catalog `iceberg`).

Use `docker compose down` to stop the container and also delete all data.

## Data model

Two raw tables are here to represent upstream data and are only read. One table contains the Trino query events and the other a daily HR export of every user's team. Our Meta DWH turns them into the tables below in a `meta` schema.

```
raw.trino_query_completed ──┬──► meta.fact_query ──────────────┐
                            └──► meta.fact_query_table_access ─┼──► meta.agg_*_usage_daily
raw.hr_user_team_snapshot ─────► meta.user_team_membership ────┘    (only designed, not built here)
```

| Table | One row per | Key | |
|---|---|---|---|
| `fact_query` | query, failed queries included | `query_id` | built |
| `fact_query_table_access` | query and data table read | `query_id`, table | built |
| `user_team_membership` | user and continuous period on one team (SCD Type 2) | `user`, `valid_from` | built |
| `agg_table_usage_daily` | table and day | table, `query_date` | only designed |
| `agg_team_usage_daily` | team and day | `team`, `query_date` | only designed |

A table is identified by `(catalog_name, schema_name, table_name)`, `query_date` is the UTC day on which the query ended.

**Relationships**
  - **`fact_query_table_access` → `fact_query`** on `query_id`: one bridge row per data table the query read. Nothing is added if the query read only metadata tables or no table at all.
  - **`fact_query` → `user_team_membership`** on `user` with `query_date >= valid_from AND query_date < valid_to`: each query belongs to the team its user was on that day, or to `unknown` if there's no match.
  
The facts store the finest grain, so that any period or grouping can still be answered later. There are no dimension tables at the moment, since I have no info such as table owners or team details. I chose to simply identify tables, users and teams by their name.

**Daily aggregates (only designed, not built yet).** They would keep the usage history in a small, fast form.
  - Per table and day: `query_count`, `failed_query_count`, `distinct_users`, `attributed_cpu_time_ms` and `physical_input_bytes`.
  - Per team and day: the same, with `cpu_time_ms` and `max_peak_user_memory_bytes` instead of attributed CPU.
  
`distinct_users` counts a single day and should not be summed (otherwise results would be off), so distinct users over a period would still need to come from the facts. The team is looked up when the team aggregate is loaded. A corrected mapping therefore means recomputing that aggregate for the affected days, not reloading facts.

**Raw tables**
  - `raw.trino_query_completed`: one row per Trino `QueryCompletedEvent`, partitioned by `day(end_time)`. It has only the fields our model needs: query ID, state, user, end time, CPU time, bytes read, peak memory, and the `inputs` array of tables read with their bytes. The real event has many more fields that we leave out on purpose, such as `context.groups`, the SQL text and the write statistics.
  - `raw.hr_user_team_snapshot`: one row per user and day, with `snapshot_date`, `user` and `team`.

We assume a single Trino cluster, so no table has a cluster column. The assumed DDL is in [`ddl/source/`](ddl/source/), with each event column commented with the field name in QueryCompletedEvent it comes from.

The model's DDL is in [`ddl/model.sql`](ddl/model.sql). We have one load per table in [`transform/`](transform/) and the runner is in [`run_pipeline.py`](run_pipeline.py).

## Example queries

Found in [`queries/examples.sql`](queries/examples.sql). Each query asks about one concrete table or team and period, first and last day are included.

- **Distinct users of table X:** `count(DISTINCT user)` on just the bridge, filtered by table and `query_date`. Distinct users cannot be summed over days (would overcount), so they're always counted over the exact period queried.
- **Resources of team Y:** the sum of `cpu_time_ms` and `physical_input_bytes` from `fact_query`, joined to `user_team_membership`
  on the user and the day. Each query counts fully for the team its user was on that day. Users without a team fall under `unknown`.
- **Weekly trend of team Y:** The same join, with queries, distinct users, CPU and bytes per week. Replace `'week'` with `'day'` or `'month'` for another grain.

## Users and teams

We assume HR, or the company directory (for example LDAP), exports every user's current team once a day, under the same user name that Trino reports as `context.user`. Every day's export is kept in `raw.hr_user_team_snapshot` and gives us the team for that whole UTC day.

On every run, `user_team_membership` is rebuilt from all snapshots ([`transform/load_user_team_membership.sql`](transform/load_user_team_membership.sql)). A user's consecutive days on one team turn into one row with a range `[valid_from, valid_to)`. The table is tiny, rebuilding it is cheap and safe to repeat, and correcting an old snapshot fixes the history.

A query counts for the team its user was on the day the query ended. In the demo, bob moves from `product-analytics` to `data-platform` on the 12th of November. His earlier queries stay attributed to `product-analytics`, the later ones count for `data-platform`.

Users who aren't in the export count as `unknown`, as do queries from before the first snapshot. The most likely cause is a service account that nobody mapped, like svc_reporting in the demo, so service accounts need to be in the export under the team that owns them.

The user is `context.user`, the identity a query runs as, so a real person rather than some tool acting for them. Teams don't come from `context.groups`: users belong to many groups, which would need their own mapping to teams and would be a second source of truth next to HR.

## Queries over several tables and data sources

## Resource metrics

## How the data is updated

The tables are created and loaded by plain Trino SQL files, a small runner written in Python runs them in order through the official `trino` client. In prod, an Airflow DAG would probably take over: One run a day (run_pipeline.py without specified dates), retries and backfills over date ranges (start/end). dbt (`dbt-trino` adapter) would replace my script with dbt models etc.

## Additional metadata

## Possible extensions