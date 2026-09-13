#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX01 – tabla customers (Piscine Data Science – Módulo 1 – Data Warehouse)

Objetivo del subject:
    Unir todas las tablas data_202*_*** en una tabla llamada "customers".
    Entrega: customers_table.*

Qué significa "unir":
    Las tablas mensuales comparten la misma estructura. Las APILAMOS con UNION ALL
    en una única tabla llamada exactamente "customers".
    Aquí NO eliminamos duplicados; eso corresponde a EX02.

Este script:
    1) Lee las credenciales de Module 0 ex00/.env cuando es posible.
    2) Descubre todas las tablas públicas cuyo nombre coincide con data_202%.
    3) Ejecuta DROP TABLE IF EXISTS customers.
    4) Crea customers con SELECT * y UNION ALL sobre todas las tablas encontradas.
"""

from __future__ import annotations

import os                   # Para leer variables de entorno y construir rutas de archivos.
import sys                  # Para sys.exit() y sys.stdout.isatty().
# sys.exit() se usa para abortar el script con un código de error si no hay tablas de origen.
# sys.stdout.isatty() se usa para decidir si mostrar un spinner animado o no.
import threading            # Para ejecutar el spinner en un hilo separado.
import time                 # Para time.sleep() en el spinner.
from pathlib import Path
# from es un atajo para en este caso importar solo Path de pathlib, en lugar de importar todo el módulo.
# pathlib se usa para que el script funcione tanto en Linux como en macOS y Windows sin depender 
# de separadores de ruta específicos del sistema operativo.
# Path se usa para localizar el .env de Module 0 y construir rutas de archivos de forma portátil.
from contextlib import contextmanager
# from contextlib import contextmanager se usa para importar solo contextmanager de contextlib, 
# en lugar de importar todo el módulo.
# contextmanager se usa para crear un "contexto" que permite mostrar un spinner animado mientras 
# se ejecuta un bloque de código.

# ---------------------------------------------------------------------------
# Dependencias opcionales (misma idea que en Module 0 EX03)
# ---------------------------------------------------------------------------
def ensure_dependencies() -> None:
    # Se comprueban los módulos antes de importarlos para dar un error útil
    # y permitir que el script prepare su propio entorno cuando sea necesario.
    import importlib.util   # Para comprobar si un módulo está instalado sin importarlo.
    import subprocess       # Para ejecutar pip install desde el script.

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

import psycopg2                 # Para conectarse a PostgreSQL y ejecutar consultas SQL.
from dotenv import load_dotenv
# load_dotenv se usa para cargar las variables de entorno desde un archivo .env en el entorno del script.

SCRIPT_DIR = Path(__file__).resolve().parent
MODULE1_DIR = SCRIPT_DIR.parent

RED = "\033[31m"
GREEN = "\033[32m"
CYAN = "\033[36m"
YELLOW = "\033[33m"
RESET = "\033[0m"


@contextmanager
def spinner(message: str):
    """Show a small red spinner only when stdout is an interactive terminal."""
    if not sys.stdout.isatty():
        yield
        return

    frames = ("\\", "-", "/")
    running = True

    def animate() -> None:
        frame = 0
        while running:
            print(f"\r{RED}{frames[frame % len(frames)]}{RESET} {message}", end="", flush=True)
            frame += 1
            time.sleep(0.12)

    thread = threading.Thread(target=animate, daemon=True)
    thread.start()
    try:
        yield
    finally:
        running = False
        thread.join()
        print(f"\r{' ' * (len(message) + 4)}\r", end="", flush=True)


def show_customers(cur, limit: int = 5) -> None:
    cur.execute(
        "SELECT * FROM customers LIMIT %s;",
        (limit,),
    )
    rows = cur.fetchall()
    columns = [description[0] for description in cur.description]

    print(f"\n{CYAN}👀 Vista previa de customers ({len(rows)} primeras filas){RESET}")
    if not rows:
        print(f"{YELLOW}(tabla vacía){RESET}")
        return

    widths = [len(column) for column in columns]
    for row in rows:
        for index, value in enumerate(row):
            widths[index] = max(widths[index], len(str(value)))
    header = " | ".join(column.ljust(widths[index]) for index, column in enumerate(columns))
    divider = "-+-".join("-" * width for width in widths)
    print(header)
    print(divider)
    for row in rows:
        print(" | ".join(str(value).ljust(widths[index]) for index, value in enumerate(row)))

# Localizar el .env de Module 0 (monorepo hermano o rutas habituales del campus).
def find_env() -> Path | None:
    # Se prueban varias ubicaciones para que el script funcione tanto dentro
    # del monorepo como con la estructura habitual del campus.
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
    # Estos valores coinciden con el contenedor PostgreSQL preparado en Module 0.
    # Las variables de entorno permiten cambiar la configuración sin editar código.
    "host": os.environ.get("POSTGRES_HOST", "localhost"),
    "port": int(os.environ.get("POSTGRES_PORT", "5432")),
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}


def main() -> None:
    print(f"{CYAN}🔌 Conectando a PostgreSQL…{RESET}")
    with spinner("Conectando"):
        conn = psycopg2.connect(**DB)
    conn.autocommit = True
    cur = conn.cursor()

    # Descubrir tablas según el patrón del subject: data_202*_***.
    # El patrón data_202% incluye automáticamente data_2023_feb si ya se cargó.
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
        print(f"{RED}✗ ERROR: no hay tablas public.data_202* — carga Module 0 (EX03) antes.{RESET}")
        sys.exit(1)

    print(f"{CYAN}📚 Tablas encontradas ({len(tables)}): {', '.join(tables)}{RESET}")

    # UNION ALL conserva todas las filas; EX02 eliminará los duplicados después.
    # Se generan las consultas a partir de los nombres encontrados, sin fijar
    # manualmente el número de meses.
    parts = [f"SELECT * FROM {name}" for name in tables]
    union_sql = "\nUNION ALL\n".join(parts)

    print(f"{YELLOW}🧹 DROP TABLE IF EXISTS customers{RESET}")
    with spinner("Eliminando customers anterior"):
        cur.execute("DROP TABLE IF EXISTS customers;")

    # La tabla final se reconstruye desde cero para reflejar todas las tablas
    # de origen disponibles en la base de datos en este momento.
    create_sql = f"CREATE TABLE customers AS\n{union_sql};"
    print(f"{YELLOW}🏗️  CREATE TABLE customers AS … UNION ALL …{RESET}")
    with spinner("Construyendo customers"):
        cur.execute(create_sql)

    cur.execute("SELECT COUNT(*) FROM customers;")
    total = cur.fetchone()[0]
    print(f"{GREEN}✓ Tabla customers creada — {total} filas{RESET}")

    print(f"\n{GREEN}✅ Proceso terminado. customers está lista para EX02.{RESET}")
    show_customers(cur)
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
