#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EX02 – remove_duplicates.py
Module 1 – Data Warehouse – Piscine Data Science

Qué pide el subject:
  Borrar las filas duplicadas de la tabla "customers".
  También eliminar los casos en que el servidor registra la misma
  instrucción dos veces con un intervalo de 1 segundo
  (ejemplo del PDF: remove_from_cart del mismo producto a las
  00:00:32 y 00:00:33).

Qué hace este script:
  1) Lee las credenciales de Module 0 (ex00/.env) cuando las encuentra
  2) Muestra COUNT(*) ANTES de la limpieza
  3) Ejecuta un único DELETE en SQL con función de ventana (LAG):
       - misma instrucción = mismos user_id, user_session,
         event_type, product_id, price
       - si el event_time respecto al anterior del grupo es ≤ 1 segundo
         → se borra la fila posterior (se conserva la primera)
  4) Muestra COUNT(*) DESPUÉS de la limpieza

Analogía:
  A veces el servidor "tartamudea" y anota dos veces la misma acción
  del cliente casi al mismo momento. Nos quedamos con la primera nota
  y descartamos el eco que llega en el plazo de un segundo.

Uso:
  python3 remove_duplicates.py
  ./remove_duplicates.py
"""

from __future__ import annotations

# annotations permite escribir tipos modernos (ej. Path | None) de forma clara

import os
import sys
import threading
import time
from pathlib import Path


def ensure_dependencies() -> None:
    """
    Comprueba si faltan librerías e intenta instalarlas para el usuario actual
    (sin sudo), típico en el campus 42.
    """
    import importlib.util
    import subprocess

    # Módulo a importar → paquete a instalar con pip
    needed = {
        "psycopg2": "psycopg2-binary",  # hablar con PostgreSQL
        "dotenv": "python-dotenv",      # leer el archivo .env
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

# ---------------------------------------------------------------------------
# Rutas: este archivo vive en .../data_science_1_data_warehouse/ex02/
# Module 0 suele ser hermano: .../data_science_0_creation_db/
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
MODULE1_DIR = SCRIPT_DIR.parent


def find_env_file() -> Path | None:
    """
    Busca el .env de Module 0 (ex00) sin fijar la ruta de un solo login.
    Prueba varias ubicaciones habituales en el campus.
    Devuelve la ruta si existe, o None si no se encuentra.
    """
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
    load_dotenv(ENV_PATH)  # carga POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# Parámetros de conexión a la base (Docker publica el 5432 en localhost)
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}

# Misma sentencia que remove_duplicates.sql (la lógica vive en el servidor SQL)
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
    """
    Abre una conexión con PostgreSQL.
    **DB_CONFIG descompone el diccionario en argumentos con nombre
    (host=..., port=..., etc.).
    """
    return psycopg2.connect(**DB_CONFIG)


def count_customers(cur) -> int:
    """Devuelve el número de filas actuales de la tabla customers."""
    cur.execute("SELECT COUNT(*) FROM customers;")
    row = cur.fetchone()
    return int(row[0]) if row else 0


def show_progress(percent: int, label: str, width: int = 34) -> None:
    """Dibuja una barra de progreso estable en una sola línea."""
    filled = int(width * percent / 100)
    bar = "=" * filled + ">" + " " * max(0, width - filled - 1)
    print(f"\r  [{bar}] {percent:3d}% · {label}", end="", flush=True)


def animate_delete(stop_event: threading.Event) -> None:
    """Mantiene visible actividad mientras PostgreSQL ejecuta el DELETE."""
    frames = ("   ", ".  ", ".. ", "...")
    index = 0
    while not stop_event.wait(0.5):
        show_progress(35, f"ejecutando DELETE{frames[index]}")
        index = (index + 1) % len(frames)


def execute_delete_with_progress(cur) -> None:
    """Ejecuta el DELETE y evita que una consulta larga parezca bloqueada."""
    stop_event = threading.Event()
    worker = threading.Thread(target=animate_delete, args=(stop_event,), daemon=True)
    show_progress(25, "preparando DELETE")
    worker.start()
    try:
        cur.execute(DELETE_SQL)
    finally:
        stop_event.set()
        worker.join()
    show_progress(50, "DELETE completado")
    print()


def main() -> None:
    """
    Punto de entrada:
      conectar → contar → borrar ecos/duplicados → contar → confirmar cambios
    """
    print("EX02 – remove_duplicates")
    print("Tabla: customers")
    print("Regla: misma instrucción + diferencia de tiempo ≤ 1 segundo → una sola fila")
    if ENV_PATH:
        print(f".env: {ENV_PATH}")
    else:
        print(".env: no encontrado (se usan valores por defecto / variables de entorno)")
    print()

    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                # cursor = canal para enviar SQL y leer resultados
                before = count_customers(cur)
                print(f"COUNT(*) antes:  {before}")

                print("Ejecutando DELETE (ventana LAG, partición por claves de negocio)...")
                print("☕ Puede tardar varios minutos con ~20 millones de filas. Paciencia 🙏")
                print("  Progreso por fases: PostgreSQL no expone un porcentaje de filas para este DELETE.")
                execute_delete_with_progress(cur)
                # rowcount = filas afectadas según el driver (a veces -1 si no aplica)
                deleted = cur.rowcount if cur.rowcount is not None and cur.rowcount >= 0 else None

                show_progress(75, "verificando COUNT(*)")
                after = count_customers(cur)
                conn.commit()  # guarda los borrados de forma definitiva
                show_progress(100, "proceso terminado")
                print()

                print(f"COUNT(*) después: {after}")
                if deleted is not None:
                    print(f"Filas borradas (informe del driver): {deleted}")
                else:
                    print(f"Filas eliminadas (antes - después): {before - after}")
                print()
                print("Proceso terminado.")
    except psycopg2.Error as exc:
        print("Error de PostgreSQL:", exc, file=sys.stderr)
        print(
            "Revisa: docker ps, archivo .env, y que exista la tabla customers (EX01).",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    # Solo se ejecuta main() si lanzamos este archivo directamente
    # (python3 remove_duplicates.py), no si otro script lo importa
    main()
