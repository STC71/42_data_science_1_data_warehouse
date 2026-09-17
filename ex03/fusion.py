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
# Llama a la función ensure_dependencies() para asegurarse de que los paquetes necesarios
# estén instalados antes de continuar con el resto del script.

import psycopg2
# psycopg2 es un módulo externo que proporciona una interfaz para conectarse y trabajar con 
# bases de datos PostgreSQL desde Python. Lo necesitamos para ejecutar consultas SQL y manipular 
# datos en la base de datos.
from dotenv import load_dotenv
# dotenv es un módulo externo que permite cargar variables de entorno desde un archivo .env.
# import load_dotenv es una forma de importar solo la función load_dotenv del módulo dotenv,
# en lugar de importar todo el módulo. Esto hace que el código sea más limpio y evita
# posibles conflictos de nombres con otras funciones o variables que puedan tener el mismo nombre
# en el módulo dotenv. La función load_dotenv se encarga de leer el archivo .env y cargar 
# las variables de entorno definidas en él en el entorno de ejecución de Python.

SCRIPT_DIR = Path(__file__).resolve().parent
# SCRIPT_DIR es una variable que contendrá la ruta del directorio donde se encuentra este script.
# Path(__file__) es la ruta del archivo actual (fusion.py).
# .resolve() convierte la ruta relativa en una ruta absoluta. O sea, nos da la ruta completa desde 
# la raíz del sistema de archivos hasta fusion.py.
# .parent obtiene el directorio padre de fusion.py, que es ex03.
# Estamos guardando en SCRIPT_DIR algo así como:
# /home/usuario/piscine_pedago_data_science/data_science_1_data_warehouse/ex03
MODULE1_DIR = SCRIPT_DIR.parent
# MODULE1_DIR es una variable que contendrá la ruta del directorio padre de SCRIPT_DIR,
# que es data_science_1_data_warehouse. O sea, nos da la ruta completa desde la raíz del sistema 
# de archivos hasta data_science_1_data_warehouse sin el subdirectorio ex03.
# Estamos guardando en MODULE1_DIR algo así como:
# /home/usuario/piscine_pedago_data_science/data_science_1_data_warehouse
# Usamos dos variables (SCRIPT_DIR y MODULE1_DIR) para poder construir rutas relativas a este script 
# sin depender del directorio actual desde el que se ejecute el script. 
# Esto hace que el código sea más robusto y portátil.

