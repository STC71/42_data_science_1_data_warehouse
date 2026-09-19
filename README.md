# 📊 Piscine Data Science – Module 1 – Data Warehouse

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
7. [Guías didácticas](#guias)
8. [Cómo arrancar el entorno](#entorno)
9. [Comprobar el almacén](#comprobar)
10. [Checklist subject](#checklist)
11. [Navegación](#navegacion)

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
├── imgs/                     ← banners del módulo
├── ex00/                     ← Show me your DB
│   ├── README.md
│   └── start.sh              ← ayuda (GUI / entorno)
├── ex01/                     ← customers table
│   ├── README.md
│   ├── customers_table.sql   ← entrega
│   ├── customers_table.py    ← entrega
│   ├── sql.md · python.md    ← guías didácticas
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

Los `start.sh` y las guías **no sustituyen** los ficheros de entrega del subject; facilitan defensa y aprendizaje.

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## 🔗 Prerrequisito: Module 0

Antes de EX01–EX03, en PostgreSQL debe existir como mínimo:

| Elemento | Origen típico |
|----------|----------------|
| Contenedor `postgres_piscineds` en `localhost:5432` | Module 0 `ex00` (docker-compose) |
| Tablas `data_2022_*` / `data_2023_*` (eventos) | Module 0 carga de CSV |
| Tabla **`items`** (catálogo) | Module 0 EX04 |
| Credenciales | Usuario = login, password `mysecretpassword`, BD `piscineds` |

```bash
docker ps | grep postgres_piscineds

docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c '\dt'
```

Repo hermano habitual: `data_science_0_creation_db` (mismo monorepo o `sgoinfre`).

[↑ Volver al índice](#indice)

---

<a id="orden"></a>
## 🚀 Orden de trabajo (subject)

| # | Ejercicio | Qué haces | Tabla / resultado |
|---|-----------|-----------|-------------------|
| 0 | **[EX00 – Show me your DB](ex00/README.md)** | GUI fácil de usar y de buscar por ID | Visualización |
| 1 | **[EX01 – customers table](ex01/README.md)** | Apilar todos los `data_202*` | **`customers`** (~20,7 M filas típicas) |
| 2 | **[EX02 – remove duplicates](ex02/README.md)** | Borrar duplicados y ecos ≤ 1 s | **`customers`** limpia (~19,2 M) |
| 3 | **[EX03 – fusion](ex03/README.md)** | `LEFT JOIN` con **`items`** | **`customers`** + categoría / marca |

El orden **no es intercambiable**: EX02 y EX03 parten de la `customers` de EX01; EX03 necesita además `items`.

[↑ Volver al índice](#indice)

---

<a id="entregas"></a>
## 📦 Qué entrega cada ejercicio

| Carpeta | Ficheros del subject | Idea técnica |
|---------|----------------------|--------------|
| [`ex00/`](ex00/README.md) | (demostración GUI en defensa) | pgAdmin / Postico / DBeaver / … |
| [`ex01/`](ex01/README.md) | **`customers_table.*`** | `UNION ALL` de `data_202*` → `customers` |
| [`ex02/`](ex02/README.md) | **`remove_duplicates.*`** | `DELETE` + ventana `LAG` (≤ 1 segundo) |
| [`ex03/`](ex03/README.md) | **`fusion.*`** | `LEFT JOIN` items → columnas en `customers` |

Nombres de carpetas y de archivos de entrega: **exactos** como en el PDF (evaluación / peer).

[↑ Volver al índice](#indice)

---

<a id="guias"></a>
## 📘 Guías didácticas

Cada ejercicio con código incluye guías que empiezan por **conceptos básicos** (sin asumir SQL/Python) y luego detallan el script:

| Ejercicio | SQL | Python |
|-----------|-----|--------|
| EX01 | [ex01/sql.md](ex01/sql.md) | [ex01/python.md](ex01/python.md) |
| EX02 | [ex02/sql.md](ex02/sql.md) | [ex02/python.md](ex02/python.md) |
| EX03 | [ex03/sql.md](ex03/sql.md) | [ex03/python.md](ex03/python.md) |

Pensadas para defensa, autoestudio y para quien llega a la piscine sin experiencia previa en bases de datos.

[↑ Volver al índice](#indice)

---

<a id="entorno"></a>
## 🖥️ Cómo arrancar el entorno

### PostgreSQL (Module 0)

```bash
cd ruta/a/data_science_0_creation_db/ex00
docker-compose up -d
# o: docker compose up -d
```

### Asistentes de este módulo

En cada `ex0X/` (y en EX00):

```bash
chmod +x start.sh
./start.sh
```

Menús típicos: comprobar contenedor, ejecutar el `.py` / aplicar el `.sql`, `COUNT(*)`, abrir `psql`, arrancar pgAdmin si hace falta.

### Ejecución directa (ejemplo EX01 → EX03)

```bash
cd ex01 && python3 customers_table.py
cd ../ex02 && python3 remove_duplicates.py   # varios minutos con ~20 M filas
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
-- Tras EX03 deben existir, entre otras: category_id, category_code, brand
SELECT * FROM customers WHERE brand IS NOT NULL LIMIT 5;
\q
```

O con la GUI de **EX00** (pgAdmin u otra): conectar a `localhost:5432` / `piscineds` y explorar `public.customers`.

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Ítem | ☐ |
|------|---|
| **EX00** – Software gráfico fácil de usar y de buscar por ID | ☐ |
| **EX01** – Tabla **`customers`** con todos los `data_202*` | ☐ |
| **EX01** – Entrega `ex01/customers_table.*` | ☐ |
| **EX02** – Duplicados eliminados (incl. intervalo de 1 s) | ☐ |
| **EX02** – Entrega `ex02/remove_duplicates.*` | ☐ |
| **EX03** – `customers` fusionada con `items` **sin perder información** | ☐ |
| **EX03** – Entrega `ex03/fusion.*` | ☐ |
| Nombres de carpetas y ficheros según el PDF | ☐ |
| Trabajo en el repositorio Git asignado | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

| | |
|--|--|
| **[EX00 – Show me your DB](ex00/README.md)** | GUI y búsqueda por ID |
| **[EX01 – customers table](ex01/README.md)** | `UNION ALL` → `customers` |
| **[EX02 – remove duplicates](ex02/README.md)** | Limpieza LAG ≤ 1 s |
| **[EX03 – fusion](ex03/README.md)** | `LEFT JOIN` con `items` |

---

<p align="center">
  <em>Piscine Data Science – Module 1 – Data Warehouse</em><br>
  <strong>sternero – 42 Málaga – 2026</strong>
</p>
