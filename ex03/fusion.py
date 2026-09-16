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
# __future__ es un módulo especial que permite usar características de Python 3.10+ 
# en versiones anteriores (3.7+). Aquí se usa para permitir anotaciones de tipo con 
# "Path | None" en lugar de "Optional[Path]". 
# Entendemos por anotaciones a las declaraciones de tipo que se pueden usar para 
# indicar qué tipo de datos se espera en variables, parámetros de funciones y valores 
# de retorno. Por ejemplo: en este caso para la función find_env_file() se indica 
# que puede devolver un objeto Path o None.
# Path sería para representar rutas de archivos y directorios.
# None representa la ausencia de valor (similar a null en otros lenguajes).
# annotations es una característica que importamos de __future__ para permitir el uso 
# de las anotaciones descritas anteriormente.


import os
# os es un módulo estándar de Python que proporciona funciones para interactuar con 
# el sistema operativo. Lo necesitamos para acceder a variables de entorno (como 
# POSTGRES_DB, POSTGRES_USER y POSTGRES_PASSWORD) y para obtener el nombre del 
# usuario actual con os.environ.get("USER").
import sys
# sys es un módulo estándar de Python que proporciona acceso a algunas variables y
# funciones del intérprete de Python. Lo necesitamos para salir del programa con
# sys.exit() en caso de error y para obtener la ruta del ejecutable de Python con
# sys.executable.
from pathlib import Path
# Path es, un módulo estándar de Pyton, dicho de otro modo, es una clase dentro del 
# módulo pathlib que proporciona una forma orientada a objetos de trabajar con 
# rutas de archivos y directorios. Lo necesitamos para construir rutas de archivos 
# de forma más legible y segura que usando cadenas de texto.
# Lo importamos desde pathlib para poder usar Path(__file__).resolve().parent y
# otras funciones de Path presentes en el código y disponibles en pathlib que es 
# el módulo que proporciona la funcionalidad de Path.
# La diferencia entre este Path y el de annotations es que este Path es una clase 
# que nos permite trabajar con rutas de archivos y directorios, mientras que el 
# Path de annotations es un tipo de dato que se usa para indicar que una variable 
# o parámetro puede ser un objeto Path o None.
# Ejemplo sencillo: el de annotations es como si dijéramos "puede ser un coche o nada",
# mientras que el de pathlib es como si dijéramos "es un coche con ruedas, motor y volante".
# Que ambos se llamen Path es una coincidencia, pero no son lo mismo.
# Es más bien una broma de mal gusto de los desarrolladores de Python, que decidieron 
# usar el mismo nombre para dos cosas diferentes.


