# 📊 Piscine Data Science – Module 1 – Data Warehouse

<p align="center">
  <a href="https://www.42malaga.com/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/42-School-000000?style=for-the-badge&logo=42&logoColor=white" alt="42 School"></a>
  <a href="https://www.python.org/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"></a>
  <a href="https://www.postgresql.org/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"></a>
  <a href="https://www.docker.com/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"></a>
  <a href="https://www.gnu.org/software/bash/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash"></a>
  <a href="https://www.pgadmin.org/" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/pgAdmin-336791?style=for-the-badge&logo=postgresql&logoColor=white" alt="pgAdmin"></a>
  <a href="https://www.ibm.com/think/topics/data-warehouse" target="_blank" rel="noopener noreferrer"><img src="https://img.shields.io/badge/Data%20Warehouse-FF6B6B?style=for-the-badge" alt="Data Warehouse"></a>
</p>

<p align="center">
  <img src="./imgs/banner_13.jpg" alt="Piscine Data Science – Module 1 – Data Warehouse" width="100%">
</p>

<p align="center">
  <strong>ETL · customers · deduplicación · fusión con items</strong><br>
  <em>Training Piscine datascience – 1 · Version 1.1</em>
</p>

---

<a id="indice"></a>
## 📑 Índice

1. [¿De qué trata este módulo?](#proyecto)
2. [ETL en una frase](#etl)
3. [Estructura del repositorio](#estructura)
4. [Prerrequisito: Module 0](#prereq)
5. [Orden de trabajo (subject)](#orden)
6. [Qué entrega cada ejercicio](#entregas)
7. [Asistente global (`./start.sh`)](#asistente-global)
8. [Asistentes por ejercicio](#asistentes-ex)
9. [Guías didácticas](#guias)
10. [Cómo arrancar el entorno](#entorno)
11. [Comprobar el almacén](#comprobar)
12. [Checklist subject](#checklist)
13. [Navegación](#navegacion)

---

<a id="proyecto"></a>
## 🎯 ¿De qué trata este módulo?

El subject de **Data Warehouse** pide construir, sobre la base **`piscineds`** del Module 0, un almacén de eventos de clientes listo para analizar:

| Paso | Idea |
|------|------|
| **EX00** | Ver y buscar en la BD con una GUI cómoda |
| **EX01** | Reunir todos los meses `data_202*` en una sola tabla **`customers`** |
| **EX02** | Limpiar duplicados y ecos a **1 segundo** |
| **EX03** | Enriquecer **`customers`** con el catálogo **`items`** sin perder filas |

Al final, `customers` concentra el historial de eventos **más** categoría/marca del producto, sin basura de servidor tartamudo y sin tirar eventos huérfanos.

> ⚠️ Aviso del PDF: aunque valides un módulo, si no limpias ni almacenas bien los datos, te puedes quedar bloqueado más adelante en la piscine.

[↑ Volver al índice](#indice)

---

<a id="etl"></a>
## 🔄 ETL en una frase

**ETL** = *Extract, Transform, Load*:

```text
  data_2022_oct … data_2023_feb     items
           \         /                 |
            \       /                  |
             v     v                   v
          EXTRACT ────────► TRANSFORM ────────► LOAD
                     (UNION, DELETE,          tabla
                      LEFT JOIN)            customers
```

- **Extract**: leer tablas mensuales y catálogo ya cargados en PostgreSQL.  
- **Transform**: apilar, deduplicar, fusionar.  
- **Load**: dejar el resultado en **`customers`** dentro de `piscineds`.

[↑ Volver al índice](#indice)

---

<a id="estructura"></a>
## 📁 Estructura del repositorio

```text
data_science_1_data_warehouse/
├── README.md                 ← este archivo
├── start.sh                  ← asistente GLOBAL (recomendado)
├── imgs/
├── ex00/                     ← Show me your DB
│   ├── README.md
│   └── start.sh
├── ex01/                     ← customers table
│   ├── README.md
│   ├── customers_table.sql   ← entrega
│   ├── customers_table.py    ← entrega
│   ├── sql.md · python.md
│   └── start.sh
├── ex02/                     ← remove duplicates
│   ├── README.md
│   ├── remove_duplicates.sql ← entrega
│   ├── remove_duplicates.py  ← entrega
│   ├── sql.md · python.md
│   └── start.sh
└── ex03/                     ← fusion
    ├── README.md
    ├── fusion.sql            ← entrega
    ├── fusion.py             ← entrega
    ├── sql.md · python.md
    └── start.sh
```

Los `start.sh` y las guías **no sustituyen** los ficheros de entrega del subject.

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## 🔗 Prerrequisito: Module 0

Antes de EX01–EX03, en PostgreSQL debe existir como mínimo:

| Elemento | Origen típico |
|----------|----------------|
| Contenedor `postgres_piscineds` en `localhost:5432` | Module 0 `ex00` |
| Tablas `data_2022_*` / `data_2023_*` | Module 0 carga CSV |
| Tabla **`items`** | Module 0 EX04 |
| Credenciales | login / `mysecretpassword` / `piscineds` |

Repo hermano: [`data_science_0_creation_db`](https://github.com/STC71/42_data_science_0_creation_db) (o ruta local equivalente).

```bash
docker ps | grep postgres_piscineds
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c '\dt'
```

[↑ Volver al índice](#indice)

---

<a id="orden"></a>
## 🚀 Orden de trabajo (subject)

| # | Ejercicio | Qué haces | Resultado |
|---|-----------|-----------|-----------|
| 0 | **[EX00](ex00/README.md)** | GUI fácil de usar y de buscar por ID | Visualización |
| 1 | **[EX01](ex01/README.md)** | Apilar todos los `data_202*` | **`customers`** |
| 2 | **[EX02](ex02/README.md)** | Borrar duplicados y ecos ≤ 1 s | **`customers`** limpia |
| 3 | **[EX03](ex03/README.md)** | `LEFT JOIN` con **`items`** | **`customers`** + catálogo |

El orden **no es intercambiable**.

[↑ Volver al índice](#indice)

---

<a id="entregas"></a>
## 📦 Qué entrega cada ejercicio

| Carpeta | Ficheros del subject | Idea técnica |
|---------|----------------------|--------------|
| [`ex00/`](ex00/README.md) | Demo GUI en defensa | pgAdmin / Postico / DBeaver / … |
| [`ex01/`](ex01/README.md) | **`customers_table.*`** | `UNION ALL` → `customers` |
| [`ex02/`](ex02/README.md) | **`remove_duplicates.*`** | `DELETE` + `LAG` ≤ 1 s |
| [`ex03/`](ex03/README.md) | **`fusion.*`** | `LEFT JOIN` items → `customers` |

Nombres de carpetas y archivos: **exactos** como en el PDF.

[↑ Volver al índice](#indice)

---

<a id="asistente-global"></a>
## 🎛️ Asistente global (`./start.sh`)

En la **raíz** del proyecto (mismo espíritu que Module 0):

```bash
chmod +x start.sh
./start.sh
# o desde cualquier directorio:
/ruta/a/data_science_1_data_warehouse/start.sh
```

### Independiente de los `start.sh` de cada `ex/`

- **No exige** `ex00/start.sh` … `ex03/start.sh`.
- Flujo integrado: estado, levantar PostgreSQL (Module 0), EX01–EX03 (`.py` o `.sql`), `COUNT`, `psql`, checklist de entregables.
- Si existen los asistentes por ejercicio, el menú ofrece **atajos opcionales** (a–d).

### Menú (resumen)

| Opción | Acción |
|--------|--------|
| 1 | Estado (Module 0, Docker, **pgAdmin**, tablas) |
| 2 | Levantar **PostgreSQL + pgAdmin** |
| g | Solo **pgAdmin** (`http://127.0.0.1:5050`) |
| p | `chmod +x` scripts conocidos |
| 3–5 | Pipeline EX01 → EX02 → EX03 |
| 6–7 | COUNT / `\d` y `psql` |
| 8 | Verificar entregables del subject |
| **e** | Preparar **`repo_<login>`** (lista blanca, sin `.env`) |
| **0** | Git asistido (push **default N**; `update-index +x`) |
| 9 | Recordatorio de defensa |
| a–d | Atajos a `ex0X/start.sh` si existen |
| q | Salir |

### Permisos +x

Tras un `git clone`, si aparece `Permission denied`:

```bash
./start.sh   # opción p, o confirmación al arrancar
# o en Git, para clones futuros:
git update-index --chmod=+x start.sh
git update-index --chmod=+x ex01/customers_table.py
git update-index --chmod=+x ex02/remove_duplicates.py
git update-index --chmod=+x ex03/fusion.py
# … y los start.sh que quieras ejecutables
```

[↑ Volver al índice](#indice)

---

<a id="asistentes-ex"></a>
## 🧩 Asistentes por ejercicio (opcionales)

| Script | Rol |
|--------|-----|
| [`ex00/start.sh`](ex00/start.sh) | GUI / entorno local EX00 |
| [`ex01/start.sh`](ex01/start.sh) | Menú EX01 |
| [`ex02/start.sh`](ex02/start.sh) | Menú EX02 |
| [`ex03/start.sh`](ex03/start.sh) | Menú EX03 |

Si no los usas, el **[`./start.sh`](./start.sh) de la raíz** cubre el recorrido.

[↑ Volver al índice](#indice)

---

<a id="guias"></a>
## 📘 Guías didácticas

Empiezan por conceptos básicos (sin asumir SQL/Python) y luego detallan cada script:

| Ejercicio | SQL | Python |
|-----------|-----|--------|
| EX01 | [ex01/sql.md](ex01/sql.md) | [ex01/python.md](ex01/python.md) |
| EX02 | [ex02/sql.md](ex02/sql.md) | [ex02/python.md](ex02/python.md) |
| EX03 | [ex03/sql.md](ex03/sql.md) | [ex03/python.md](ex03/python.md) |

[↑ Volver al índice](#indice)

---

<a id="entorno"></a>
## 🖥️ Cómo arrancar el entorno

```bash
# Module 0
cd ruta/a/data_science_0_creation_db/ex00
docker-compose up -d

# Module 1 – asistente global
cd ruta/a/data_science_1_data_warehouse
./start.sh
```

Ejecución directa del pipeline:

```bash
cd ex01 && python3 customers_table.py
cd ../ex02 && python3 remove_duplicates.py   # varios minutos
cd ../ex03 && python3 fusion.py
```

[↑ Volver al índice](#indice)

---

<a id="comprobar"></a>
## ✅ Comprobar el almacén

```bash
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -W
```

```sql
\dt
SELECT COUNT(*) FROM customers;
\d customers
-- Tras EX03: category_id, category_code, brand
SELECT * FROM customers WHERE brand IS NOT NULL LIMIT 5;
\q
```

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Ítem | ☐ |
|------|---|
| **EX00** – GUI fácil de usar y de buscar por ID | ☐ |
| **EX01** – Tabla **`customers`** con todos los `data_202*` | ☐ |
| **EX01** – Entrega `ex01/customers_table.*` | ☐ |
| **EX02** – Duplicados / ecos ≤ 1 s eliminados | ☐ |
| **EX02** – Entrega `ex02/remove_duplicates.*` | ☐ |
| **EX03** – Fusión con `items` **sin perder información** | ☐ |
| **EX03** – Entrega `ex03/fusion.*` | ☐ |
| Nombres de carpetas y ficheros según el PDF | ☐ |
| Trabajo en el repositorio Git asignado | ☐ |
| Puedes demostrar el flujo en la máquina del evaluado | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

| | |
|--|--|
| **[EX00 – Show me your DB](ex00/README.md)** | GUI y búsqueda por ID |
| **[EX01 – customers table](ex01/README.md)** | `UNION ALL` → `customers` |
| **[EX02 – remove duplicates](ex02/README.md)** | Limpieza `LAG` ≤ 1 s |
| **[EX03 – fusion](ex03/README.md)** | `LEFT JOIN` con `items` |
| **[./start.sh](./start.sh)** | Asistente global del módulo |

---

<p align="center">
  <em>Piscine Data Science – Module 1 – Data Warehouse</em><br>
  <strong>sternero – 42 Málaga – 2026</strong>
</p>
