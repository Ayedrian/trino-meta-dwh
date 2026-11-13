# Creates tables in the local Trino instance by running the relevant DDL files in order

from pathlib import Path

import trino

DDL_DIR = Path(__file__).parent / "ddl"


def connect():
    return trino.dbapi.connect(host="localhost", port=8080, user="meta_dwh", catalog="iceberg")


def run_sql_file(cursor, path):
    for statement in path.read_text().split(";"): # split SQL statements -> never put a ; inside a string or comment
        if statement.strip():
            cursor.execute(statement)
            cursor.fetchall() # polls until query actually finishes


def main():
    cursor = connect().cursor()
    for path in [*sorted((DDL_DIR / "source").glob("*.sql")), DDL_DIR / "model.sql"]:
        print(f"Running {path.relative_to(DDL_DIR.parent)}")
        run_sql_file(cursor, path)


if __name__ == "__main__":
    main()
