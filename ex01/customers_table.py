#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX01 – customers_table.py
Module 1 – Data Warehouse – Piscine Data Science

Qué pide el subject:
  Unir todas las tablas data_202*_*** en una tabla llamada exactamente "customers".
  Entrega: customers_table.*

Qué significa "unir" aquí:
  Las tablas mensuales (data_2022_oct, data_2022_nov, …) tienen las MISMAS columnas.
  No hacemos un JOIN por user_id entre meses: las APILAMOS una debajo de otra.
  En SQL eso es UNION ALL (conserva todas las filas, incluso repetidas).

  Analogía: varios cuadernos de caja del mismo formato (uno por mes).
  Pegamos todas las hojas en un solo archivador llamado "customers".
  Si dos hojas son idénticas, de momento las dejamos las dos (EX02 limpiará).

Qué hace este script, en orden:
  1) Instala psycopg2 / python-dotenv si faltan (pip --user, sin sudo).
  2) Busca el .env de Module 0 (ex00) para no hardcodear la contraseña.
  3) Conecta a PostgreSQL (Docker publica el puerto 5432 en localhost).
  4) Descubre en el catálogo del sistema todas las tablas public.data_202%.
  5) DROP TABLE IF EXISTS customers (para poder reejecutar el script).
  6) CREATE TABLE customers AS  SELECT * FROM t1 UNION ALL SELECT * FROM t2 …
  7) Muestra COUNT(*) y una vista previa de filas.

Uso:
  python3 customers_table.py
  ./customers_table.py
"""

from __future__ import annotations
# __future__.annotations permite escribir tipos como Path | None de forma clara
# (equivalente moderno a Optional[Path] en versiones antiguas de Python).

import os
# os: variables de entorno (POSTGRES_*, USER) y datos del sistema.
import sys
# sys: sys.exit(código) para abortar con error; sys.stdout.isatty() para saber
# si la salida es una terminal interactiva (y entonces mostrar el spinner).
import threading
# threading: el spinner gira en un hilo paralelo mientras PostgreSQL trabaja.
import time
# time.sleep: pausa breve entre fotogramas del spinner.
from pathlib import Path
# Path: rutas de archivos portables (Linux/macOS/Windows) sin liarnos con "/".
from contextlib import contextmanager
# contextmanager: permite escribir "with spinner(...):" de forma limpia.


# ---------------------------------------------------------------------------
# Dependencias (misma idea que Module 0 EX03 / EX03 fusion)
# ---------------------------------------------------------------------------
def ensure_dependencies() -> None:
    """
    Comprueba si se pueden importar psycopg2 y dotenv.
    Si faltan, las instala solo para el usuario actual (pip install --user),
    típico del campus 42 donde no hay sudo.
    """
    import importlib.util  # ¿Está instalado el módulo sin importarlo del todo?
    import subprocess      # Lanzar "python -m pip install ..."

    # Clave = nombre al importar; valor = nombre del paquete en PyPI
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
# psycopg2: "conductor" (driver) que permite a Python hablar con PostgreSQL.
from dotenv import load_dotenv
# load_dotenv: lee un archivo .env y exporta POSTGRES_USER, POSTGRES_PASSWORD, etc.


# ---------------------------------------------------------------------------
# Rutas del proyecto
# Este archivo está en: .../data_science_1_data_warehouse/ex01/
# Module 0 suele ser hermano: .../data_science_0_creation_db/
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent  # carpeta ex01/
MODULE1_DIR = SCRIPT_DIR.parent               # carpeta data_science_1_...

# Colores ANSI para la terminal (solo estética; no afectan a la lógica)
RED = "\033[31m"
GREEN = "\033[32m"
CYAN = "\033[36m"
YELLOW = "\033[33m"
RESET = "\033[0m"


@contextmanager
def spinner(message: str):
    """
    Muestra un spinner rojo (\\ - /) mientras se ejecuta el bloque "with".
    Solo si stdout es una terminal interactiva; si la salida va a un fichero
    o a un pipeline, no pinta nada (evita basura en logs).
    """
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
        yield  # aquí dentro se ejecuta el código del "with spinner(...)"
    finally:
        running = False
        thread.join()
        # Limpia la línea del spinner
        print(f"\r{' ' * (len(message) + 4)}\r", end="", flush=True)


def show_customers(cur, limit: int = 5) -> None:
    """
    Imprime una mini-tabla con las primeras filas de customers.
    Sirve para comprobar a ojo que la creación funcionó (columnas y datos).
    """
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

    # Ancho de cada columna = máximo entre cabecera y valores (para alinear)
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


def find_env() -> Path | None:
    """
    Busca el archivo .env de Module 0 (ex00) sin fijar la ruta de un solo login.
    Prueba rutas relativas al monorepo y rutas típicas de sgoinfre en el campus.
    Devuelve Path si existe, o None si no se encuentra.
    """
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


# ---------------------------------------------------------------------------
# Carga de credenciales y configuración de conexión
# ---------------------------------------------------------------------------
env_path = find_env()
if env_path:
    load_dotenv(env_path)
    print(f"→ .env: {env_path}")
else:
    print("→ .env no encontrado; uso variables de entorno / valores por defecto")

# Valores alineados con el contenedor de Module 0 (subject: piscineds / mysecretpassword)
DB = {
    "host": os.environ.get("POSTGRES_HOST", "localhost"),
    "port": int(os.environ.get("POSTGRES_PORT", "5432")),
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}


def main() -> None:
    """
    Punto de entrada:
      conectar → listar data_202* → DROP customers → CREATE … UNION ALL → COUNT
    """
    print(f"{CYAN}🔌 Conectando a PostgreSQL…{RESET}")
    with spinner("Conectando"):
        # **DB descompone el diccionario en host=..., port=..., etc.
        conn = psycopg2.connect(**DB)
    # autocommit=True: cada sentencia se confirma sola (no hace falta commit manual)
    conn.autocommit = True
    cur = conn.cursor()  # cursor = canal para enviar SQL y leer resultados

    # -----------------------------------------------------------------------
    # Descubrir tablas del patrón del subject: data_202*_***
    # pg_tables es el catálogo de PostgreSQL (metadatos: qué tablas existen).
    # LIKE 'data_202%' captura oct, nov, dec, jan, feb… sin hardcodear nombres.
    # (En el string de Python se escribe %% porque % se escapa en algunos contextos;
    #  aquí el literal enviado a PostgreSQL es data_202%.)
    # -----------------------------------------------------------------------
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
        print(
            f"{RED}✗ ERROR: no hay tablas public.data_202* — "
            f"carga Module 0 (EX03) antes.{RESET}"
        )
        sys.exit(1)

    print(f"{CYAN}📚 Tablas encontradas ({len(tables)}): {', '.join(tables)}{RESET}")

    # UNION ALL = apilar todas las filas de todos los meses.
    # No usamos UNION (sin ALL): ese quitaría duplicados exactos y eso es trabajo de EX02.
    parts = [f"SELECT * FROM {name}" for name in tables]
    union_sql = "\nUNION ALL\n".join(parts)

    print(f"{YELLOW}🧹 DROP TABLE IF EXISTS customers{RESET}")
    with spinner("Eliminando customers anterior"):
        cur.execute("DROP TABLE IF EXISTS customers;")

    # CREATE TABLE … AS SELECT materializa el resultado del UNION ALL
    # en una tabla nueva llamada exactamente "customers" (nombre del subject).
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
    # Solo ejecuta main() si lanzamos este archivo directamente
    # (python3 customers_table.py), no si otro módulo lo importa.
    main()