def find_env_file() -> Path | None:
    """Localiza Module 0 ex00/.env sin hardcodear un único path de campus.
        def es una palabra reservada en Python que se utiliza para definir funciones.
        find_env_file es el nombre de la función que estamos definiendo.
        Path | None indica que la función puede devolver un objeto Path o None.
        -> es para indicar el tipo de retorno de la función, algo así como el return 
        en otros lenguajes.
    """
    candidates = [
        MODULE1_DIR.parent 
        / "data_science_0_creation_db"
        / "ex00"
        / ".env",
    ]
    """
    La ruta se construye desde la ubicación de este script, no desde el directorio actual.
    Por eso funciona aunque fusion.py se ejecute desde otra carpeta.
    candidates es una lista que contiene posibles rutas donde se puede encontrar el archivo .env.
    En nuestro caso, solo hay una ruta candidata, que es la ruta relativa a este script.
    En concreto, la ruta candidata calculada a partir de __file__ sería algo así como:
    fusion.py
      -> ex03
      -> data_science_1_data_warehouse
      -> piscine_pedago_data_science
      -> data_science_0_creation_db/ex00/.env
    __file__ es una variable especial de Python que contiene la ruta del archivo actual (fusion.py).
    MODULE1_DIR es una variable que contiene la ruta del directorio donde se encuentra este script (ex03).
    MODULE1_DIR.parent es la ruta del directorio padre de ex03, que es data_science_1_data_warehouse.
    El nombre 'candidates' para la lista también podría ser 'posibles_rutas' o 'rutas_candidatas'.
    MODULE1_DIR no es más que una variable que podría llamarse 'directorio_modulo1' o 'ruta_modulo1'.
    ¿Por qué usamos MODULE1_DIR dentro de la lista candidates cuando antes la igualamos a SCRIPT_DIR.parent? 
    Porque queremos construir la ruta relativa a este script, y MODULE1_DIR ya contiene la ruta del directorio 
    padre de ex03, que es data_science_1_data_warehouse. De esta forma, podemos concatenar las subcarpetas 
    "data_science_0_creation_db/ex00/.env" a MODULE1_DIR para obtener la ruta completa del archivo .env.
    O sea, el resultado/valor final de la lista candidates sería algo así como:
        /ruta/completa/a/data_science_1_data_warehouse/data_science_0_creation_db/ex00/.env
    Mientras que el valor de MODULE1_DIR sería algo así como:
        /ruta/completa/a/data_science_1_data_warehouse
    ¿Por qué candidates es una lista y no una variable única? 
    Porque en teoría podrían existir varios lugares donde se podría encontrar el archivo .env, aunque en 
    nuestro caso solo hay uno. Si en el futuro se añadieran más rutas candidatas, bastaría con añadirlas
    a la lista candidates y la función find_env_file() seguiría funcionando sin cambios.
    """
    for path in candidates:
        path = path.resolve()
        if path.is_file():
            return path
    # El ciclo for anterior recorre cada ruta candidata en la lista candidates.
    # path es simplemente una variable que podría llamarse "ruta" o "archivo". 
    # Su valor cambia en cada iteración del bucle for, tomando el valor de cada elemento de candidates.
    # in es una palabra reservada en Python que se utiliza para comprobar si un elemento está presente 
    # en una secuencia (como una lista, tupla o cadena de texto). En este caso, se utiliza para recorrer 
    # cada ruta candidata en la lista candidates.
    # path.resolve() convierte la ruta relativa en una ruta absoluta. En nuestro caso, ya que candidates 
    # contiene rutas absolutas, esto no cambia nada.
    # Ruta relativa: es una ruta que se especifica en relación a otra ruta (por ejemplo, "./ex00/.env" 
    # significa "el archivo .env dentro del subdirectorio ex00 del directorio actual").
    # Ruta absoluta: es una ruta que especifica la ubicación completa del archivo o directorio desde la 
    # raíz del sistema de archivos. 
    # (por ejemplo, "/home/usuario/piscine_pedago_data_science/data_science_0_creation_db/ex00/.env").
    # Almacenamos la ruta absoluta en la variable path y luego comprobamos si es un archivo existente 
    # con path.is_file(). Si es así, la función retornará esa ruta. Si no se encuentra ningún archivo 
    # .env en las rutas candidatas, la función devolverá None y continuará el bucle for hasta que se 
    # agoten las rutas candidatas. 
    # Si hubiesen más de una ruta candidata, la función devolvería la primera que encuentre y saldría 
    # del bucle for.
    return None
    # Si llegamos hasta el return None, significa que no se encontró ningún archivo .env en las rutas 
    # candidatas. Por lo que se devuelve None para indicar que no se encontró el archivo .env. y la 
    # función termina su ejecución. 

ENV_PATH = find_env_file()      
# Almacenamos la ruta del archivo .env en la variable ENV_PATH que nos retorna la función find_env_file().
if ENV_PATH is not None:
    load_dotenv(ENV_PATH)
# Si se encontró un archivo .env, se carga en el entorno de ejecución de Python usando la función load_dotenv().
# is not None es una forma de comprobar si la variable ENV_PATH tiene un valor distinto de None, es decir, 
#   si se encontró un archivo .env.
# Si no lo cargamos en el entorno de ejecución, las variables de entorno definidas en el archivo .env 
# no estarán disponibles para el resto del script y se usarán los valores por defecto o los valores del 
# entorno del sistema operativo, lo que podría causar errores.

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": os.environ.get("POSTGRES_DB", "piscineds"),
    "user": os.environ.get("POSTGRES_USER", os.environ.get("USER", "")),
    "password": os.environ.get("POSTGRES_PASSWORD", "mysecretpassword"),
}
# BG_CONFIG es un diccionario que contiene la configuración de la conexión a la base de datos PostgreSQL.
# Los valores de dbname, user y password se obtienen de las variables de entorno definidas en el archivo .env
# o, si no se encuentran, se usan valores por defecto como por ejemplo:
# dbname = "piscineds", user = el usuario actual del sistema operativo, password = "mysecretpassword". 

