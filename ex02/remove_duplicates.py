#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX02 – remove_duplicates.py
Module 1 – Data Warehouse – Piscine Data Science

Subject:
  Delete the duplicate rows in the "customers" table.
  Also remove rows that are the same instruction sent twice with a
  1 second interval (see subject example with remove_from_cart).

What this script does:
  1) Reads DB credentials from Module 0 ex00/.env when possible
  2) Prints COUNT(*) before the cleanup
  3) Runs one SQL DELETE using a window function (LAG):
       - same user_id, user_session, event_type, product_id, price
       - previous event_time within 0..1 second → delete the later row
  4) Prints COUNT(*) after the cleanup

Analogy:
  The server sometimes "stutters" and records the same customer action
  twice almost at the same moment. We keep the first note and throw away
  the echo that arrives within one second.

Usage:
  python3 remove_duplicates.py
  ./remove_duplicates.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path


def ensure_dependencies() -> None:
    """Install psycopg2 / dotenv for the current user if missing (no sudo)."""
    import importlib.util
    import subprocess

    needed = {
        "psycopg2": "psycopg2-binary",
        "dotenv": "python-dotenv",
    }
    missing = [
        pkg
        for mod, pkg in needed.items()
        if importlib.util.find_spec(mod) is None
    ]
    if missing:
        print(f"Installing: {', '.join(missing)} ...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--user", *missing]
        )


ensure_dependencies()

import psycopg2
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Paths: this file lives in .../data_science_1_data_warehouse/ex02/
# Module 0 is usually a sibling: .../data_science_0_creation_db/
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
MODULE1_DIR = SCRIPT_DIR.parent

def find_env_file() -> Path | None:
    """Locate Module 0 ex00/.env without hardcoding one campus path."""
    candidates = [
        MODULE1_DIR.parent / "data_science_0_creation_db" / "ex00" / ".env",
        MODULE1_DIR / ".." / "data_science_0_creation_db" / "ex00" / ".env",
        Path.home()
        / "sgoinfre"
        / "42_outer_core"
        / "piscine_pedago_data_science"
        / "data_science_0_creation_db"
        / "ex00"
        / ".env",
        Path.home()
        / "sgoinfre"
        / "students"
        / (os.environ.get("USER") or "")
        / "42_outer_core"
        / "piscine_pedago_data_science"
        / "data_science_0_creation_db"
        / "ex00"
        / ".env",
    ]
    for path in candidates:
        path = path.resolve()
        if path.is_file():
            return path
    return None


ENV_PATH = find_env_file()
if ENV_PATH is not None:
    load_dotenv(ENV_PATH)

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}

# Same DELETE as remove_duplicates.sql (keep SQL logic in one place conceptually)
DELETE_SQL = """
DELETE FROM customers AS c
USING (
    SELECT s.ctid AS rid
    FROM (
        SELECT
            ctid,
            event_time,
            LAG(event_time) OVER (
                PARTITION BY
                    user_id,
                    user_session,
                    event_type,
                    product_id,
                    price
                ORDER BY
                    event_time,
                    ctid
            ) AS prev_time
        FROM customers
    ) AS s
    WHERE s.prev_time IS NOT NULL
      AND s.event_time - s.prev_time <= INTERVAL '1 second'
) AS d
WHERE c.ctid = d.rid;
"""


def get_connection():
    """Open a connection to PostgreSQL (Docker publishes 5432 on localhost)."""
    return psycopg2.connect(**DB_CONFIG)


def count_customers(cur) -> int:
    cur.execute("SELECT COUNT(*) FROM customers;")
    row = cur.fetchone()
    return int(row[0]) if row else 0


def main() -> None:
    print("EX02 – remove_duplicates")
    print("Table: customers")
    print("Rule: same instruction + time gap ≤ 1 second → keep one row")
    if ENV_PATH:
        print(f".env: {ENV_PATH}")
    else:
        print(".env: not found (using defaults / environment)")
    print()

    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                before = count_customers(cur)
                print(f"COUNT(*) before: {before}")

                print("Running DELETE (window LAG, partition by business keys)...")
                print("This can take several minutes on ~20M rows. Please wait.")
                cur.execute(DELETE_SQL)
                deleted = cur.rowcount if cur.rowcount is not None and cur.rowcount >= 0 else None

                after = count_customers(cur)
                conn.commit()

                print(f"COUNT(*) after:  {after}")
                if deleted is not None:
                    print(f"Rows deleted (driver report): {deleted}")
                else:
                    print(f"Rows removed (before - after): {before - after}")
                print()
                print("Done.")
    except psycopg2.Error as exc:
        print("PostgreSQL error:", exc, file=sys.stderr)
        print("Check: docker ps, .env, table customers exists (EX01).", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
