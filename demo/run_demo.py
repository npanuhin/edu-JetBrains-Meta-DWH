"""
Local demo test runner.

Usage:
    python demo/run_demo.py
"""

from pathlib import Path
import sqlite3

DEMO_DIR = Path(__file__).resolve().parent


def main():
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    print("1. Creating tables...")
    cur.executescript((DEMO_DIR / "ddl.sql").read_text(encoding="utf-8"))

    print("2. Seeding data...")
    cur.executescript((DEMO_DIR / "seed.sql").read_text(encoding="utf-8"))

    print("3. Running transformations...")
    cur.executescript((DEMO_DIR / "transformations.sql").read_text(encoding="utf-8"))

    print("\n--- Question 1: Distinct users for table X ---")
    q1_sql = (DEMO_DIR / "q1_distinct_users_per_table.sql").read_text(encoding="utf-8")
    cur.execute(q1_sql)
    res1 = cur.fetchone()
    assert res1 is not None, "Q1 returned no results"
    print(f"Table:          {res1['table_name']}")
    print(f"Distinct Users: {res1['distinct_users_count']}")
    print(f"Total Queries:  {res1['total_queries_count']}")

    assert res1["table_name"] == "iceberg.product_analytics.events_log"
    assert res1["distinct_users_count"] == 3
    assert res1["total_queries_count"] == 5
    print("Question 1 passed.")

    print("\n--- Question 2: Resource consumption for team Y ---")
    q2_sql = (DEMO_DIR / "q2_team_resource_consumption.sql").read_text(encoding="utf-8")
    cur.execute(q2_sql)
    res2 = cur.fetchone()
    assert res2 is not None, "Q2 returned no results"
    print(f"Team:           {res2['team_id']}")
    print(f"Queries:        {res2['total_queries']}")
    print(f"CPU Hours:      {res2['total_cpu_hours']} hrs")
    print(f"Max RAM:        {res2['max_peak_memory_mb']} MB")
    print(f"Data Scan:      {res2['total_scanned_gb']} GB")
    print(f"Cost:           ${res2['total_cost_usd']}")

    assert res2["team_id"] == "product-analytics"
    assert res2["total_queries"] == 4
    assert res2["total_cpu_hours"] == 0.0226
    assert res2["max_peak_memory_mb"] == 1024.0
    assert res2["total_scanned_gb"] == 2.588
    assert res2["total_cost_usd"] == 0.0135
    print("Question 2 passed.")

    print("\nAll tests passed.")


if __name__ == "__main__":
    main()