# A continuación usamos la misma lógica que fusion.sql (también comentado en detalle allí). 
# Se ejecuta desde Python para poder mostrar mensajes de progreso y errores.
# Almacenamos en la variable FUSION_SQL la consulta SQL que realiza la fusión de las tablas customers e items.
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
# La función get_connection() abre una conexión a la base de datos PostgreSQL usando la configuración
# almacenada en DB_CONFIG. La función devuelve un objeto de conexión que se puede usar para ejecutar 
# consultas SQL y manipular datos en la base de datos. 
# El operador ** se utiliza para desempaquetar el diccionario DB_CONFIG y pasar sus elementos como 
# argumentos de palabra clave a la función psycopg2.connect(). Esto permite que la función connect() 
# reciba los parámetros de conexión.

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
# La función table_exists() comprueba si una tabla con el nombre especificado existe en la base de datos.
# La función recibe dos parámetros: cur, que es un objeto cursor que se utiliza para ejecutar consultas SQL, 
# y name, que es el nombre de la tabla que se quiere comprobar. 
# Un objeto cursor es un objeto que permite interactuar con la base de datos y ejecutar consultas SQL. cur
# por tanto es una variable que representa un cursor de la base de datos (psycopg2 cursor) que se utiliza 
# para ejecutar consultas SQL y recuperar resultados. El término cur es propio de este script y podría llamarse 
# de otra manera, como por ejemplo "cursor" o "db_cursor". 
# La función como es boolean devuelve True si la tabla existe y False si no existe. 
# cur.execute() ejecuta la consulta SQL que busca la tabla en la vista pg_tables de PostgreSQL.
# WHERE schemaname es una cláusula que filtra las tablas que pertenecen al esquema público de la base de datos
# y tablename = %s es un marcador de posición que se reemplaza por el nombre de la tabla que se quiere comprobar.
# (name,) es una tupla que contiene el nombre de la tabla que se quiere comprobar. Una tupla es una 
# estructura de datos que permite almacenar varios elementos en un solo objeto, similar a una lista, pero 
# inmutable (no se puede cambiar una vez creada). En este caso, se utiliza una tupla para pasar el nombre de la 
# tabla como parámetro a la consulta SQL. No usamos el str que hemos recibido como parámetro para evitar 
# inyecciones SQL (SQL injection), que es un tipo de ataque que consiste en insertar código malicioso en una 
# consulta SQL para manipular la base de datos. Al usar un marcador de posición (%s) y pasar el nombre de la 
# tabla como parámetro, psycopg2 se encarga de escapar correctamente el valor y evitar inyecciones SQL.
# cur.fetchone() devuelve la primera fila del resultado de la consulta SQL. Si la tabla existe, la consulta 
# devolverá al menos una fila y cur.fetchone() devolverá un objeto que representa esa fila. Si la tabla 
# no existe, la consulta no devolverá ninguna fila y cur.fetchone() devolverá None. Por eso, la función devuelve 
# True si cur.fetchone() no es None y False si lo es. 
# fetchone() es un método del objeto cursor que se utiliza para obtener una fila del resultado de una 
# consulta SQL.

def count_rows(cur, table: str) -> int:
    """
    Cuenta el número de filas de una tabla especificada en la base de datos.
    """
    cur.execute(f"SELECT COUNT(*) FROM {table};")
    row = cur.fetchone()
    return int(row[0]) if row else 0
# La función recibe dos parámetros: cur, que es un objeto cursor que se utiliza para ejecutar consultas SQL, 
# y table: str que es el nombre de la tabla de la que se quiere contar el número de filas.
# table es un parámetro de tipo str (cadena de texto) que representa el nombre de la tabla de la que se 
# quiere contar el número de filas. El término table es propio de este script y podría llamarse de otra manera, 
# como por ejemplo "nombre_tabla" o "tabla", y con str estamos indicando que el parámetro debe ser una cadena de texto.
# La función devuelve un entero que representa el número de filas de la tabla especificada.
# cur.execute ejecuta la consulta SQL que cuenta el número de filas de la tabla especificada.
# f"SELECT COUNT(*) FROM {table};" es una cadena de texto formateada (f-string) que permite insertar el valor de la 
# variable table en la consulta SQL. 
# cur.fetchone() devuelve la primera fila del resultado de la consulta SQL, que contiene el número de filas de la tabla
# y se almacena en la variable row (podría llamarse "fila" o "resultado"). 
# row[0] accede al primer elemento de la fila, que es el número de filas. Si row es None (es decir, si la consulta no 
# devolvió ninguna fila), la función devuelve 0. 
# int(row[0]) convierte el valor de row[0] a un entero antes de devolverlo (algo así como un cast en otros lenguajes). 
# Esto es útil porque el resultado de la consulta SQL puede ser de tipo decimal o string, y queremos asegurarnos de 
# que la función devuelva un entero.
# Con el if row else 0 estamos diciendo que si row es None (es decir, si la consulta no devolvió ninguna fila),
# la función debe devolver 0. Esto es una forma de manejar el caso en el que la tabla no existe o está vacía, evitando 
# que se produzca un error al intentar acceder a row[0] cuando row es None.

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
