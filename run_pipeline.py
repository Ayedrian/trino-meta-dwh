# Fills the model tables for a specified range of UTC days: First rebuild the user-to-team history once,
# then replace each day of both the facts and the bridge, so that running again changes nothing

import argparse
from datetime import date, timedelta
from pathlib import Path

from setup_db import connect, run_sql, run_sql_file

TRANSFORM_DIR = Path(__file__).parent / "transform"
DAILY_TRANSFORMS = ["load_fact_query.sql", "load_fact_query_table_access.sql"]


def main():
    parser = argparse.ArgumentParser(description="Load the Meta DWH for a specified range of UTC days, both first and last day are inclusive")
    parser.add_argument("--start", type=date.fromisoformat, required=True, help="first day, YYYY-MM-DD")
    parser.add_argument("--end", type=date.fromisoformat, required=True, help="last day, YYYY-MM-DD")
    args = parser.parse_args()

    cursor = connect().cursor()
    print("Running transform/load_user_team_membership.sql")
    run_sql_file(cursor, TRANSFORM_DIR / "load_user_team_membership.sql")

    day = args.start
    while day <= args.end:
        for name in DAILY_TRANSFORMS:
            print(f"Running transform/{name} for {day}")
            run_sql(cursor, (TRANSFORM_DIR / name).read_text().replace("{day}", day.isoformat()))
        day += timedelta(days=1)


if __name__ == "__main__":
    main()
