A small data model to turn Trino query events into historical usage statistics about Iceberg tables. Right now it answers how many distinct users queried a table and how many resources a team consumed during a period, based on a few generated demo events and HR snapshots. We model that user -> team information comes from a daily HR export. A user's past queries are attributed to the team they were on at the time.

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

Populate the model tables for the 10th to the 12th of November. Each day is replaced, so running it again doesn't add anything new.

```sh
.venv/bin/python run_pipeline.py --start 2026-11-10 --end 2026-11-12
```

To ask how many distinct users queried `iceberg.analytics.page_views` (expected: 4) and how much CPU and bytes the team `product-analytics` used (expected: 14402 ms and 452460198 bytes), both from the 10th to the 12th of November:

```sh
docker compose exec -T trino trino --catalog iceberg --output-format ALIGNED < queries/examples.sql
```

To ask about another table, team or period, change the values in `queries/examples.sql`. Users who aren't in the HR export count as the team `unknown`. You can also connect any SQL client with a Trino driver to `localhost:8080` (any user name, catalog `iceberg`).

Use `docker compose down` to stop the container and also delete all data.

## Orchestration

The tables are created and loaded by plain Trino SQL files, a small runner written in Python runs them in order through the official `trino` client. In prod, an Airflow DAG would probably take over: One run a day, retries and backfills over date ranges. dbt (`dbt-trino` adapter) would replace my script with dbt models etc.