# Inserts the few demo events into the raw table

from pathlib import Path

from setup_db import connect, run_sql_file

SEED_FILE = Path(__file__).parent / "demo" / "seed_events.sql"


def main():
    print(f"Running {SEED_FILE.relative_to(SEED_FILE.parent.parent)}")
    run_sql_file(connect().cursor(), SEED_FILE)


if __name__ == "__main__":
    main()
