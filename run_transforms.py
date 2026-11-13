# Runs the transforms in order, soon to be be replaced by a pipeline (which will load them day by day)

from pathlib import Path

from setup_db import connect, run_sql_file

TRANSFORM_DIR = Path(__file__).parent / "transform"
TRANSFORMS = ["load_fact_query.sql", "load_fact_query_table_access.sql"]


def main():
    cursor = connect().cursor()
    for name in TRANSFORMS:
        print(f"Running transform/{name}")
        run_sql_file(cursor, TRANSFORM_DIR / name)


if __name__ == "__main__":
    main()
