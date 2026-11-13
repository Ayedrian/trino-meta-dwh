A small data model to turn Trino query events into historical usage statistics about Iceberg tables. Right now there's only a runnable Trino + Iceberg environment, I will add the model next.

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

How to check that we can work with Iceberg tables:

```sh
docker compose exec -T trino trino --catalog iceberg --execute "
CREATE SCHEMA test;
CREATE TABLE test.t (id BIGINT, name VARCHAR);
INSERT INTO test.t VALUES (1, 'a'), (2, 'b');
SELECT * FROM test.t;
DROP TABLE test.t;
DROP SCHEMA test;"
```

Use `docker compose down` to stop the container and also delete all data.

## Orchestration

The tables are created and loaded by plain Trino SQL files, a small runner written in Python runs them in order through the official `trino` client. In prod, an Airflow DAG would probably take over: One run a day, retries and backfills over date ranges. dbt (`dbt-trino` adapter) would replace my script with dbt models etc.