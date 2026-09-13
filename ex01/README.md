# 📦 Ejercicio 01 – customers table

<p align="center">
  <img src="../imgs/banner_10.jpg" alt="Piscine Data Science – Module 1 – Data Warehouse" width="100%">
</p>

[← Volver al README principal](../README.md)

---

<a id="indice"></a>
## 📑 Índice

1. [¿Qué se pide?](#que-se-pide)
2. [Archivos a entregar](#archivos)
3. [Explicación](#explicacion)
4. [Prerrequisitos](#prereq)
5. [Implementación](#implementacion)
6. [Ejecutar](#ejecutar)
7. [El CSV de febrero](#febrero)
8. [Comprobar](#comprobar)
9. [Checklist](#checklist)
10. [Navegación](#navegacion)

---

<a id="que-se-pide"></a>
## 🎯 ¿Qué se pide?

Literalmente:

> You have to join all the `data_202*_***` tables together in a table called **`customers`**.

| Requisito | Detalle |
|-----------|---------|
| Directorio | `ex01/` |
| Entrega | `customers_table.*` |
| Tabla final | Exactamente **`customers`** |
| Origen | Todas las tablas `data_202*` de Module 0 y Module 1 |

[↑ Volver al índice](#indice)

---

<a id="archivos"></a>
## 📁 Archivos a entregar

| Archivo | Rol |
|---------|-----|
| [`customers_table.sql`](./customers_table.sql) | `UNION ALL` explícito de los cinco meses |
| [`customers_table.py`](./customers_table.py) | Descubre `data_202%` y crea `customers` |

Cualquiera de los dos cumple el nombre `customers_table.*`.

[↑ Volver al índice](#indice)

---

<a id="explicacion"></a>
## 🧠 Explicación

En Module 0 cada mes es una tabla (`data_2022_oct`, …). Aquí el almacén necesita **una sola** tabla de eventos: **`customers`**.

“Join together” en este ejercicio = **apilar** filas con la misma estructura:

```text
data_2022_oct  ─┐
data_2022_nov  ─┼─►  customers   (UNION ALL)
data_2022_dec  ─┤
data_2023_jan  ─┤
data_2023_feb  ─┘
```

- **`UNION ALL`**: no elimina filas repetidas (eso es **EX02**).
- No es un `JOIN` por `user_id` entre meses.

[↑ Volver al índice](#indice)

---

<a id="prereq"></a>
## ⚙️ Prerrequisitos

1. Contenedor `postgres_piscineds` en marcha  
2. Tablas `data_202*` cargadas (Module 0 EX03)  
3. Credenciales habituales: login / `mysecretpassword` / `piscineds`

```bash
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c '\dt'
```

[↑ Volver al índice](#indice)

---

<a id="febrero"></a>
## 📥 El CSV de febrero de 2023

Junto al subject se proporciona `data_2023_feb.csv`. El PDF no lo menciona por
nombre, pero forma parte del patrón `data_202*_***` del ejercicio: representa
otro mes de eventos que se entiende debe estar disponible como tabla `**data_2023_feb**` 
antes de construir `customers`.

El CSV no se añade directamente a `customers`. Primero se carga en PostgreSQL
como una tabla independiente y después EX01 la apila con las demás mediante
`UNION ALL`. Esto conserva la separación por meses y permite comprobar cada
origen antes de continuar con EX02.

El fichero contiene las columnas `event_time`, `event_type`, `product_id`,
`price`, `user_id` y `user_session`, con la misma estructura que los otros
meses. Tiene aproximadamente 4,1 millones de filas, por lo que la carga puede
tardar y necesitar espacio adicional en Docker.

### Cargar solo febrero

Desde `data_science_1_data_warehouse/` que es donde se supone que tenemos el nuevo .csv:

```bash
docker cp data_2023_feb.csv postgres_piscineds:/tmp/data_2023_feb.csv
```
Ignoramos "failed to Lchown" si el fichero se ha copiado con éxito. Luego **entramos en psql** ...
```bash
docker exec -it postgres_piscineds psql -U "$(whoami)" -d piscineds
```

Dentro de `psql`:

```sql
DROP TABLE IF EXISTS data_2023_feb;

CREATE TABLE data_2023_feb (
  event_time   TIMESTAMPTZ,
  event_type   VARCHAR(50),
  product_id   INTEGER,
  price        NUMERIC(10,2),
  user_id      BIGINT,
  user_session UUID
);

COPY data_2023_feb
FROM '/tmp/data_2023_feb.csv'
WITH (FORMAT csv, HEADER true);

SELECT COUNT(*) FROM data_2023_feb;
```

Con '**\dt**' veremos que el nuevo csv se ha integrado con éxito.

Otra **alternativa automática** es copiar el CSV a la carpeta `customer/` de Module
0 y ejecutar su EX03. Ese proceso descubre todos los CSV y recrea sus tablas,
por lo que conviene usarlo cuando se quiere reconstruir todo el conjunto, no
solo añadir febrero.

Para ello desde la carpeta `data_science_1_data_warehouse/`:

```bash
cp data_2023_feb.csv \
  ../data_science_0_creation_db/subject/customer/data_2023_feb.csv
cd ../data_science_0_creation_db/ex03
python3 automatic_table.py
```

Después se puede verificar que la tabla existe:

```bash
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -c '\dt data_2023_feb'
```

### Por qué se incluye en el SQL

El archivo `customers_table.sql` es una implementación explícita y educativa:
enumera cada tabla que participa. Por eso incluye `data_2023_feb`. Si febrero
todavía no está cargado, el SQL fallará con `relation "data_2023_feb" does not
exist`; en ese caso hay que completar primero la carga anterior.

[↑ Volver al índice](#indice)

---

<a id="implementacion"></a>
## 🚀 Implementación

### SQL (`customers_table.sql`)

```sql
DROP TABLE IF EXISTS customers;

CREATE TABLE customers AS
SELECT * FROM data_2022_oct
UNION ALL
SELECT * FROM data_2022_nov
UNION ALL
SELECT * FROM data_2022_dec
UNION ALL
SELECT * FROM data_2023_jan
UNION ALL
SELECT * FROM data_2023_feb;
```

Este archivo enumera los cinco meses conocidos en este repositorio. Si en tu
base de datos hay más tablas `data_202*`, usa `customers_table.py`, que las
descubre sin tener que editar una lista fija.

### Python (`customers_table.py`)

1. Lee `.env` de Module 0 si lo encuentra  
2. Lista tablas `public` con nombre `data_202%`  
3. `CREATE TABLE customers AS … UNION ALL …`  
4. Imprime `COUNT(*)`

[↑ Volver al índice](#indice)

---

<a id="ejecutar"></a>
## ▶️ Ejecutar

### Opción A – Python (recomendada si puede haber más/menos meses)

```bash
cd ex01
python3 customers_table.py
```

### Opción B – SQL dentro del contenedor

```bash
docker cp customers_table.sql postgres_piscineds:/tmp/customers_table.sql
docker exec -it postgres_piscineds \
  psql -U "$(whoami)" -d piscineds -W -f /tmp/customers_table.sql
```

[↑ Volver al índice](#indice)

---

<a id="comprobar"></a>
## ✅ Comprobar

```sql
\d customers
SELECT COUNT(*) FROM customers;

-- Debe coincidir con la suma de los meses:
SELECT 'oct' AS m, COUNT(*) FROM data_2022_oct
UNION ALL SELECT 'nov', COUNT(*) FROM data_2022_nov
UNION ALL SELECT 'dec', COUNT(*) FROM data_2022_dec
UNION ALL SELECT 'jan', COUNT(*) FROM data_2023_jan
UNION ALL SELECT 'feb', COUNT(*) FROM data_2023_feb;
```

`COUNT(*)` de `customers` = suma de los cinco meses (con `UNION ALL`).

[↑ Volver al índice](#indice)

---

<a id="checklist"></a>
## ✅ Checklist subject

| Requisito | ☐ |
|-----------|---|
| Tabla se llama exactamente `customers` | ☐ |
| Incluye todos los `data_202*` | ☐ |
| `data_2023_feb` está cargada antes de crear `customers` | ☐ |
| Archivo `customers_table.*` en `ex01/` | ☐ |
| `COUNT(*)` coherente con la suma de orígenes | ☐ |

[↑ Volver al índice](#indice)

---

<a id="navegacion"></a>
## 🔗 Navegación

- [← EX00](../ex00/README.md)
- [← README Module 1](../README.md)
- [Siguiente: EX02 – remove duplicates →](../ex02/README.md)

---

*Module 1 – EX01 – sternero – 42 Málaga*
