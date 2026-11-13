A small data model to turn Trino query events into historical usage statistics about Iceberg tables. Right now it can only answer how many distinct users queried a table during a period, based on a few generated demo events. Will add resources per team next.

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

Insert a few demo events into the raw table, running again replaces the values:

```sh
.venv/bin/python load_demo_data.py
```

Populate the model tables from the raw events, running again rebuilds them:

```sh
.venv/bin/python run_transforms.py
```

To ask how many distinct users queried `iceberg.analytics.page_views` from the 10th to the 12th of November (expected: 4):

```sh
docker compose exec -T trino trino --catalog iceberg --output-format ALIGNED < queries/examples.sql
```

To ask about another table or period, change the values in `queries/examples.sql`. You can also connect any SQL client with a Trino driver to `localhost:8080` (any user name, catalog `iceberg`).

Use `docker compose down` to stop the container and also delete all data.

## Orchestration

The tables are created and loaded by plain Trino SQL files, a small runner written in Python runs them in order through the official `trino` client. In prod, an Airflow DAG would probably take over: One run a day, retries and backfills over date ranges. dbt (`dbt-trino` adapter) would replace my script with dbt models etc.