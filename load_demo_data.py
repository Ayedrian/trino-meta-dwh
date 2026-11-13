# Inserts the demo events and HR snapshots into the raw tables

from pathlib import Path

from setup_db import connect, run_sql_file

DEMO_DIR = Path(__file__).parent / "demo"
SEED_FILES = ["seed_events.sql", "seed_hr_snapshots.sql"]


def main():
    cursor = connect().cursor()
    for name in SEED_FILES:
        print(f"Running demo/{name}")
        run_sql_file(cursor, DEMO_DIR / name)


if __name__ == "__main__":
    main()