def ensure_dependencies() -> None:
    """Instala psycopg2 y python-dotenv para el usuario si faltan (sin sudo)."""
    import importlib.util
    # importlib.util es un módulo estándar de Python que proporciona funciones para
    # trabajar con módulos y paquetes de Python. Lo necesitamos para comprobar si
    # los módulos psycopg2 y dotenv están instalados en el entorno de Python actual.
    import subprocess
    # subprocess es un módulo estándar de Python que permite ejecutar comandos del
    # sistema operativo desde un script de Python. Lo necesitamos para instalar los
    # paquetes necesarios usando pip si no están presentes.

    needed = {
        "psycopg2": "psycopg2-binary",
        "dotenv": "python-dotenv",
    }
    # needed es un diccionario que mapea los nombres de los módulos que necesitamos
    # importar (psycopg2 y dotenv) a los nombres de los paquetes que
    # debemos instalar con pip (psycopg2-binary y python-dotenv).
    # El diccionario se llama needed pero podría llamarse "dependencias" o "requerimientos"
    # Los diccionarios son estructuras de datos que permiten almacenar pares de clave-valor,
    # es decir, cada elemento del diccionario tiene una clave (key) y un valor (value). 
    # Es algo así como un diccionario de palabras, donde la clave es la palabra y el valor 
    # es su definición. En este caso, la clave es el nombre del módulo y el valor es el 
    # nombre del paquete que se va a instalar con pip.
    missing = [
        pkg
        for mod, pkg in needed.items()
            if importlib.util.find_spec(mod) is None
    ]
    # missing es una lista que contiene los nombres de los paquetes que faltan por instalar.
    # Una lista es una estructura de datos que permite almacenar varios elementos en un solo objeto,
    # es algo así como cuando apuntamos varias cosas en una lista de la compra (leche = 1, pan = 2, 
    # huevos = 12 ...). Las tuplas son similares a las listas, pero son inmutables 
    # (no se pueden cambiar una vez creadas).
    # La llamamos missing pero podría llamarse "faltantes" o "no_instalados".
    # pkg es el nombre del paquete que se va a instalar con pip. Lo llamamos pkg pero 
    # podría llamarse "paquete" o "nombre_paquete".
    # for inicia un bucle que recorre los elementos del diccionario needed. 
    # mod es el nombre del módulo que se va a importar. Lo llamamos mod pero 
    # podría llamarse "modulo" o "nombre_modulo".
    # Con in decimos que queremos recorrer todos los elementos del diccionario needed.
    # Con .items() que es un método nativo de los diccionarios que devuelve una lista de 
    # tuplas (clave, valor) obtenemos tanto el nombre del módulo como el nombre del paquete
    # que necesitamos instalar. 
    # O sea, en el ciclo for estamos diciendo algó así como "para cada módulo y paquete en el 
    # diccionario needed, si no se encuentra el módulo, añade el paquete a la lista missing".
    # El if importlib.util.find_spec(mod) is None comprueba si el módulo mod está instalado en el
    # entorno de Python actual. Si no está instalado, find_spec devuelve None y el paquete
    # correspondiente se añade a la lista missing. La condición if se repite para cada módulo en 
    # needed mediante el bucle for. Si el módulo está instalado, find_spec devuelve un objeto de 
    # especificación del módulo y la condición if no se cumple, por lo que el paquete no se añade 
    # a missing.
    if missing:
        print(f"Instalando: {', '.join(missing)} ...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "--user", *missing]
        )
    # Si la lista missing no está vacía, significa que faltan paquetes por instalar. En ese caso,
    # se imprime un mensaje indicando qué paquetes se van a instalar. 
    # join(missing) convierte la lista de paquetes en una cadena separada por comas.
    # subprocess es un módulo que permite ejecutar comandos del sistema operativo desde Python.
    #.check_call es una función nativa de subprocess que ejecuta un comando y espera a que termine.
    # [sys.executable, "-m", "pip", "install", "--user", *missing] es la lista de argumentos que 
    # se pasa al comando. En concreto sys (sistema) es un módulo que proporciona acceso a algunas 
    # variables y funciones del intérprete de Python.
    # En concreto, sys.executable es algo así como un "atajo" que nos dice dónde está instalado 
    # Python en el sistema operativo para poder usarlo en el comando de instalación de paquetes.
    # "-m pip" indica que se quiere ejecutar el módulo pip, 
    # "install" es la acción que se quiere realizar, 
    # "--user" indica que se quiere instalar el paquete para el usuario actual que se obtiene de 
    # la variable de entorno USER,
    # y *missing es una forma de pasar todos los elementos de la lista missing como argumentos a
    # el comando pip install.

ensure_dependencies()

import psycopg2
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).resolve().parent
MODULE1_DIR = SCRIPT_DIR.parent


def find_env_file() -> Path | None:
    """Localiza Module 0 ex00/.env sin hardcodear un único path de campus.
        def es una palabra reservada en Python que se utiliza para definir funciones.
        find_env_file es el nombre de la función que estamos definiendo.
        Path | None indica que la función puede devolver un objeto Path o None.
        -> es para indicar el tipo de retorno de la función, algo así como el return 
        en otros lenguajes.
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
    # candidates es una lista de rutas de archivos que se van a comprobar para ver 
    # si existe un archivo .env.
    # MODULE1_DIR.parent es la ruta del directorio que contiene el módulo 1 (data_science_1_data_warehouse).
    # MODULE1_DIR es un objeto Path que representa la ruta del directorio que contiene el script fusion.py
    # con el .parent obtenemos el directorio padre de MODULE1_DIR, es decir, el directorio que contiene 
    # data_science_1_data_warehouse. El término "parent" se refiere a la relación jerárquica entre directorios, .
    # MODULE1_DIR / ".." es otra forma de referirse al directorio padre de MODULE1_DIR.
    # Path.home() es la ruta del directorio home del usuario actual.
    # 
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
