#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX01 – customers table (Piscine Data Science – Module 1 – Data Warehouse)

Subject:
  Join all data_202*_*** tables together in a table called "customers".
  Turn-in: customers_table.*

Meaning of "join together":
  The monthly tables share the same schema. We STACK them with UNION ALL
  into one table named exactly "customers".
  We do NOT remove duplicates here (that is EX02).

This script:
  1) Reads credentials from Module 0 ex00/.env when possible
  2) Discovers every public table whose name matches data_202%
  3) DROP TABLE IF EXISTS customers
  4) CREATE TABLE customers AS (SELECT * FROM t1 UNION ALL SELECT * FROM t2 ...)
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Optional deps (same idea as Module 0 EX03)
# ---------------------------------------------------------------------------
def ensure_dependencies() -> None:
    import importlib.util
    import subprocess

    needed = {"psycopg2": "psycopg2-binary", "dotenv": "python-dotenv"}
    missing = [
        pkg for mod, pkg in needed.items() if importlib.util.find_spec(mod) is None
    ]
    if missing:
        print(f"Instalando: {', '.join(missing)} ...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--user", *missing]
        )


ensure_dependencies()

import psycopg2
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
MODULE1_DIR = SCRIPT_DIR.parent

# Locate Module 0 .env (sibling monorepo or common campus paths)
def find_env() -> Path | None:
    candidates = [
        MODULE1_DIR / ".." / "data_science_0_creation_db" / "ex00" / ".env",
        MODULE1_DIR.parent / "data_science_0_creation_db" / "ex00" / ".env",
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
    for p in candidates:
        p = p.resolve()
        if p.is_file():
            return p
    return None


env_path = find_env()
if env_path:
    load_dotenv(env_path)
    print(f"→ .env: {env_path}")
else:
    print("→ .env no encontrado; uso variables de entorno / valores por defecto")

DB = {
    "host": os.environ.get("POSTGRES_HOST", "localhost"),
    "port": int(os.environ.get("POSTGRES_PORT", "5432")),
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}


def main() -> None:
    print("→ Conectando a PostgreSQL…")
    conn = psycopg2.connect(**DB)
    conn.autocommit = True
    cur = conn.cursor()

    # Discover tables: subject pattern data_202*_***
    cur.execute(
        """
        SELECT tablename
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'public'
          AND tablename LIKE 'data_202%%'
        ORDER BY tablename;
        """
    )
    tables = [row[0] for row in cur.fetchall()]

    if not tables:
        print("ERROR: no hay tablas public.data_202* — carga Module 0 (EX03) antes.")
        sys.exit(1)

    print(f"→ Tablas encontradas ({len(tables)}): {', '.join(tables)}")

    # UNION ALL keeps every row (subject: join all together; EX02 removes dups later)
    parts = [f"SELECT * FROM {name}" for name in tables]
    union_sql = "\nUNION ALL\n".join(parts)

    print("→ DROP TABLE IF EXISTS customers")
    cur.execute("DROP TABLE IF EXISTS customers;")

    create_sql = f"CREATE TABLE customers AS\n{union_sql};"
    print("→ CREATE TABLE customers AS … UNION ALL …")
    cur.execute(create_sql)

    cur.execute("SELECT COUNT(*) FROM customers;")
    total = cur.fetchone()[0]
    print(f"✓ Tabla customers creada — {total} filas")

    cur.close()
    conn.close()
    print("✓ Proceso terminado.")


if __name__ == "__main__":
    main()
