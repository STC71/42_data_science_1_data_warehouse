#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX03 – fusion.py
Module 1 – Data Warehouse – Piscine Data Science

Qué pide el subject:
  Fusionar las tablas "customers" e "items" sin perder información.

Qué hace este script:
  1) Lee credenciales de Module 0 (ex00/.env) si las encuentra
  2) Comprueba que existen las tablas customers e items
  3) Muestra COUNT(*) de ambas antes de fusionar
  4) Crea customers enriquecida con LEFT JOIN a items (por product_id):
       - Se conservan TODOS los eventos de customers
       - category_id, category_code, brand vienen de items (o NULL)
  5) Sustituye la tabla customers por el resultado
  6) Muestra COUNT(*) después (debe ser igual al de customers antes)

Analogía:
  customers = lista de tickets de caja (qué se miró / compró / quitó del carrito).
  items     = catálogo de productos (categoría, marca…).
  Fusionar  = pegar en cada ticket la ficha del producto, sin tirar ningún ticket
              aunque el producto no esté en el catálogo.

Uso:
  python3 fusion.py
  ./fusion.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path


def ensure_dependencies() -> None:
    """Instala psycopg2 y python-dotenv para el usuario si faltan (sin sudo)."""
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
        print(f"Instalando: {', '.join(missing)} ...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--user", *missing]
        )


ensure_dependencies()

import psycopg2
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
MODULE1_DIR = SCRIPT_DIR.parent


def find_env_file() -> Path | None:
    """Localiza Module 0 ex00/.env sin hardcodear un único path de campus."""
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

# Misma lógica que fusion.sql
FUSION_SQL = """
DROP TABLE IF EXISTS customers_fused;

CREATE TABLE customers_fused AS
SELECT
    c.event_time,
    c.event_type,
    c.product_id,
    c.price,
    c.user_id,
    c.user_session,
    i.category_id,
    i.category_code,
    i.brand
FROM customers AS c
LEFT JOIN (
    SELECT DISTINCT ON (product_id)
        product_id,
        category_id,
        category_code,
        brand
    FROM items
    ORDER BY product_id
) AS i
  ON c.product_id = i.product_id;

DROP TABLE customers;
ALTER TABLE customers_fused RENAME TO customers;
"""


def get_connection():
    """Abre conexión a PostgreSQL (puerto 5432 en localhost vía Docker)."""
    return psycopg2.connect(**DB_CONFIG)


def table_exists(cur, name: str) -> bool:
    cur.execute(
        """
        SELECT 1
        FROM pg_tables
        WHERE schemaname = 'public' AND tablename = %s
        """,
        (name,),
    )
    return cur.fetchone() is not None


def count_rows(cur, table: str) -> int:
    cur.execute(f"SELECT COUNT(*) FROM {table};")
    row = cur.fetchone()
    return int(row[0]) if row else 0


def main() -> None:
    print("EX03 – fusion")
    print("Objetivo: customers LEFT JOIN items (por product_id), sin perder eventos")
    if ENV_PATH:
        print(f".env: {ENV_PATH}")
    else:
        print(".env: no encontrado (valores por defecto / entorno)")
    print()

    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                if not table_exists(cur, "customers"):
                    print("ERROR: no existe la tabla customers (haz EX01 y EX02 antes).", file=sys.stderr)
                    sys.exit(1)
                if not table_exists(cur, "items"):
                    print("ERROR: no existe la tabla items (Module 0 – EX04).", file=sys.stderr)
                    sys.exit(1)

                n_cust = count_rows(cur, "customers")
                n_items = count_rows(cur, "items")
                print(f"COUNT(*) customers (antes): {n_cust}")
                print(f"COUNT(*) items:             {n_items}")
                print()
                print("Fusionando (LEFT JOIN + DISTINCT ON product_id en items)...")
                print("Puede tardar varios minutos. Espera, por favor.")

                cur.execute(FUSION_SQL)
                conn.commit()

                n_after = count_rows(cur, "customers")
                print(f"COUNT(*) customers (después): {n_after}")

                if n_after != n_cust:
                    print(
                        "AVISO: el número de filas de customers cambió; "
                        "revisa si items tenía product_id duplicados no controlados.",
                        file=sys.stderr,
                    )
                else:
                    print("OK: mismo número de eventos que antes (no se perdió información).")

                cur.execute(
                    """
                    SELECT COUNT(*) FILTER (WHERE category_id IS NULL) AS sin_categoria,
                           COUNT(*) FILTER (WHERE category_id IS NOT NULL) AS con_categoria
                    FROM customers;
                    """
                )
                sin_cat, con_cat = cur.fetchone()
                print(f"Filas con datos de items:    {con_cat}")
                print(f"Filas sin match en items:    {sin_cat}")
                print()
                print("Proceso terminado.")
    except psycopg2.Error as exc:
        print("Error de PostgreSQL:", exc, file=sys.stderr)
        print(
            "Revisa: docker ps, .env, tablas customers e items.",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
